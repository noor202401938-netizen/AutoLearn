// lib/model/quiz_model.dart

class QuizModel {
  final String quizId;
  final String courseId;
  final String moduleId;
  final String lessonId;
  final String title;
  final String description;
  final List<QuestionModel> questions;
  final int timeLimit; // in minutes, 0 means no limit
  final int passingScore; // percentage (0-100)
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  QuizModel({
    required this.quizId,
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    required this.title,
    this.description = '',
    this.questions = const [],
    this.timeLimit = 0,
    this.passingScore = 70,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'courseId': courseId,
      'moduleId': moduleId,
      'lessonId': lessonId,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'timeLimit': timeLimit,
      'passingScore': passingScore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt != null ? updatedAt!.toIso8601String() : null,
      'createdBy': createdBy,
    };
  }

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      quizId: map['quizId'] ?? '',
      courseId: map['courseId'] ?? '',
      moduleId: map['moduleId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      questions: map['questions'] != null
          ? (map['questions'] as List)
              .map((item) => QuestionModel.fromMap(item))
              .toList()
          : [],
      timeLimit: map['timeLimit'] ?? 0,
      passingScore: map['passingScore'] ?? 70,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      createdBy: map['createdBy'],
    );
  }
}

class QuestionModel {
  final String questionId;
  final String questionText;
  final QuestionType type; // multiple_choice, true_false, short_answer
  final List<OptionModel> options; // For multiple choice
  final String? correctAnswer; // For short answer or true/false
  final int correctOptionIndex; // For multiple choice
  final String? explanation; // Explanation shown after answering
  final int points; // Points for this question

  QuestionModel({
    required this.questionId,
    required this.questionText,
    required this.type,
    this.options = const [],
    this.correctAnswer,
    this.correctOptionIndex = -1,
    this.explanation,
    this.points = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'type': type.toString().split('.').last,
      'options': options.map((o) => o.toMap()).toList(),
      'correctAnswer': correctAnswer,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'points': points,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      questionId: map['questionId'] ?? '',
      questionText: map['questionText'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: map['options'] != null
          ? (map['options'] as List)
              .map((item) => OptionModel.fromMap(item))
              .toList()
          : [],
      correctAnswer: map['correctAnswer'],
      correctOptionIndex: map['correctOptionIndex'] ?? -1,
      explanation: map['explanation'],
      points: map['points'] ?? 1,
    );
  }
}

enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
}

class OptionModel {
  final String optionId;
  final String text;

  OptionModel({
    required this.optionId,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'optionId': optionId,
      'text': text,
    };
  }

  factory OptionModel.fromMap(Map<String, dynamic> map) {
    return OptionModel(
      optionId: map['optionId'] ?? '',
      text: map['text'] ?? '',
    );
  }
}

// Quiz Submission/Result Model
class QuizSubmissionModel {
  final String submissionId;
  final String userId;
  final String quizId;
  final String courseId;
  final String moduleId;
  final String lessonId;
  final Map<String, dynamic> answers; // questionId -> answer
  final int score; // percentage
  final int totalPoints;
  final int earnedPoints;
  final bool passed;
  final DateTime submittedAt;
  final int? timeSpent; // in seconds

  QuizSubmissionModel({
    required this.submissionId,
    required this.userId,
    required this.quizId,
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    required this.answers,
    required this.score,
    required this.totalPoints,
    required this.earnedPoints,
    required this.passed,
    required this.submittedAt,
    this.timeSpent,
  });

  Map<String, dynamic> toMap() {
    return {
      'submissionId': submissionId,
      'userId': userId,
      'quizId': quizId,
      'courseId': courseId,
      'moduleId': moduleId,
      'lessonId': lessonId,
      'answers': answers,
      'score': score,
      'totalPoints': totalPoints,
      'earnedPoints': earnedPoints,
      'passed': passed,
      'submittedAt': submittedAt.toIso8601String(),
      'timeSpent': timeSpent,
    };
  }

  factory QuizSubmissionModel.fromMap(Map<String, dynamic> map) {
    return QuizSubmissionModel(
      submissionId: map['submissionId'] ?? '',
      userId: map['userId'] ?? '',
      quizId: map['quizId'] ?? '',
      courseId: map['courseId'] ?? '',
      moduleId: map['moduleId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      answers: Map<String, dynamic>.from(map['answers'] ?? {}),
      score: map['score'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      earnedPoints: map['earnedPoints'] ?? 0,
      passed: map['passed'] ?? false,
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      timeSpent: map['timeSpent'],
    );
  }
}

// Assignment Model
class AssignmentModel {
  final String assignmentId;
  final String courseId;
  final String moduleId;
  final String lessonId;
  final String title;
  final String description;
  final String instructions;
  final DateTime dueDate;
  final int maxPoints;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  AssignmentModel({
    required this.assignmentId,
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    required this.title,
    this.description = '',
    this.instructions = '',
    required this.dueDate,
    this.maxPoints = 100,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'courseId': courseId,
      'moduleId': moduleId,
      'lessonId': lessonId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'dueDate': dueDate.toIso8601String(),
      'maxPoints': maxPoints,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt != null ? updatedAt!.toIso8601String() : null,
      'createdBy': createdBy,
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      assignmentId: map['assignmentId'] ?? '',
      courseId: map['courseId'] ?? '',
      moduleId: map['moduleId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructions: map['instructions'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      maxPoints: map['maxPoints'] ?? 100,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      createdBy: map['createdBy'],
    );
  }
}

// Assignment Submission Model
class AssignmentSubmissionModel {
  final String submissionId;
  final String userId;
  final String assignmentId;
  final String courseId;
  final String moduleId;
  final String lessonId;
  final String content; // Student's submission text
  final String? feedback; // AI or instructor feedback
  final int? score; // Points earned
  final bool isGraded;
  final DateTime submittedAt;
  final DateTime? gradedAt;

  AssignmentSubmissionModel({
    required this.submissionId,
    required this.userId,
    required this.assignmentId,
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    required this.content,
    this.feedback,
    this.score,
    this.isGraded = false,
    required this.submittedAt,
    this.gradedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'submissionId': submissionId,
      'userId': userId,
      'assignmentId': assignmentId,
      'courseId': courseId,
      'moduleId': moduleId,
      'lessonId': lessonId,
      'content': content,
      'feedback': feedback,
      'score': score,
      'isGraded': isGraded,
      'submittedAt': submittedAt.toIso8601String(),
      'gradedAt': gradedAt != null ? gradedAt!.toIso8601String() : null,
    };
  }

  factory AssignmentSubmissionModel.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmissionModel(
      submissionId: map['submissionId'] ?? '',
      userId: map['userId'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      courseId: map['courseId'] ?? '',
      moduleId: map['moduleId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      content: map['content'] ?? '',
      feedback: map['feedback'],
      score: map['score'],
      isGraded: map['isGraded'] ?? false,
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      gradedAt: map['gradedAt'] != null
          ? (map['gradedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

