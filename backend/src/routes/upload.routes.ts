import { Router } from 'express';
import { authenticateToken } from '../middleware/auth.middleware';
import { upload, handleFileUpload } from '../controllers/upload.controller';

const router = Router();

router.post('/', authenticateToken, upload.single('file'), handleFileUpload);

export default router;
