// lib/screens/student/course_content_screen.dart
import 'package:flutter/material.dart';
import '../../repository/course_repository.dart';
import '../../repository/progress_repository.dart';
import '../../repository/auth_repository.dart';
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
          userId: await _getUserId(),
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

  Future<String> _getUserId() async {
    final user = await AuthRepository().getCurrentUser();
    return user?['uid'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
              Theme.of(context).colorScheme.background,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary))
              : _course == null
                  ? _buildErrorView()
                  : _buildCourseContent(),
        ),
      ),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 12),
                        Text(
                          'Course Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _courseCompletion / 100,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_courseCompletion.toStringAsFixed(0)}% Complete',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(ModuleModel module, int moduleIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Text(
                '${moduleIndex + 1}',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              module.title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Text(
              '${module.lessons.length} ${module.lessons.length == 1 ? 'lesson' : 'lessons'}',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            children: module.lessons.map((lesson) => _buildLessonTile(module, lesson)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonTile(ModuleModel module, LessonModel lesson) {
    final progress = _progressMap[lesson.lessonId];
    final isCompleted = progress?.isCompleted ?? false;
    final isVideo = lesson.type == 'video' && lesson.videoURL != null && lesson.videoURL!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.withOpacity(0.2) : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getLessonIcon(lesson.type),
            color: isCompleted ? Colors.greenAccent : Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
        ),
        title: Text(
          lesson.title,
          style: TextStyle(color: Colors.white.withOpacity(isCompleted ? 0.6 : 0.9)),
        ),
        subtitle: Row(
          children: [
            if (lesson.duration > 0)
              Text(
                '${lesson.duration} min',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
              ),
            if (progress != null && !isCompleted) ...[
              const SizedBox(width: 8),
              Text(
                '${progress.completionPercentage.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary),
              ),
            ],
          ],
        ),
        trailing: isCompleted
            ? const Icon(Icons.check_circle, color: Colors.greenAccent)
            : Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
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
      ),
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


