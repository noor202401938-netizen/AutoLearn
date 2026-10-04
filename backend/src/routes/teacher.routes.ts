import { Router } from 'express';
import {
  getOverview, getCourseStudents, listSubmissions, gradeSubmission, announceToCourse,
  listCoTeachers, addCoTeacher, removeCoTeacher, getEarnings,
} from '../controllers/teacher.controller';
import { authenticateToken, staffOnly } from '../middleware/auth.middleware';

const router = Router();
router.use(authenticateToken, staffOnly);

router.get('/overview', getOverview);
router.get('/courses/:id/students', getCourseStudents);
router.post('/courses/:id/announce', announceToCourse);
router.get('/courses/:id/co-teachers', listCoTeachers);
router.post('/courses/:id/co-teachers', addCoTeacher);
router.delete('/courses/:id/co-teachers/:userId', removeCoTeacher);
router.get('/earnings', getEarnings);
router.get('/submissions', listSubmissions);
router.put('/submissions/:id/grade', gradeSubmission);

export default router;
