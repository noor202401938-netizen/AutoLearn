// lib/screens/student/course_content_screen.dart
import 'package:flutter/material.dart';
import '../../repository/course_repository.dart';
import '../../repository/progress_repository.dart';
import '../../business_logic/video_manager.dart';
import '../../model/course_model.dart';
import '../../model/video_progress_model.dart';
import 'video_player_screen.dart';
import 'ai_quiz_screen.dart';
import 'assignment_screen.dart';

class CourseContentScreen extends StatefulWidget {
  final String courseId;
  final String title;
  const CourseContentScreen({super.key, required this.courseId, required this.title});

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen> {
  final CourseRepository _courseRepository = CourseRepository();
  final VideoManager _videoManager = VideoManager();
  final ProgressRepository _progressRepository = ProgressRepository();

  bool _loading = true;
  CourseModel? _course;
  Map<String, VideoProgressModel> _progressMap = {};
  double _courseCompletion = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCourseContent();
  }

  Future<void> _loadCourseContent() async {
    setState(() => _loading = true);
    try {
      final course = await _courseRepository.getCourseById(widget.courseId);
      if (course != null) {
        // Load progress for all lessons
        final progressList = await _progressRepository.getCourseProgress(
          userId: _getUserId(),
          courseId: widget.courseId,
        );

        final progressMap = <String, VideoProgressModel>{};
        for (var progress in progressList) {
          progressMap[progress.lessonId] = progress;
        }

        // Calculate course completion
        final totalLessons = course.syllabus.fold<int>(
          0,
          (sum, module) => sum + module.lessons.length,
        );
        final completion = await _progressRepository.getCourseCompletionPercentage(
          userId: _getUserId(),
          courseId: widget.courseId,
          totalLessons: totalLessons,
        );

        setState(() {
          _course = course;
          _progressMap = progressMap;
          _courseCompletion = completion;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _getUserId() {
    final user = null /* was FirebaseAuth.instance.currentUser */;
    return user?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _course == null
              ? _buildErrorView()
              : _buildCourseContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load course content',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCourseContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseContent() {
    if (_course!.syllabus.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, size: 64, color: Theme.of(context).disabledColor),
              const SizedBox(height: 16),
              Text(
                'No content available yet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Theme.of(context).disabledColor),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCourseContent,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Course Progress Card
            if (_courseCompletion > 0)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Course Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _courseCompletion / 100,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_courseCompletion.toStringAsFixed(0)}% Complete',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Modules List
            ..._course!.syllabus.asMap().entries.map((entry) {
              final moduleIndex = entry.key;
              final module = entry.value;
              return _buildModuleCard(module, moduleIndex);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(ModuleModel module, int moduleIndex) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            '${moduleIndex + 1}',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          module.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${module.lessons.length} ${module.lessons.length == 1 ? 'lesson' : 'lessons'}'),
        children: module.lessons.map((lesson) => _buildLessonTile(module, lesson)).toList(),
      ),
    );
  }

  Widget _buildLessonTile(ModuleModel module, LessonModel lesson) {
    final progress = _progressMap[lesson.lessonId];
    final isCompleted = progress?.isCompleted ?? false;
    final isVideo = lesson.type == 'video' && lesson.videoURL != null && lesson.videoURL!.isNotEmpty;

    return ListTile(
      leading: Icon(
        _getLessonIcon(lesson.type),
        color: isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
      ),
      title: Text(lesson.title),
      subtitle: Row(
        children: [
          if (lesson.duration > 0)
            Text(
              '${lesson.duration} min',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          if (progress != null && !isCompleted) ...[
            const SizedBox(width: 8),
            Text(
              '${progress.completionPercentage.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ],
      ),
      trailing: isCompleted
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.chevron_right),
      onTap: () {
        if (isVideo) {
          _navigateToVideoPlayer(module, lesson);
        } else if (lesson.type == 'quiz') {
          _navigateToQuiz(module, lesson);
        } else if (lesson.type == 'assignment') {
          _navigateToAssignment(module, lesson);
        } else {
          _showLessonInfo(lesson);
        }
      },
    );
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'reading':
        return Icons.article_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  void _navigateToVideoPlayer(ModuleModel module, LessonModel lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          courseId: widget.courseId,
          courseTitle: widget.title,
          moduleId: module.moduleId,
          moduleTitle: module.title,
          lesson: lesson,
          videoManager: _videoManager,
        ),
      ),
    ).then((_) {
      // Reload progress when returning from video player
      _loadCourseContent();
    });
  }

  void _navigateToQuiz(ModuleModel module, LessonModel lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIQuizScreen(
          courseId: widget.courseId,
          courseTitle: widget.title,
          moduleId: module.moduleId,
          moduleTitle: module.title,
          lessonId: lesson.lessonId,
          lessonTitle: lesson.title,
        ),
      ),
    ).then((_) {
      _loadCourseContent();
    });
  }

  void _navigateToAssignment(ModuleModel module, LessonModel lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentScreen(
          courseId: widget.courseId,
          courseTitle: widget.title,
          moduleId: module.moduleId,
          moduleTitle: module.title,
          lessonId: lesson.lessonId,
          lessonTitle: lesson.title,
        ),
      ),
    ).then((_) {
      _loadCourseContent();
    });
  }

  void _showLessonInfo(LessonModel lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lesson.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${lesson.type}'),
            if (lesson.duration > 0) Text('Duration: ${lesson.duration} minutes'),
            if (lesson.content != null && lesson.content!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(lesson.content!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}


