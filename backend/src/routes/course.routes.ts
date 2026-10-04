import { Router } from 'express';
import {
  getAllCourses,
  getCourseById,
  createCourse,
  updateCourse,
  deleteCourse,
  enrollInCourse,
  rateCourse,
  getCourseStats,
} from '../controllers/course.controller';
import { authenticateToken, optionalAuth } from '../middleware/auth.middleware';

const router = Router();

// Public routes
// Public, but the answer depends on who asks: drafts are visible only to their teachers.
router.get('/', optionalAuth, getAllCourses);
router.get('/:id', optionalAuth, getCourseById);
router.get('/:id/stats', optionalAuth, getCourseStats);

// Protected routes (require authentication)
router.use(authenticateToken);

router.post('/', createCourse);           // Admin, or teacher (ownership enforced in controller)
router.put('/:id', updateCourse);         // Admin, or teacher (ownership enforced in controller)
router.delete('/:id', deleteCourse);      // Admin, or teacher (ownership enforced in controller)
router.post('/:id/enroll', enrollInCourse);
router.post('/:id/rate', rateCourse);

export default router;
