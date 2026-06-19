import { Router } from 'express';
import {
  getAllCourses,
  getCourseById,
  createCourse,
  updateCourse,
  deleteCourse,
  enrollInCourse,
  rateCourse,
} from '../controllers/course.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

// Public routes
router.get('/', getAllCourses);
router.get('/:id', getCourseById);

// Protected routes (require authentication)
router.use(authenticateToken);

router.post('/', createCourse);           // Admin only (enforced in controller)
router.put('/:id', updateCourse);         // Admin only (enforced in controller)
router.delete('/:id', deleteCourse);      // Admin only (enforced in controller)
router.post('/:id/enroll', enrollInCourse);
router.post('/:id/rate', rateCourse);

export default router;
