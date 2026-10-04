import { Router } from 'express';
import { authenticateToken } from '../middleware/auth.middleware';
import { upload, handleFileUpload, getFile } from '../controllers/upload.controller';

const router = Router();

router.post('/', authenticateToken, upload.single('file'), handleFileUpload);
router.get('/file/:filename', getFile);

export default router;
