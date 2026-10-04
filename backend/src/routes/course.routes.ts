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
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

// Public routes
router.get('/', (req, res, next) => (req.query.mine === 'true' ? authenticateToken(req, res, next) : next()), getAllCourses);
router.get('/:id', getCourseById);
router.get('/:id/stats', getCourseStats);

// Protected routes (require authentication)
router.use(authenticateToken);

router.post('/', createCourse);           // Admin, or teacher (ownership enforced in controller)
router.put('/:id', updateCourse);         // Admin, or teacher (ownership enforced in controller)
router.delete('/:id', deleteCourse);      // Admin, or teacher (ownership enforced in controller)
router.post('/:id/enroll', enrollInCourse);
router.post('/:id/rate', rateCourse);

export default router;
