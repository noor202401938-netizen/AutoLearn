// lib/business_logic/ai_feedback_engine.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/quiz_model.dart';
import '../repository/quiz_repository.dart';

class AIFeedbackEngine {
  final QuizRepository _quizRepository = QuizRepository();

  // OpenAI API Configuration
  static const String _openAIApiKey =
      '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';
  static const String _openAIApiUrl =
      'https://api.openai.com/v1/chat/completions';

  // Generate feedback for assignment submission
  Future<String> generateAssignmentFeedback({
    required String assignmentTitle,
    required String assignmentInstructions,
    required String studentSubmission,
    int maxPoints = 100,
  }) async {
    try {
      final prompt = '''
You are an expert instructor grading a student assignment.
Provide constructive feedback and a score between 0 and 100.
Assignment: $assignmentTitle
Instructions: $assignmentInstructions
Maximum Points: $maxPoints

Student Submission:
$studentSubmission

Please provide:
1. A score out of $maxPoints points
2. Detailed feedback on what the student did well
3. Areas for improvement
4. Suggestions for further learning

Format your response as:
Score: X/$maxPoints

Feedback:
[Your detailed feedback here]
''';

      final response = await http.post(
        Uri.parse(_openAIApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert educator providing constructive feedback on student assignments.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['choices'][0]['message']['content'].trim();
      } else {
        return 'Feedback generation is temporarily unavailable. Your submission has been received.';
      }
    } catch (e) {
      return 'Feedback generation is temporarily unavailable. Your submission has been received.';
    }
  }

  // Extract score from feedback
  int? extractScoreFromFeedback(String feedback, int maxPoints) {
    try {
      // Look for "Score: X/maxPoints" pattern
      final regex = RegExp(r'Score:\s*(\d+)/\d+', caseSensitive: false);
      final match = regex.firstMatch(feedback);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }

      // Look for just a number at the start
      final numberRegex = RegExp(r'^(\d+)');
      final numberMatch = numberRegex.firstMatch(feedback);
      if (numberMatch != null) {
        final score = int.tryParse(numberMatch.group(1)!);
        if (score != null && score <= maxPoints) {
          return score;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Generate personalized feedback for quiz answers
  Future<String> generateQuizAnswerFeedback({
    required String questionText,
    required String? correctAnswer,
    required String? studentAnswer,
    required bool isCorrect,
    String? explanation,
  }) async {
    if (isCorrect && explanation != null) {
      return explanation;
    }

    try {
      final prompt = '''
Question: $questionText
Correct Answer: ${correctAnswer ?? 'N/A'}
Student Answer: ${studentAnswer ?? 'No answer provided'}
Is Correct: $isCorrect

Provide helpful feedback explaining why the answer is ${isCorrect ? 'correct' : 'incorrect'} and how the student can improve their understanding.
''';

      final response = await http.post(
        Uri.parse(_openAIApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert tutor providing helpful feedback on quiz answers.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['choices'][0]['message']['content'].trim();
      } else {
        return explanation ?? 'Keep studying this topic!';
      }
    } catch (e) {
      return explanation ?? 'Keep studying this topic!';
    }
  }

  // Grade short answer question
  Future<Map<String, dynamic>> gradeShortAnswer({
    required String questionText,
    required String? correctAnswer,
    required String studentAnswer,
  }) async {
    try {
      final prompt = '''
Grade this short answer question:

Question: $questionText
Expected Answer: ${correctAnswer ?? 'N/A'}
Student Answer: $studentAnswer

Provide:
1. A score (0-100)
2. Brief feedback

Format as JSON:
{
  "score": 85,
  "feedback": "Your answer demonstrates good understanding but could be more specific about..."
}
''';

      final response = await http.post(
        Uri.parse(_openAIApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert educator grading short answer questions.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.5,
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final content = responseData['choices'][0]['message']['content'];

        // Parse JSON from response
        String jsonContent = content;
        if (content.contains('```json')) {
          jsonContent = content.split('```json')[1].split('```')[0].trim();
        } else if (content.contains('```')) {
          jsonContent = content.split('```')[1].split('```')[0].trim();
        }

        final gradeData = json.decode(jsonContent);
        return {
          'score': gradeData['score'] ?? 0,
          'feedback': gradeData['feedback'] ?? 'No feedback available',
        };
      } else {
        return {
          'score': 50,
          'feedback': 'Automated grading unavailable. Answer received.',
        };
      }
    } catch (e) {
      return {
        'score': 50,
        'feedback': 'Automated grading unavailable. Answer received.',
      };
    }
  }
}
