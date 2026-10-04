// Mounted at /api: quiz/assignment content is shared, submissions are per user.
import { Router } from 'express';
import {
  getQuizByLesson, upsertQuiz, submitQuiz, getQuizSubmission,
  getAssignmentByLesson, upsertAssignment, listMyAssignments, submitAssignment, getAssignmentSubmission,
  getUserCertificates, checkCertificate, issueCertificate, getCourseProgress,
} from '../controllers/learning.controller';
import { authenticateToken, adminOnly } from '../middleware/auth.middleware';

const router = Router();

router.get('/quizzes/lesson/:lessonId', authenticateToken, getQuizByLesson);
router.post('/quizzes', authenticateToken, adminOnly, upsertQuiz);
router.post('/user/quizzes/:quizId/submit', authenticateToken, submitQuiz);
router.get('/user/quizzes/:quizId/submission', authenticateToken, getQuizSubmission);

router.get('/assignments/lesson/:lessonId', authenticateToken, getAssignmentByLesson);
router.post('/assignments', authenticateToken, adminOnly, upsertAssignment);
router.get('/user/assignments', authenticateToken, listMyAssignments);
router.post('/user/assignments/:assignmentId/submit', authenticateToken, submitAssignment);
router.get('/user/assignments/:assignmentId/submission', authenticateToken, getAssignmentSubmission);

router.get('/user/certificates', authenticateToken, getUserCertificates);
router.get('/user/certificates/check', authenticateToken, checkCertificate);
router.post('/user/certificates', authenticateToken, issueCertificate);

router.get('/user/courses/:courseId/progress', authenticateToken, getCourseProgress);

export default router;
