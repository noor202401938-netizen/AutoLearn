import 'package:flutter/material.dart';
import '../../repository/auth_repository.dart';
import '../../repository/enrollment_repository.dart';
import '../../repository/course_repository.dart';
import '../../model/course_model.dart';
import 'course_content_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();
  final CourseRepository _courseRepository = CourseRepository();
  final AuthRepository _authRepository = AuthRepository();

  bool _loading = true;
  List<CourseModel> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = await _authRepository.getCurrentUser();
    final uid = user?['uid'] as String?;
    if (uid == null) {
      setState(() {
        _courses = [];
        _loading = false;
      });
      return;
    }
    final ids = await _enrollmentRepository.getUserCourseIds(uid: uid);
    final List<CourseModel> result = [];
    for (final id in ids) {
      final course = await _courseRepository.getCourseById(id);
      if (course != null) result.add(course);
    }
    setState(() {
      _courses = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('My Courses', style: theme.textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('You have not enrolled in any courses yet',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: colorScheme.secondary,
                  backgroundColor: colorScheme.surface,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseContentScreen(
                                    courseId: course.courseId,
                                    title: course.title),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: course.thumbnailURL.isNotEmpty
                                      ? Image.network(
                                          course.thumbnailURL,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildPlaceholder(colorScheme),
                                        )
                                      : _buildPlaceholder(colorScheme),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        course.instructor,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .secondaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.star_rounded,
                                                    size: 14,
                                                    color:
                                                        colorScheme.secondary),
                                                const SizedBox(width: 3),
                                                Text(
                                                  course.rating > 0
                                                      ? course.rating
                                                          .toStringAsFixed(1)
                                                      : '-',
                                                  style: theme
                                                      .textTheme.labelMedium
                                                      ?.copyWith(
                                                          color: colorScheme
                                                              .secondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.group_outlined,
                                                    size: 14,
                                                    color: colorScheme
                                                        .onSurfaceVariant),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${course.enrollmentCount}',
                                                  style: theme
                                                      .textTheme.labelMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          Icon(Icons.play_lesson_rounded, color: colorScheme.primary, size: 28),
    );
  }
}
