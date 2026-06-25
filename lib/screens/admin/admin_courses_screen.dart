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
                  color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.3) : const Color(0xFFeff4ff),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        _applyFilter(_selectedFilter);
                      } else {
                        _filteredCourses = _allCourses
                            .where((c) => c.title.toLowerCase().contains(value.toLowerCase()))
                            .toList();
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    hintStyle: GoogleFonts.inter(color: colorScheme.outline),
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_filteredCourses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('No courses found', style: theme.textTheme.bodyMedium),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
      final theme = Theme.of(context);
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
                          statusBg: isPublished ? const Color(0xFF6ffbbe) : const Color(0xFFe9ddff),
                          statusColor: isPublished ? const Color(0xFF002113) : const Color(0xFF23005c),
                          enrolled: '${course.enrollmentCount}',
                          progress: isPublished ? 1.0 : 0.0,
                          isDraft: !isPublished,
                        );
                      },
                    );
                  }
                ),

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
          color: isSelected ? colorScheme.primary : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Image / Thumbnail area
          Container(
            width: 100,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainer : const Color(0xFFd9e3f6),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(8),
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '$enrolled Enrolled',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: isDraft
                            ? Text('Drafting in progress...', style: theme.textTheme.bodyMedium)
                            : isArchived
                                ? Text('Access Restricted', style: theme.textTheme.bodyMedium)
                                : Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isDark ? colorScheme.surfaceContainerHigh : const Color(0xFFe6eeff),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: progress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFF4edea3), Color(0xFF00724e)]),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.chevron_right, color: colorScheme.primary),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
