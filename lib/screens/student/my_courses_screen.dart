// lib/screens/student/my_courses_screen.dart
import 'package:flutter/material.dart';
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

  bool _loading = true;
  List<CourseModel> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = null /* was FirebaseAuth.instance.currentUser */;
    if (user == null) {
      setState(() { _courses = []; _loading = false; });
      return;
    }
    final ids = await _enrollmentRepository.getUserCourseIds(uid: user.uid);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 80, color: Theme.of(context).disabledColor),
                      const SizedBox(height: 16),
                      Text('You have not enrolled in any courses yet',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(course.instructor),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseContentScreen(courseId: course.courseId, title: course.title),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}


