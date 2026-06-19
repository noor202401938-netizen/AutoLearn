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
          const SnackBar(
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with Stats
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                            const Text(
                              'Course Management',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Create Course'),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CreateCourseScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadCourses();
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Course Management',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Course'),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateCourseScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadCourses();
                              }
                            },
                          ),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search courses...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterCourses();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _filterStatus == null,
                          onSelected: (selected) {
                            setState(() => _filterStatus = null);
                            _filterCourses();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Published'),
                          selected: _filterStatus == 'published',
                          selectedColor: Colors.green.shade100,
                          onSelected: (selected) {
                            setState(() => _filterStatus = 'published');
                            _filterCourses();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Draft'),
                          selected: _filterStatus == 'draft',
                          selectedColor: Colors.orange.shade100,
                          onSelected: (selected) {
                            setState(() => _filterStatus = 'draft');
                            _filterCourses();
                          },
                        ),
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
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No courses found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCourses,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.instructor,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: course.isPublished
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    course.isPublished ? 'PUBLISHED' : 'DRAFT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: course.isPublished ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${course.enrollmentCount} enrolled'),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(course.rating.toStringAsFixed(1)),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${course.duration}h'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    course.isPublished
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: course.isPublished ? Colors.orange : Colors.green,
                  ),
                  onPressed: () => _togglePublishStatus(course),
                  tooltip: course.isPublished ? 'Unpublish' : 'Publish',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
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
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.folder, color: Colors.purple),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseContentManagementScreen(course: course),
                      ),
                    ).then((_) => _loadCourses());
                  },
                  tooltip: 'Manage Content',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCourse(course),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}