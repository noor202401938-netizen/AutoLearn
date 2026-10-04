import { Router } from 'express';
import { getOverview, getCourseStudents, listSubmissions, gradeSubmission, announceToCourse } from '../controllers/teacher.controller';
import { authenticateToken, staffOnly } from '../middleware/auth.middleware';

const router = Router();
router.use(authenticateToken, staffOnly);

router.get('/overview', getOverview);
router.get('/courses/:id/students', getCourseStudents);
router.post('/courses/:id/announce', announceToCourse);
router.get('/submissions', listSubmissions);
router.put('/submissions/:id/grade', gradeSubmission);

export default router;
