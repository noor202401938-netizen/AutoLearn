// lib/screens/student/course_content_screen.dart
import 'package:flutter/material.dart';
import '../../repository/course_repository.dart';
import '../../repository/progress_repository.dart';
import '../../repository/auth_repository.dart';
import '../../business_logic/video_manager.dart';
import '../../model/course_model.dart';
import '../../model/video_progress_model.dart';
import 'package:google_fonts/google_fonts.dart';
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
          userId: await _getUserId(),
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
      backgroundColor: const Color(0xFFf8f9ff),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _course == null
              ? _buildErrorView()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Stack(
                      children: [
                    // Main Content
                    RefreshIndicator(
                      onRefresh: _loadCourseContent,
                      child: CustomScrollView(
                        slivers: [
                          _buildSliverAppBar(),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 100),
                              child: _buildCourseContent(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Fixed Bottom CTA
                    if (_course!.syllabus.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 20,
                            top: 20,
                            left: 20,
                            right: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _handleContinueLearning,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_circle_fill, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Continue Learning',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      title: Text(
        'AutoLearn',
        style: GoogleFonts.geist(
          color: const Color(0xFF4231C0),
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.person, size: 20, color: Colors.white),
          ),
        ),
      ],
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
              style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
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
                style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).disabledColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroSection(),
        _buildProgressSummary(),
        _buildModuleList(),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Player Placeholder
          GestureDetector(
            onTap: _handleContinueLearning,
            child: Container(
              width: double.infinity,
              aspectRatio: 16 / 9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFd9e3f6),
                image: _course!.thumbnailURL.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_course!.thumbnailURL),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  // Progress overlay on video bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFd9e3f6),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _courseCompletion / 100,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF10b981), Color(0xFF14b8a6)],
                            ),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            style: GoogleFonts.geist(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF121c2a),
              height: 1.2,
              letterSpacing: -0.64, // -0.02em
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                _course!.instructor,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF474554),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFc8c4d7), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                'Lead Instructor',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFeff4ff), // surface-container-low
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5b4ed9).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OVERALL PROGRESS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6, // 0.05em
                  color: const Color(0xFF474554),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_courseCompletion.toStringAsFixed(0)}%',
                    style: GoogleFonts.geist(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121c2a),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Complete',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF474554),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _courseCompletion / 100,
                  backgroundColor: const Color(0xFFd9e3f6),
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  strokeWidth: 4,
                ),
                Center(
                  child: Text(
                    '${_courseCompletion.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Course Modules',
                style: GoogleFonts.geist(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121c2a),
                ),
              ),
              Text(
                '${_course!.syllabus.length} Modules',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF474554),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _course!.syllabus.length,
          itemBuilder: (context, index) {
            return _buildModuleCard(_course!.syllabus[index], index);
          },
        ),
      ],
    );
  }

  bool _isModuleCompleted(ModuleModel module) {
    if (module.lessons.isEmpty) return false;
    for (var lesson in module.lessons) {
      if (!(_progressMap[lesson.lessonId]?.isCompleted ?? false)) {
        return false;
      }
    }
    return true;
  }

  double _getModuleProgress(ModuleModel module) {
    if (module.lessons.isEmpty) return 0.0;
    int completed = 0;
    for (var lesson in module.lessons) {
      if (_progressMap[lesson.lessonId]?.isCompleted ?? false) {
        completed++;
      }
    }
    return (completed / module.lessons.length) * 100;
  }

  Widget _buildModuleCard(ModuleModel module, int moduleIndex) {
    final bool isCompleted = _isModuleCompleted(module);
    
    // Determine if it is the "current" module (first incomplete module)
    bool isCurrent = false;
    if (!isCompleted) {
      // Check if previous modules are completed
      bool previousCompleted = true;
      for (int i = 0; i < moduleIndex; i++) {
        if (!_isModuleCompleted(_course!.syllabus[i])) {
          previousCompleted = false;
          break;
        }
      }
      isCurrent = previousCompleted;
    }

    if (isCompleted) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFc8c4d7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5b4ed9).withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF00724e).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF00573a)),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPLETED',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00573a),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Module ${moduleIndex + 1}: ${module.title}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF121c2a),
                  ),
                ),
              ],
            ),
            children: module.lessons.map((lesson) => _buildLessonTile(module, lesson)).toList(),
          ),
        ),
      );
    } else if (isCurrent) {
      final double modProgress = _getModuleProgress(module);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFeff4ff),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4231c0), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5b4ed9).withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4231c0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT MODULE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4231c0),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Module ${moduleIndex + 1}: ${module.title}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF121c2a),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 72, right: 16, bottom: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Section Progress',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF474554),
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          '${modProgress.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: modProgress / 100,
                        backgroundColor: const Color(0xFFd9e3f6),
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              ...module.lessons.map((lesson) => _buildLessonTile(module, lesson)).toList(),
            ],
          ),
        ),
      );
    } else {
      // Locked Module
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFc8c4d7).withOpacity(0.5)),
        ),
        child: Opacity(
          opacity: 0.6,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFc8c4d7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock, color: Color(0xFF787586)),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCKED',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF787586),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Module ${moduleIndex + 1}: ${module.title}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF121c2a),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLessonTile(ModuleModel module, LessonModel lesson) {
    final progress = _progressMap[lesson.lessonId];
    final isCompleted = progress?.isCompleted ?? false;
    final isVideo = lesson.type == 'video' && lesson.videoURL != null && lesson.videoURL!.isNotEmpty;

    return InkWell(
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: const Color(0xFFc8c4d7).withOpacity(0.3))),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.withOpacity(0.1) : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getLessonIcon(lesson.type),
                color: isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF121c2a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (lesson.duration > 0)
                        Text(
                          '${lesson.duration} min',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF474554),
                          ),
                        ),
                      if (progress != null && !isCompleted && progress.completionPercentage > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${progress.completionPercentage.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            isCompleted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.chevron_right, color: Color(0xFF787586)),
          ],
        ),
      ),
    );
  }

  void _handleContinueLearning() {
    if (_course == null || _course!.syllabus.isEmpty) return;
    
    // Find first incomplete lesson
    for (var module in _course!.syllabus) {
      for (var lesson in module.lessons) {
        if (!(_progressMap[lesson.lessonId]?.isCompleted ?? false)) {
          if (lesson.type == 'video' && lesson.videoURL != null && lesson.videoURL!.isNotEmpty) {
            _navigateToVideoPlayer(module, lesson);
          } else if (lesson.type == 'quiz') {
            _navigateToQuiz(module, lesson);
          } else if (lesson.type == 'assignment') {
            _navigateToAssignment(module, lesson);
          } else {
            _showLessonInfo(lesson);
          }
          return;
        }
      }
    }
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'video': return Icons.play_circle_outline;
      case 'quiz': return Icons.quiz_outlined;
      case 'assignment': return Icons.assignment_outlined;
      case 'reading': return Icons.article_outlined;
      default: return Icons.circle_outlined;
    }
  }

  void _navigateToVideoPlayer(ModuleModel module, LessonModel lesson) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(courseId: widget.courseId, courseTitle: widget.title, moduleId: module.moduleId, moduleTitle: module.title, lesson: lesson, videoManager: _videoManager,))).then((_) => _loadCourseContent());
  }

  void _navigateToQuiz(ModuleModel module, LessonModel lesson) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AIQuizScreen(courseId: widget.courseId, courseTitle: widget.title, moduleId: module.moduleId, moduleTitle: module.title, lessonId: lesson.lessonId, lessonTitle: lesson.title,))).then((_) => _loadCourseContent());
  }

  void _navigateToAssignment(ModuleModel module, LessonModel lesson) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AssignmentScreen(courseId: widget.courseId, courseTitle: widget.title, moduleId: module.moduleId, moduleTitle: module.title, lessonId: lesson.lessonId, lessonTitle: lesson.title,))).then((_) => _loadCourseContent());
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}


