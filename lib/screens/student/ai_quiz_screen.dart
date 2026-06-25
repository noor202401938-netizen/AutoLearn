// lib/screens/student/ai_quiz_screen.dart
import 'package:flutter/material.dart';
import '../../business_logic/ai_quiz_engine.dart';
import '../../business_logic/ai_feedback_engine.dart';
import '../../business_logic/certificate_manager.dart';
import '../../repository/quiz_repository.dart';
import '../../repository/auth_repository.dart';
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
      final user = await AuthRepository().getCurrentUser();
      final uid = user?['uid'] as String?;
      if (uid != null) {
        final existingSubmission = await _quizRepository.getUserQuizSubmission(
          userId: uid,
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

    final user = await AuthRepository().getCurrentUser();
    final uid = user?['uid'] as String?;
    if (uid == null || _quiz == null) return;

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final timeSpent = _startTime != null
          ? DateTime.now().difference(_startTime!).inSeconds
          : null;

      // Grade the quiz
      final submission = _quizEngine.gradeQuiz(
        userId: uid,
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 1,
        shadowColor: Colors.black12,
        scrolledUnderElevation: 1,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF474554)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.courseTitle,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Unit: ${widget.moduleTitle}'.toUpperCase(),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_quiz != null && _quiz!.timeLimit > 0 && !_showResults)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEE9FC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: Color(0xFF4231C0)),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(_timeRemaining),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
            : _quiz == null
                ? const Center(child: Text('Quiz not found', style: TextStyle(color: Colors.black)))
                : _showResults
                    ? _buildResultsView()
                    : _buildQuizView(),
      ),
      bottomNavigationBar: !_isLoading && _quiz != null && !_showResults
          ? _buildBottomNavigation()
          : null,
    );
  }

  Widget _buildQuizView() {
    final theme = Theme.of(context);
    if (_quiz!.questions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    final question = _quiz!.questions[_currentQuestionIndex];
    final progressPercent = (_currentQuestionIndex + 1) / _quiz!.questions.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Question ${_currentQuestionIndex + 1} ',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: 'of ${_quiz!.questions.length}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E3F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
      final theme = Theme.of(context);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        height: 8,
                        width: constraints.maxWidth * progressPercent,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00724E), Color(0xFF4EDEA3)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.questionText,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                if (question.type == QuestionType.multipleChoice ||
                    question.type == QuestionType.trueFalse)
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _answers[question.questionId] == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _answers[question.questionId] = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFeff4ff) : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withOpacity(0.5),
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: isSelected ? 1.0 : 0.0,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4231C0),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.text,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                if (question.type == QuestionType.shortAnswer)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        _answers[question.questionId] = value;
                      },
                      maxLines: 5,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Type your answer here...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(24),
                      ),
                    ),
                  ),
                ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    final theme = Theme.of(context);
    final isLastQuestion = _currentQuestionIndex == _quiz!.questions.length - 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _currentQuestionIndex > 0
                    ? () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      }
                    : () { Navigator.pop(context); },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF4231C0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Back',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4231C0), Color(0xFF6B38D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastQuestion ? 'Submit Quiz' : 'Next',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(width: 8),
                            Icon(isLastQuestion ? Icons.check : Icons.arrow_forward, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final theme = Theme.of(context);
    if (_submission == null) return const SizedBox();

    final score = _submission!.score;
    final passed = _submission!.passed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: (passed ? Colors.green : Colors.orange).withOpacity(0.2),
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
                  color: passed ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  '$score%',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  passed ? 'Passed!' : 'Not Passed',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_submission!.earnedPoints} / ${_submission!.totalPoints} points',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          ..._quiz!.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final userAnswer = _answers[question.questionId];
            final isCorrect = question.type == QuestionType.multipleChoice ||
                    question.type == QuestionType.trueFalse
                ? userAnswer == question.correctOptionIndex
                : true;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                          style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.questionText,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (question.explanation != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                        ),
                        child: Text(
                          question.explanation!,
                          style: theme.textTheme.bodyMedium),
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4231C0), Color(0xFF6B38D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Done', 
                style: theme.textTheme.bodyMedium
              ),
            ),
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
