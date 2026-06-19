// lib/screens/student/ai_quiz_screen.dart
import 'package:flutter/material.dart';
import '../../business_logic/ai_quiz_engine.dart';
import '../../business_logic/ai_feedback_engine.dart';
import '../../business_logic/certificate_manager.dart';
import '../../repository/quiz_repository.dart';
import '../../model/quiz_model.dart';
import 'certificate_screen.dart';
import 'dart:async';

class AIQuizScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String moduleId;
  final String moduleTitle;
  final String lessonId;
  final String lessonTitle;

  const AIQuizScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.moduleId,
    required this.moduleTitle,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<AIQuizScreen> createState() => _AIQuizScreenState();
}

class _AIQuizScreenState extends State<AIQuizScreen> {
  final AIQuizEngine _quizEngine = AIQuizEngine();
  final AIFeedbackEngine _feedbackEngine = AIFeedbackEngine();
  final QuizRepository _quizRepository = QuizRepository();
  final CertificateManager _certificateManager = CertificateManager();
  bool _certificateShown = false;

  QuizModel? _quiz;
  Map<String, dynamic> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showResults = false;
  QuizSubmissionModel? _submission;
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _timeRemaining = 0; // in seconds
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    try {
      _quiz = await _quizEngine.getOrGenerateQuiz(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        lessonId: widget.lessonId,
        lessonTitle: widget.lessonTitle,
      );

      // Check for existing submission
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user != null) {
        final existingSubmission = await _quizRepository.getUserQuizSubmission(
          userId: user.uid,
          quizId: _quiz!.quizId,
        );
        if (existingSubmission != null) {
          setState(() {
            _submission = existingSubmission;
            _showResults = true;
            _answers = existingSubmission.answers;
          });
        }
      }

      // Initialize timer if time limit exists
      if (_quiz!.timeLimit > 0) {
        _timeRemaining = _quiz!.timeLimit * 60;
        _startTime = DateTime.now();
        _startTimer();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quiz: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _timer?.cancel();
        _submitQuiz(autoSubmit: true);
      }
    });
  }

  Future<void> _submitQuiz({bool autoSubmit = false}) async {
    if (_isSubmitting) return;

    final user = null /* was FirebaseAuth.instance.currentUser */;
    if (user == null || _quiz == null) return;

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final timeSpent = _startTime != null
          ? DateTime.now().difference(_startTime!).inSeconds
          : null;

      // Grade the quiz
      final submission = _quizEngine.gradeQuiz(
        userId: user.uid,
        quiz: _quiz!,
        answers: _answers,
        timeSpent: timeSpent,
      );

      // Save submission
      await _quizRepository.submitQuiz(submission);

      setState(() {
        _submission = submission;
        _showResults = true;
        _isSubmitting = false;
      });

      // Generate and show certificate
      if (!_certificateShown) {
        _certificateShown = true;
        _showCertificate();
      }

      if (autoSubmit && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time\'s up! Quiz submitted automatically.')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting quiz: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz?.title ?? 'Quiz'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_quiz != null && _quiz!.timeLimit > 0 && !_showResults)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  _formatTime(_timeRemaining),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quiz == null
              ? const Center(child: Text('Quiz not found'))
              : _showResults
                  ? _buildResultsView()
                  : _buildQuizView(),
    );
  }

  Widget _buildQuizView() {
    if (_quiz!.questions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    final question = _quiz!.questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _quiz!.questions.length - 1;

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _quiz!.questions.length,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),

        // Question counter
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_quiz!.questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_quiz!.questions.length - _currentQuestionIndex - 1} remaining',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Answer options
                if (question.type == QuestionType.multipleChoice ||
                    question.type == QuestionType.trueFalse)
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _answers[question.questionId] == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _answers[question.questionId] = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                if (question.type == QuestionType.shortAnswer)
                  TextField(
                    onChanged: (value) {
                      _answers[question.questionId] = value;
                    },
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Type your answer here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (isLastQuestion) {
                              _submitQuiz();
                            } else {
                              setState(() {
                                _currentQuestionIndex++;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                            ),
                          )
                        : Text(isLastQuestion ? 'Submit Quiz' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    if (_submission == null) return const SizedBox();

    final score = _submission!.score;
    final passed = _submission!.passed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Score card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: passed
                    ? [Colors.green[400]!, Colors.green[600]!]
                    : [Colors.orange[400]!, Colors.orange[600]!],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (passed ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  passed ? Icons.check_circle : Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  '$score%',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  passed ? 'Passed!' : 'Not Passed',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_submission!.earnedPoints} / ${_submission!.totalPoints} points',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Question review
          ..._quiz!.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final userAnswer = _answers[question.questionId];
            final isCorrect = question.type == QuestionType.multipleChoice ||
                    question.type == QuestionType.trueFalse
                ? userAnswer == question.correctOptionIndex
                : true; // Short answer grading handled separately

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Question ${index + 1}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.questionText,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    if (question.explanation != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          question.explanation!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Action buttons
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _showCertificate() async {
    try {
      final certificate = await _certificateManager.generateCertificate(
        courseId: widget.courseId,
        courseName: widget.courseTitle,
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
      );

      if (certificate != null && mounted) {
        // Show certificate after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CertificateScreen(certificate: certificate),
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error showing certificate: $e');
    }
  }
}

