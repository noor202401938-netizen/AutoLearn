// lib/business_logic/ai_quiz_engine.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/quiz_model.dart';
import '../repository/quiz_repository.dart';

class AIQuizEngine {
  final QuizRepository _quizRepository = QuizRepository();

  // OpenAI API Configuration
  static const String _openAIApiKey =
      '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';
  static const String _openAIApiUrl =
      'https://api.openai.com/v1/chat/completions';

  // Generate quiz using AI
  Future<QuizModel> generateQuiz({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String lessonTitle,
    String? topic,
    int numberOfQuestions = 5,
    QuestionType questionType = QuestionType.multipleChoice,
  }) async {
    try {
      final quizId = 'quiz_${DateTime.now().millisecondsSinceEpoch}';

      // Build prompt for AI
      final prompt = _buildQuizPrompt(
        lessonTitle: lessonTitle,
        topic: topic,
        numberOfQuestions: numberOfQuestions,
        questionType: questionType,
      );

      // Call OpenAI API
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
                  'You are an expert educator. Generate educational quizzes in JSON format.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final content = responseData['choices'][0]['message']['content'];

        // Parse AI response
        final questions = _parseQuizResponse(content, questionType);

        // Create quiz model
        final quiz = QuizModel(
          quizId: quizId,
          courseId: courseId,
          moduleId: moduleId,
          lessonId: lessonId,
          title: 'Quiz: $lessonTitle',
          description: 'AI-generated quiz for $lessonTitle',
          questions: questions,
          timeLimit: numberOfQuestions * 2, // 2 minutes per question
          passingScore: 70,
          createdAt: DateTime.now(),
        );

        // Save quiz
        await _quizRepository.saveQuiz(quiz);

        return quiz;
      } else {
        throw Exception('Failed to generate quiz: ${response.statusCode}');
      }
    } catch (e) {
      // Return a default quiz if AI generation fails
      return _createDefaultQuiz(
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
        lessonTitle: lessonTitle,
      );
    }
  }

  String _buildQuizPrompt({
    required String lessonTitle,
    String? topic,
    required int numberOfQuestions,
    required QuestionType questionType,
  }) {
    final typeStr = questionType == QuestionType.multipleChoice
        ? 'multiple choice'
        : questionType == QuestionType.trueFalse
            ? 'true/false'
            : 'short answer';

    return '''
Generate a quiz about "$lessonTitle"${topic != null ? ' focusing on $topic' : ''}.

Requirements:
- Generate $numberOfQuestions $typeStr questions
- Questions should be educational and test understanding
- For multiple choice: provide 4 options with one correct answer
- Include explanations for each answer
- Format as JSON with this structure:
{
  "questions": [
    {
      "questionText": "Question text here",
      "type": "$typeStr",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctOptionIndex": 0,
      "explanation": "Explanation of the correct answer"
    }
  ]
}
''';
  }

  List<QuestionModel> _parseQuizResponse(String content, QuestionType type) {
    try {
      // Extract JSON from response
      String jsonContent = content;
      if (content.contains('```json')) {
        jsonContent = content.split('```json')[1].split('```')[0].trim();
      } else if (content.contains('```')) {
        jsonContent = content.split('```')[1].split('```')[0].trim();
      }

      final data = json.decode(jsonContent);
      final questionsList = data['questions'] as List;

      return questionsList.asMap().entries.map((entry) {
        final index = entry.key;
        final q = entry.value as Map<String, dynamic>;

        final options = <OptionModel>[];
        if (q['options'] != null) {
          options.addAll((q['options'] as List).asMap().entries.map((opt) {
            return OptionModel(
              optionId: 'opt_${index}_${opt.key}',
              text: opt.value.toString(),
            );
          }));
        }

        return QuestionModel(
          questionId: 'q_$index',
          questionText: q['questionText'] ?? 'Question ${index + 1}',
          type: type,
          options: options,
          correctOptionIndex: q['correctOptionIndex'] ?? 0,
          correctAnswer: q['correctAnswer'],
          explanation: q['explanation'],
          points: 1,
        );
      }).toList();
    } catch (e) {
      // Return default questions if parsing fails
      return _createDefaultQuestions();
    }
  }

  QuizModel _createDefaultQuiz({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String lessonTitle,
  }) {
    return QuizModel(
      quizId: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      moduleId: moduleId,
      lessonId: lessonId,
      title: 'Quiz: $lessonTitle',
      description: 'Quiz for $lessonTitle',
      questions: _createDefaultQuestions(),
      timeLimit: 10,
      passingScore: 70,
      createdAt: DateTime.now(),
    );
  }

  List<QuestionModel> _createDefaultQuestions() {
    return [
      QuestionModel(
        questionId: 'q_0',
        questionText: 'What is the basic definition of your subject?',
        type: QuestionType.multipleChoice,
        options: [
          OptionModel(optionId: 'opt_0_0', text: 'The study of money'),
          OptionModel(
              optionId: 'opt_0_1',
              text: 'The study of how society manages scarce resources'),
          OptionModel(optionId: 'opt_0_2', text: 'The study of business'),
          OptionModel(optionId: 'opt_0_3', text: 'The study of markets'),
        ],
        correctOptionIndex: 1,
        explanation:
            'It is the study of how society manages scarce resources and makes decisions about production, distribution, and consumption.',
        points: 1,
      ),
      QuestionModel(
        questionId: 'q_1',
        questionText: 'Supply and demand determine prices in a market economy.',
        type: QuestionType.trueFalse,
        options: [
          OptionModel(optionId: 'opt_1_0', text: 'True'),
          OptionModel(optionId: 'opt_1_1', text: 'False'),
        ],
        correctOptionIndex: 0,
        explanation:
            'True. In a market economy, prices are determined by the interaction of supply and demand.',
        points: 1,
      ),
    ];
  }

  // Grade quiz submission
  QuizSubmissionModel gradeQuiz({
    required String userId,
    required QuizModel quiz,
    required Map<String, dynamic> answers,
    int? timeSpent,
  }) {
    int totalPoints = 0;
    int earnedPoints = 0;

    for (var question in quiz.questions) {
      totalPoints += question.points;
      final userAnswer = answers[question.questionId];

      bool isCorrect = false;
      if (question.type == QuestionType.multipleChoice ||
          question.type == QuestionType.trueFalse) {
        isCorrect = userAnswer == question.correctOptionIndex;
      } else if (question.type == QuestionType.shortAnswer) {
        // For short answer, we'll use AI feedback engine for grading
        // For now, mark as correct if answer is provided
        isCorrect =
            userAnswer != null && userAnswer.toString().trim().isNotEmpty;
      }

      if (isCorrect) {
        earnedPoints += question.points;
      }
    }

    final score =
        totalPoints > 0 ? ((earnedPoints / totalPoints) * 100).round() : 0;
    final passed = score >= quiz.passingScore;

    return QuizSubmissionModel(
      submissionId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      quizId: quiz.quizId,
      courseId: quiz.courseId,
      moduleId: quiz.moduleId,
      lessonId: quiz.lessonId,
      answers: answers,
      score: score,
      totalPoints: totalPoints,
      earnedPoints: earnedPoints,
      passed: passed,
      submittedAt: DateTime.now(),
      timeSpent: timeSpent,
    );
  }

  // Get or generate quiz for a lesson
  Future<QuizModel> getOrGenerateQuiz({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String lessonTitle,
  }) async {
    // Try to get existing quiz
    final existingQuiz = await _quizRepository.getQuizByLessonId(lessonId);
    if (existingQuiz != null) {
      return existingQuiz;
    }

    // Generate new quiz
    return await generateQuiz(
      courseId: courseId,
      moduleId: moduleId,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      numberOfQuestions: 5,
    );
  }
}
