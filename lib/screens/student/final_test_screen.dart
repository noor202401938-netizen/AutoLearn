// lib/screens/student/final_test_screen.dart
import 'package:flutter/material.dart';
import '../../business_logic/ai_quiz_engine.dart';
import '../../model/quiz_model.dart';
import 'ai_quiz_screen.dart';

class FinalTestScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const FinalTestScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Final Test: $courseTitle'),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz, size: 80, color: Color(0xFF4169E1)),
              const SizedBox(height: 24),
              const Text(
                'Final Test',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This is the final assessment for the course.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to quiz screen with final test flag
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AIQuizScreen(
                        courseId: courseId,
                        courseTitle: courseTitle,
                        moduleId: 'final',
                        moduleTitle: 'Final Test',
                        lessonId: 'final_test_$courseId',
                        lessonTitle: 'Final Test: $courseTitle',
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
                child: const Text('Start Final Test'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

