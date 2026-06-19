// lib/screens/student/my_courses_screen.dart
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

  bool _loading = true;
  List<CourseModel> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = AuthRepository.getCurrentUser();
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Courses', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _courses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book, size: 80, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text('You have not enrolled in any courses yet',
                              style: TextStyle(color: Colors.white.withOpacity(0.7))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: Theme.of(context).colorScheme.secondary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _courses.length,
                        itemBuilder: (context, index) {
                          final course = _courses[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text(
                                course.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  course.instructor,
                                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                ),
                              ),
                              trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
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
        ),
      ),
    );
  }
}


