// lib/screens/student/project_screen.dart
import 'package:flutter/material.dart';
import 'assignment_screen.dart';

class ProjectScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const ProjectScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project: $courseTitle'),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment, size: 80, color: Color(0xFF4169E1)),
              const SizedBox(height: 24),
              const Text(
                'Course Project',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Complete the final project to demonstrate your understanding.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignmentScreen(
                        courseId: courseId,
                        courseTitle: courseTitle,
                        moduleId: 'project',
                        moduleTitle: 'Final Project',
                        lessonId: 'project_$courseId',
                        lessonTitle: 'Final Project: $courseTitle',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Start Project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

