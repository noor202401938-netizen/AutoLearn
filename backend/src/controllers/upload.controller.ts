import { Request, Response } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import * as Minio from 'minio';

// Use memory storage for uploads to allow streaming to MinIO or disk fallback
const storage = multer.memoryStorage();

// Uploads are served back from this origin, so only allow inert document,
// image and video types — never HTML/SVG/JS that a browser would execute.
const ALLOWED_EXTENSIONS = new Set([
  '.pdf', '.doc', '.docx', '.txt', '.csv', '.xls', '.xlsx', '.ppt', '.pptx',
  '.png', '.jpg', '.jpeg', '.gif', '.webp', '.mp4', '.webm',
]);

export const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (_req, file, cb) => {
    if (ALLOWED_EXTENSIONS.has(path.extname(file.originalname).toLowerCase())) return cb(null, true);
    cb(Object.assign(new Error('That file type is not allowed'), { status: 400 }));
  },
});

const BUCKET_NAME = process.env.MINIO_BUCKET || 'autolearn-media';
let minioClient: Minio.Client | null = null;
let minioInitialized = false;

if (process.env.MINIO_ENDPOINT) {
  try {
    minioClient = new Minio.Client({
      endPoint: process.env.MINIO_ENDPOINT,
      port: parseInt(process.env.MINIO_PORT || '9000', 10),
      useSSL: process.env.MINIO_USE_SSL === 'true',
      accessKey: process.env.MINIO_ACCESS_KEY || 'minioadmin',
      secretKey: process.env.MINIO_SECRET_KEY || 'minioadmin',
    });
  } catch (err) {
    console.warn('⚠️ MinIO client initialization failed:', err);
  }
}

async function ensureBucketExists(): Promise<boolean> {
  if (!minioClient) return false;
  if (minioInitialized) return true;
  try {
    const exists = await minioClient.bucketExists(BUCKET_NAME);
    if (!exists) {
      await minioClient.makeBucket(BUCKET_NAME, 'us-east-1');
      console.log(`✅ MinIO bucket "${BUCKET_NAME}" created.`);
    }
    minioInitialized = true;
    return true;
  } catch (err: any) {
    console.warn(`⚠️ MinIO bucket check failed (${err.message}). Using local disk fallback.`);
    return false;
  }
}

export const handleFileUpload = async (req: Request, res: Response): Promise<void> => {
  if (!req.file) {
    res.status(400).json({ error: 'No file uploaded' });
    return;
  }

  const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
  const ext = path.extname(req.file.originalname).toLowerCase();
  const filename = `${uniqueSuffix}${ext}`;

  // Attempt upload to MinIO S3 bucket first
  if (minioClient) {
    try {
      const bucketReady = await ensureBucketExists();
      if (bucketReady) {
        await minioClient.putObject(
          BUCKET_NAME,
          filename,
          req.file.buffer,
          req.file.size,
          // Type from the (allow-listed) extension, never the client's claim.
          { 'Content-Type': mime(ext) }
        );

        const fileUrl = `/api/upload/file/${filename}`;
        res.status(200).json({
          message: 'File uploaded successfully to object storage',
          url: fileUrl,
          filename,
          originalName: req.file.originalname,
          storage: 'minio',
        });
        return;
      }
    } catch (err: any) {
      console.warn('⚠️ MinIO upload failed, falling back to local disk:', err.message);
    }
  }

  // Local disk fallback
  try {
    const uploadDir = path.join(__dirname, '../../uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    const filePath = path.join(uploadDir, filename);
    fs.writeFileSync(filePath, req.file.buffer);

    const fileUrl = `/uploads/${filename}`;
    res.status(200).json({
      message: 'File uploaded successfully to local storage',
      url: fileUrl,
      filename,
      originalName: req.file.originalname,
      storage: 'local',
    });
  } catch (err: any) {
    console.error('File Upload Error:', err);
    res.status(500).json({ error: 'Failed to save file' });
  }
};

// Uploaded names are always "<timestamp>-<random>.<ext>" (see handleFileUpload).
const STORED_NAME = /^\d+-\d+\.[a-z0-9]+$/;

const MIME: Record<string, string> = {
  '.pdf': 'application/pdf', '.txt': 'text/plain', '.csv': 'text/csv',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.webp': 'image/webp',
  '.mp4': 'video/mp4', '.webm': 'video/webm',
};
const mime = (ext: string) => MIME[ext] ?? 'application/octet-stream';

export const getFile = async (req: Request, res: Response): Promise<void> => {
  const filename = String(Array.isArray(req.params.filename) ? req.params.filename[0] : req.params.filename ?? '');
  // Reject anything that isn't a name we generated — blocks "../" path traversal.
  if (!STORED_NAME.test(filename)) {
    res.status(404).json({ error: 'File not found' });
    return;
  }
  res.type(mime(path.extname(filename)));

  if (minioClient) {
    try {
      const dataStream = await minioClient.getObject(BUCKET_NAME, filename);
      dataStream.pipe(res);
      return;
    } catch (err: any) {
      // Fall through to local filesystem
    }
  }

  const filePath = path.join(__dirname, '../../uploads', filename);
  if (fs.existsSync(filePath)) {
    res.sendFile(filePath);
  } else {
    res.status(404).json({ error: 'File not found' });
  }
};
