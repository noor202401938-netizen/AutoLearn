// Mounted at /api.
import { Router } from 'express';
import {
  listBookmarks, addBookmark, deleteBookmark,
  listLearningPaths, saveLearningPath, deleteLearningPath,
  listThreads, createThread, getThread, createReply, upvoteThread, upvoteReply, acceptReply, deleteThread,
} from '../controllers/community.controller';
import { authenticateToken, adminOnly } from '../middleware/auth.middleware';

const router = Router();
const auth = authenticateToken;

router.get('/user/bookmarks', auth, listBookmarks);
router.post('/user/bookmarks', auth, addBookmark);
router.delete('/user/bookmarks/:id', auth, deleteBookmark);

router.get('/learning-paths', auth, listLearningPaths);
router.post('/learning-paths', auth, adminOnly, saveLearningPath);
router.put('/learning-paths/:id', auth, adminOnly, saveLearningPath);
router.delete('/learning-paths/:id', auth, adminOnly, deleteLearningPath);

router.get('/forum/threads', auth, listThreads);
router.post('/forum/threads', auth, createThread);
router.get('/forum/threads/:id', auth, getThread);
router.delete('/forum/threads/:id', auth, deleteThread);
router.post('/forum/threads/:id/replies', auth, createReply);
router.post('/forum/threads/:id/upvote', auth, upvoteThread);
router.post('/forum/threads/:id/accept', auth, acceptReply);
router.post('/forum/replies/:id/upvote', auth, upvoteReply);

export default router;
