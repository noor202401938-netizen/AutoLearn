// lib/screens/admin/admin_course_management.dart
import 'package:flutter/material.dart';
import '../../business_logic/course_manager.dart';
import '../../model/course_model.dart';
import 'create_course_screen.dart';
import 'edit_course_screen.dart';
import 'course_content_management_screen.dart';

class AdminCourseManagement extends StatefulWidget {
  const AdminCourseManagement({super.key});

  @override
  State<AdminCourseManagement> createState() => _AdminCourseManagementState();
}

class _AdminCourseManagementState extends State<AdminCourseManagement> {
  final CourseManager _courseManager = CourseManager();
  List<CourseModel> _courses = [];
  List<CourseModel> _filteredCourses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterStatus; // 'published' or 'draft'

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final courses = await _courseManager.getAllCourses();
    setState(() {
      _courses = courses;
      _filteredCourses = courses;
      _isLoading = false;
    });
  }

  void _filterCourses() {
    setState(() {
      _filteredCourses = _courses.where((course) {
        bool matchesSearch = _searchQuery.isEmpty ||
            course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            course.instructor.toLowerCase().contains(_searchQuery.toLowerCase());

        bool matchesStatus = _filterStatus == null ||
            (_filterStatus == 'published' && course.isPublished) ||
            (_filterStatus == 'draft' && !course.isPublished);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _togglePublishStatus(CourseModel course) async {
    final updatedCourse = course.copyWith(
      isPublished: !course.isPublished,
      updatedAt: DateTime.now(),
    );

    final result = await _courseManager.updateCourse(updatedCourse);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedCourse.isPublished
                ? 'Course published successfully'
                : 'Course unpublished',
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
      _loadCourses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  Future<void> _deleteCourse(CourseModel course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "${course.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _courseManager.deleteCourse(course.courseId);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Course deleted successfully'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
        _loadCourses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        
        child: SafeArea(
          child: Column(
            children: [
              // Header with Stats
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : colorScheme.surfaceContainer,
                  border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course Management',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: _buildCreateButton(),
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Course Management',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildCreateButton(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatChip(
                        'Total',
                        _courses.length.toString(),
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Published',
                        _courses.where((c) => c.isPublished).length.toString(),
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Draft',
                        _courses
                            .where((c) => !c.isPublished)
                            .length
                            .toString(),
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search and Filters
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.3) : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: TextField(
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search courses...',
                        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onChanged: (value) {
                        _searchQuery = value;
                        _filterCourses();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterChip('All', null),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterChip('Published', 'published'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterChip('Draft', 'draft'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Course List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary),
                    )
                  : _filteredCourses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 80,
                                color: colorScheme.outlineVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No courses found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCourses,
                          color: Theme.of(context).colorScheme.secondary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: _filteredCourses.length,
                            itemBuilder: (context, index) {
                              return _buildCourseCard(
                                  _filteredCourses[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCreateButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          shadowColor: Colors.transparent,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Create Course', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCourseScreen(),
            ),
          );
          if (result == true) {
            _loadCourses();
          }
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () {
        setState(() => _filterStatus = value);
        _filterCourses();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : (isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.3) : colorScheme.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Icon(
                    Icons.school,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course.instructor,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: course.isPublished
                        ? Colors.greenAccent.withOpacity(0.1)
                        : Colors.orangeAccent.withOpacity(0.1),
                    border: Border.all(
                      color: course.isPublished
                          ? Colors.greenAccent.withOpacity(0.5)
                          : Colors.orangeAccent.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    course.isPublished ? 'PUBLISHED' : 'DRAFT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: course.isPublished ? Colors.greenAccent : Colors.orangeAccent,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('${course.enrollmentCount} enrolled', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 20),
                const Icon(Icons.star, size: 16, color: Colors.amberAccent),
                const SizedBox(width: 6),
                Text(course.rating.toStringAsFixed(1), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 20),
                Icon(Icons.access_time, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('${course.duration}h', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: colorScheme.outlineVariant),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: course.isPublished ? Icons.visibility_off : Icons.visibility,
                  color: course.isPublished ? Colors.orangeAccent : Colors.greenAccent,
                  tooltip: course.isPublished ? 'Unpublish' : 'Publish',
                  onPressed: () => _togglePublishStatus(course),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.edit,
                  color: Colors.blueAccent,
                  tooltip: 'Edit',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditCourseScreen(course: course),
                      ),
                    );
                    if (result == true) {
                      _loadCourses();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.folder,
                  color: Colors.purpleAccent,
                  tooltip: 'Manage Content',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseContentManagementScreen(course: course),
                      ),
                    ).then((_) => _loadCourses());
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.delete,
                  color: Colors.redAccent,
                  tooltip: 'Delete',
                  onPressed: () => _deleteCourse(course),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}