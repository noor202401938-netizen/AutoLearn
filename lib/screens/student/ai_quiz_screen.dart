import 'dart:async';
import 'package:flutter/material.dart';
import '../../backend/api_client.dart';
import '../../model/certificate_model.dart';
import '../../model/quiz_model.dart';
import '../../repository/certificate_repository.dart';
import '../../repository/quiz_repository.dart';
import '../../widgets/notebook/notebook.dart';
import 'certificate_screen.dart';

/// A quiz laid out like a worksheet: every question on one page, circle your
/// answer, hand it in, get it back marked in red pen.
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
  final _quizzes = QuizRepository();
  final _certificates = CertificateRepository();

  QuizModel? _quiz;
  QuizSubmissionModel? _result;
  CertificateModel? _certificate;
  final Map<String, dynamic> _answers = {};
  String? _error;
  bool _submitting = false;
  DateTime? _started;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final quiz = await _quizzes.getQuizForLesson(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        lessonId: widget.lessonId,
        lessonTitle: widget.lessonTitle,
      );
      final previous = await _quizzes.getQuizSubmission(quiz.quizId);
      if (!mounted) return;
      setState(() {
        _quiz = quiz;
        _result = previous;
      });
      if (previous == null) _start();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _start() {
    _answers.clear();
    _started = DateTime.now();
    _timer?.cancel();
    final limit = _quiz!.timeLimit * 60;
    setState(() {
      _result = null;
      _certificate = null;
      _secondsLeft = limit;
    });
    if (limit > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft <= 1) {
          t.cancel();
          _submit();
        } else {
          setState(() => _secondsLeft--);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting || _quiz == null) return;
    _timer?.cancel();
    setState(() => _submitting = true);
    try {
      final result = await _quizzes.submitQuiz(
        _quiz!.quizId,
        Map.of(_answers),
        timeSpent: _started == null ? null : DateTime.now().difference(_started!).inSeconds,
      );
      CertificateModel? cert;
      if (result.passed) {
        cert = await _certificates.issueIfEarned(courseId: widget.courseId, lessonId: widget.lessonId);
      }
      if (!mounted) return;
      setState(() {
        _result = result;
        _certificate = cert;
        _submitting = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_error != null) {
      body = NotebookError(message: _error!, onRetry: _load);
    } else if (_quiz == null) {
      body = const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          MarginNote('setting your questions…', tilt: 0),
        ]),
      );
    } else if (_result != null) {
      body = _results();
    } else {
      body = _worksheet();
    }
    return NotebookPage(title: widget.lessonTitle, body: body);
  }

  Widget _worksheet() {
    final theme = Theme.of(context);
    final quiz = _quiz!;
    final answered = quiz.questions.where((q) => _answers.containsKey(q.questionId)).length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 48), children: [
          Row(children: [
            Expanded(child: Text(quiz.title, style: theme.textTheme.headlineMedium)),
            if (quiz.timeLimit > 0)
              Text(
                '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                style: NotebookColors.figures(
                  size: 22,
                  weight: FontWeight.w600,
                  color: _secondsLeft < 60 ? theme.colorScheme.error : theme.colorScheme.onSurface,
                ),
              ),
          ]),
          if (quiz.description.isNotEmpty) Text(quiz.description, style: theme.textTheme.bodyMedium),
          MarginNote('${quiz.passingScore}% to pass', size: 19),
          const SizedBox(height: 24),
          for (final (i, q) in quiz.questions.indexed) ...[
            _QuestionBlock(
              number: i + 1,
              question: q,
              selected: _answers[q.questionId],
              onSelect: (v) => setState(() => _answers[q.questionId] = v),
            ),
            const SizedBox(height: 28),
          ],
          Row(children: [
            Text('$answered of ${quiz.questions.length} answered', style: theme.textTheme.bodyMedium),
            const Spacer(),
            ElevatedButton(
              onPressed: _submitting || answered == 0 ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Hand it in'),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _results() {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final r = _result!;
    final review = r.review.isNotEmpty ? r.review : _quiz!.questions;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 48), children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // The mark, written in red pen and circled.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: nb.annotation, width: 2),
                borderRadius: const BorderRadius.all(Radius.elliptical(60, 40)),
              ),
              child: Text('${r.earnedPoints}/${r.totalPoints}', style: nb.hand(size: 40)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${r.score}%', style: NotebookColors.figures(size: 28, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                MarginNote(
                  r.passed ? 'Passed — well done!' : 'Not yet — you need ${_quiz!.passingScore}%',
                  size: 21,
                  color: r.passed ? nb.correct : nb.annotation,
                ),
              ]),
            ),
          ]),
          if (_certificate != null) ...[
            const SizedBox(height: 20),
            NoteCard(
              color: nb.highlighter.withValues(alpha: 0.35),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CertificateScreen(certificate: _certificate!)),
              ),
              child: Row(children: [
                const Icon(Icons.workspace_premium_outlined, size: 32),
                const SizedBox(width: 14),
                Expanded(child: Text('You earned the certificate for ${widget.courseTitle}', style: theme.textTheme.titleMedium)),
                const Icon(Icons.arrow_forward),
              ]),
            ),
          ],
          const SizedBox(height: 28),
          const NoteHeading('Corrections'),
          const SizedBox(height: 16),
          for (final (i, q) in review.indexed) ...[
            _QuestionBlock(number: i + 1, question: q, selected: r.answers[q.questionId], marked: true),
            const SizedBox(height: 28),
          ],
          Row(children: [
            OutlinedButton.icon(onPressed: _start, icon: const Icon(Icons.refresh), label: const Text('Try again')),
            const Spacer(),
            ElevatedButton(onPressed: () => Navigator.pop(context, r.passed), child: const Text('Back to the course')),
          ]),
        ]),
      ),
    );
  }
}

/// One numbered question. In answer mode the chosen option is circled in ink;
/// in [marked] mode each option shows ✓/✗ and the explanation sits in the margin.
class _QuestionBlock extends StatelessWidget {
  final int number;
  final QuestionModel question;
  final dynamic selected;
  final ValueChanged<dynamic>? onSelect;
  final bool marked;

  const _QuestionBlock({required this.number, required this.question, this.selected, this.onSelect, this.marked = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final q = question;
    final letters = 'abcdefgh';

    final Widget answers;
    if (q.type == QuestionType.multipleChoice) {
      answers = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (j, o) in q.options.indexed)
          Builder(builder: (context) {
            final picked = selected != null && '$selected' == '$j';
            final correct = marked && j == q.correctOptionIndex;
            final wrong = marked && picked && !correct;
            return InkWell(
              onTap: onSelect == null ? null : () => onSelect!(j),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(children: [
                  Container(
                    width: 30,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: picked
                        ? BoxDecoration(
                            border: Border.all(color: marked ? (wrong ? nb.annotation : nb.correct) : theme.colorScheme.primary, width: 2),
                            borderRadius: const BorderRadius.all(Radius.elliptical(16, 13)),
                          )
                        : null,
                    child: Text('${letters[j % letters.length]})', style: theme.textTheme.titleSmall),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: correct
                        ? Highlight(o.text, style: theme.textTheme.bodyLarge)
                        : Text(o.text, style: theme.textTheme.bodyLarge),
                  ),
                  if (marked && (correct || wrong)) ...[
                    const SizedBox(width: 8),
                    Text(correct ? '✓' : '✗', style: nb.hand(size: 24, color: correct ? nb.correct : nb.annotation)),
                  ],
                ]),
              ),
            );
          }),
      ]);
    } else {
      answers = marked
          ? Text('Your answer: ${selected ?? '—'}   ·   Answer: ${q.correctAnswer ?? '—'}', style: theme.textTheme.bodyLarge)
          : TextFormField(
              initialValue: selected?.toString(),
              onChanged: onSelect,
              decoration: const InputDecoration(hintText: 'Your answer'),
            );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 32, child: Text('$number.', style: theme.textTheme.titleMedium)),
        Expanded(child: Text(q.questionText, style: theme.textTheme.titleMedium)),
      ]),
      const SizedBox(height: 8),
      Padding(padding: const EdgeInsets.only(left: 28), child: answers),
      if (marked && (q.explanation ?? '').isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 36, top: 6),
          child: MarginNote(q.explanation!, size: 18, tilt: 0),
        ),
    ]);
  }
}
