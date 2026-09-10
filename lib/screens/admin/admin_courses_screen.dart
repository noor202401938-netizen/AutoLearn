import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../business_logic/course_manager.dart';
import '../../model/course_model.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  final CourseManager _courseManager = CourseManager();
  bool _isLoading = true;
  List<CourseModel> _allCourses = [];
  List<CourseModel> _filteredCourses = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _courseManager.getAllCourses();
      if (mounted) {
        setState(() {
          _allCourses = courses;
          _filteredCourses = courses;
          _isLoading = false;
        });
        _applyFilter(_selectedFilter);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredCourses = List.from(_allCourses);
      } else if (filter == 'Published') {
        _filteredCourses = _allCourses.where((c) => c.isPublished).toList();
      } else if (filter == 'Drafts') {
        _filteredCourses = _allCourses.where((c) => !c.isPublished).toList();
      } else if (filter == 'Archived') {
        _filteredCourses = []; // Assuming no explicit archived flag for now
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Header
              Text(
                'Course Management',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and organize your learning curriculum.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3)
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        _applyFilter(_selectedFilter);
                      } else {
                        _filteredCourses = _allCourses
                            .where((c) => c.title
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    hintStyle: GoogleFonts.inter(color: colorScheme.outline),
                    prefixIcon:
                        Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(context, 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'Published'),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'Drafts'),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'Archived'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Courses List Grid for Desktop / List for Mobile
              if (_isLoading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_filteredCourses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('No courses found',
                        style: theme.textTheme.bodyMedium),
                  ),
                )
              else
                LayoutBuilder(builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  return GridView.builder(
                    itemCount: _filteredCourses.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 2 : 1,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: isDesktop ? 3 : 2.5,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
                      final isPublished = course.isPublished;
                      return _buildCourseCard(
                        context: context,
                        title: course.title,
                        status: isPublished ? 'PUBLISHED' : 'DRAFT',
                        statusBg: isPublished
                            ? colorScheme.secondaryContainer
                            : colorScheme.primaryContainer,
                        statusColor: isPublished
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onPrimaryContainer,
                        enrolled: '${course.enrollmentCount}',
                        progress: isPublished ? 1.0 : 0.0,
                        isDraft: !isPublished,
                      );
                    },
                  );
                }),

              const SizedBox(height: 100), // Space for FAB/Nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () => _applyFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : (isDark
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surface),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required String title,
    required String status,
    required Color statusBg,
    required Color statusColor,
    required String enrolled,
    required double progress,
    bool isDraft = false,
    bool isArchived = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDraft
                      ? colorScheme.outlineVariant.withValues(alpha: 0.4)
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDraft ? Icons.edit_outlined : Icons.check_circle_rounded,
                      size: 11,
                      color: isDraft ? colorScheme.onSurfaceVariant : colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDraft ? colorScheme.onSurfaceVariant : colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '$enrolled enrolled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isDraft ? 0.0 : progress,
                    minHeight: 5,
                    backgroundColor: colorScheme.primaryContainer,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}
