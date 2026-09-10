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
import 'project_screen.dart';

class CourseContentScreen extends StatefulWidget {
  final String courseId;
  final String title;
  const CourseContentScreen(
      {super.key, required this.courseId, required this.title});

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
  // Cached user ID — fetched once during load, used everywhere
  String _cachedUserId = '';
  // Cached user photo URL for AppBar — avoids per-rebuild API calls
  String? _cachedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadCourseContent();
  }

  Future<void> _loadCourseContent() async {
    setState(() => _loading = true);
    try {
      // Resolve user once and cache — avoids redundant API calls below
      final user = await AuthRepository().getCurrentUser();
      _cachedUserId = user?['uid'] as String? ?? '';
      _cachedPhotoUrl = user?['photoUrl'] as String?;

      final course = await _courseRepository.getCourseById(widget.courseId);
      if (course != null) {
        // Load progress for all lessons using the cached user ID
        final progressList = await _progressRepository.getCourseProgress(
          userId: _cachedUserId,
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
        final completion =
            await _progressRepository.getCourseCompletionPercentage(
          userId: _cachedUserId,
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



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary))
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
                                bottom:
                                    MediaQuery.of(context).padding.bottom + 20,
                                top: 20,
                                left: 20,
                                right: 20,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface
                                    .withValues(alpha: 0.9),
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 1200),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _handleContinueLearning,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.play_circle_fill,
                                                  color: theme
                                                      .colorScheme.onPrimary),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Continue Learning',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  color: theme
                                                      .colorScheme.onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        'AutoLearn',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: theme.colorScheme.primaryContainer, width: 2),
            ),
            child: ClipOval(
              // Use cached photo URL — no per-rebuild API call
              child: _cachedPhotoUrl != null && _cachedPhotoUrl!.isNotEmpty
                  ? Image.network(_cachedPhotoUrl!, fit: BoxFit.cover)
                  : Container(
                      color: theme.colorScheme.primaryContainer,
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 20),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load course content',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
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
    final theme = Theme.of(context);
    if (_course!.syllabus.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book,
                  size: 64, color: Theme.of(context).disabledColor),
              const SizedBox(height: 16),
              Text(
                'No content available yet',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.disabledColor),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Player Placeholder
          GestureDetector(
            onTap: _handleContinueLearning,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                  image: _course!.thumbnailURL.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_course!.thumbnailURL),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          size: 32,
                          color: theme.colorScheme.primary,
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
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _courseCompletion / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer,
                ),
                child: ClipOval(
                  child: Container(
                    color: theme.colorScheme.primaryContainer,
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _course!.instructor,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lead Instructor',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_courseCompletion.toStringAsFixed(0)}%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Complete',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                  value: 1.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.surfaceContainerHighest),
                  strokeWidth: 4,
                ),
                CircularProgressIndicator(
                  value: _courseCompletion / 100,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  strokeWidth: 4,
                ),
                Center(
                  child: Text(
                    '${_courseCompletion.toStringAsFixed(0)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
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
    final theme = Theme.of(context);
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
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_course!.syllabus.length} Modules',
                style: theme.textTheme.bodyMedium,
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
    final theme = Theme.of(context);
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
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.tertiaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.check_circle, color: theme.colorScheme.tertiary),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPLETED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Module ${moduleIndex + 1}: ${module.title}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            children: module.lessons
                .map((lesson) => _buildLessonTile(module, lesson))
                .toList(),
          ),
        ),
      );
    } else if (isCurrent) {
      final double modProgress = _getModuleProgress(module);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary, width: 2),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.play_arrow, color: theme.colorScheme.onPrimary),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT MODULE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Module ${moduleIndex + 1}: ${module.title}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
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
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${modProgress.toStringAsFixed(0)}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: modProgress / 100,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              ...module.lessons
                  .map((lesson) => _buildLessonTile(module, lesson)),
            ],
          ),
        ),
      );
    } else {
      // Locked Module
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Opacity(
          opacity: 0.6,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lock, color: theme.colorScheme.outline),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCKED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Module ${moduleIndex + 1}: ${module.title}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
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
    final theme = Theme.of(context);
    final progress = _progressMap[lesson.lessonId];
    final isCompleted = progress?.isCompleted ?? false;
    final isVideo = lesson.type == 'video' &&
        lesson.videoURL != null &&
        lesson.videoURL!.isNotEmpty;

    return InkWell(
      onTap: () {
        if (isVideo) {
          _navigateToVideoPlayer(module, lesson);
        } else if (lesson.type == 'quiz') {
          _navigateToQuiz(module, lesson);
        } else if (lesson.type == 'assignment') {
          _navigateToAssignment(module, lesson);
        } else if (lesson.type == 'project') {
          _navigateToProject(module, lesson);
        } else {
          _showLessonInfo(lesson);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3))),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getLessonIcon(lesson.type),
                color: isCompleted
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (lesson.duration > 0)
                        Text(
                          '${lesson.duration} min',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (progress != null &&
                          !isCompleted &&
                          progress.completionPercentage > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${progress.completionPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
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
                ? Icon(Icons.check_circle, color: theme.colorScheme.secondary)
                : Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
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
          if (lesson.type == 'video' &&
              lesson.videoURL != null &&
              lesson.videoURL!.isNotEmpty) {
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
                  course: _course,
                ))).then((_) => _loadCourseContent());
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
                ))).then((_) => _loadCourseContent());
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
                ))).then((_) => _loadCourseContent());
  }

  void _navigateToProject(ModuleModel module, LessonModel lesson) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProjectScreen(
                  courseId: widget.courseId,
                  courseTitle: widget.title,
                  lessonId: lesson.lessonId,
                  lessonTitle: lesson.title,
                ))).then((_) => _loadCourseContent());
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
            if (lesson.duration > 0)
              Text('Duration: ${lesson.duration} minutes'),
            if (lesson.content != null && lesson.content!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Content:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(lesson.content!),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}
