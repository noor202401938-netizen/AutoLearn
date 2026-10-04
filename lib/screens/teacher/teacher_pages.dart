// Teacher sections: overview, marking, student progress and course announcements.
// Everything is read from /api/teacher, which only ever returns the teacher's own courses.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/api_client.dart';
import '../../widgets/notebook/notebook.dart';
import '../admin/admin_pages.dart';

// ── Overview ─────────────────────────────────────────────────────────────────

class TeacherOverviewPage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const TeacherOverviewPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) => PageLoader(
        endpoint: '/teacher/overview',
        builder: (context, d, _) {
          final theme = Theme.of(context);
          final avgQuiz = d['averageQuizScore'] as num?;
          final courses = (d['courses'] as List).cast<Map<String, dynamic>>();
          final toMark = d['assignmentsToMark'] as int;
          final unanswered = d['unansweredQuestions'] as int;
          return ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              children: [
                pageTitle(context, 'Overview',
                    DateFormat('EEEE, d MMMM').format(DateTime.now())),
                const SizedBox(height: 24),
                NoteCard(
                  child: Wrap(spacing: 24, runSpacing: 20, children: [
                    figureTile(
                        context,
                        '${d['publishedCourses']}/${d['totalCourses']}',
                        'courses published'),
                    figureTile(
                        context, '${d['totalEnrollments']}', 'enrolments'),
                    figureTile(context, '${d['activeLearners7d']}',
                        'active this week'),
                    figureTile(
                        context,
                        '${((d['completionRate'] as num) * 100).round()}%',
                        'complete their course'),
                    figureTile(
                        context,
                        avgQuiz == null ? '—' : '${avgQuiz.round()}%',
                        'average quiz score'),
                  ]),
                ),
                if (toMark > 0 || unanswered > 0) ...[
                  const SizedBox(height: 28),
                  const NoteHeading('Needs you'),
                  const SizedBox(height: 10),
                  if (toMark > 0)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.assignment_late_outlined),
                      title: Text(
                          '$toMark ${toMark == 1 ? 'submission is' : 'submissions are'} waiting for a mark'),
                      trailing: TextButton(
                          onPressed: () => onNavigate(2),
                          child: const Text('Mark')),
                    ),
                  if (unanswered > 0)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.help_outline),
                      title: Text(
                          '$unanswered course ${unanswered == 1 ? 'question has' : 'questions have'} no replies yet'),
                    ),
                ],
                const SizedBox(height: 28),
                NoteHeading('Your courses',
                    trailing: TextButton(
                        onPressed: () => onNavigate(1),
                        child: const Text('Manage'))),
                const SizedBox(height: 8),
                if (courses.isEmpty)
                  NotebookEmpty(
                      title: 'No courses yet',
                      note: 'create your first one',
                      actionLabel: 'New course',
                      onAction: () => onNavigate(1))
                else
                  for (final c in courses)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c['title'] as String),
                      subtitle: Text(
                          c['isPublished'] == true ? 'published' : 'draft'),
                      trailing: Text(
                        '${c['enrollmentCount']} enrolled${(c['ratingCount'] as int) > 0 ? '  ·  rated ${(c['rating'] as num).toStringAsFixed(1)}' : ''}',
                        style: NotebookColors.figures(
                            size: 13, color: theme.colorScheme.onSurface),
                      ),
                    ),
              ]);
        },
      );
}

// ── Marking ──────────────────────────────────────────────────────────────────

class TeacherMarkingPage extends StatefulWidget {
  const TeacherMarkingPage({super.key});

  @override
  State<TeacherMarkingPage> createState() => _TeacherMarkingPageState();
}

class _TeacherMarkingPageState extends State<TeacherMarkingPage> {
  String _status = 'pending';

  Future<void> _mark(
      Map<String, dynamic> s, Future<void> Function() reload) async {
    final result = await showDialog<({int score, String feedback})>(
        context: context, builder: (_) => _MarkDialog(submission: s));
    if (result == null) return;
    try {
      await ApiClient.instance.json(
          'PUT', '/teacher/submissions/${s['id']}/grade',
          body: {'score': result.score, 'feedback': result.feedback});
      await reload();
      if (mounted)
        showToast(context, 'Marked — ${s['studentName']} has been notified');
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => PageLoader(
        key: ValueKey(_status),
        endpoint: '/teacher/submissions?status=$_status',
        builder: (context, data, reload) {
          final theme = Theme.of(context);
          final rows = (data as List).cast<Map<String, dynamic>>();
          return ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              children: [
                pageTitle(
                    context, 'Marking', 'assignment work from your students'),
                const SizedBox(height: 16),
                Wrap(spacing: 8, children: [
                  for (final (value, label) in const [
                    ('pending', 'To mark'),
                    ('graded', 'Marked')
                  ])
                    ChoiceChip(
                        label: Text(label),
                        selected: _status == value,
                        onSelected: (_) => setState(() => _status = value)),
                ]),
                const SizedBox(height: 16),
                if (rows.isEmpty)
                  NotebookEmpty(
                    title: _status == 'pending'
                        ? 'Nothing to mark'
                        : 'Nothing marked yet',
                    note: _status == 'pending'
                        ? 'new submissions will appear here'
                        : 'marked work will be listed here',
                  ),
                for (final s in rows) ...[
                  NoteCard(
                    onTap: () => _mark(s, reload),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(s['assignmentTitle'] as String,
                                    style: theme.textTheme.titleMedium)),
                            if (s['isGraded'] == true)
                              Text('${s['score']}/${s['maxPoints']}',
                                  style: NotebookColors.figures(
                                      size: 15,
                                      weight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface)),
                          ]),
                          Text(
                            '${s['studentName']} · ${s['courseTitle']} · ${timeAgo(DateTime.parse(s['submittedAt'] as String))}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                              (s['content'] as String).isEmpty
                                  ? '(file attached)'
                                  : s['content'] as String,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                                onPressed: () => _mark(s, reload),
                                child: Text(s['isGraded'] == true
                                    ? 'Change mark'
                                    : 'Mark')),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 12),
                ],
              ]);
        },
      );
}

class _MarkDialog extends StatefulWidget {
  final Map<String, dynamic> submission;
  const _MarkDialog({required this.submission});

  @override
  State<_MarkDialog> createState() => _MarkDialogState();
}

class _MarkDialogState extends State<_MarkDialog> {
  late final _score =
      TextEditingController(text: widget.submission['score']?.toString() ?? '');
  late final _feedback = TextEditingController(
      text: widget.submission['feedback'] as String? ?? '');
  String? _error;

  @override
  void dispose() {
    _score.dispose();
    _feedback.dispose();
    super.dispose();
  }

  void _save() {
    final max = widget.submission['maxPoints'] as int;
    final score = int.tryParse(_score.text.trim());
    if (score == null || score < 0 || score > max) {
      setState(() => _error = 'Enter a whole number from 0 to $max');
      return;
    }
    Navigator.pop(context, (score: score, feedback: _feedback.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.submission;
    return AlertDialog(
      title: Text(s['assignmentTitle'] as String),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${s['studentName']} wrote:',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 6),
                SelectableText((s['content'] as String).isEmpty
                    ? '(file attached)'
                    : s['content'] as String),
                if (s['fileUrl'] != null) ...[
                  const SizedBox(height: 6),
                  SelectableText('File: ${s['fileUrl']}')
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _score,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Mark out of ${s['maxPoints']}',
                      errorText: _error),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: _feedback,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                        labelText: 'Feedback for the student')),
              ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save mark')),
      ],
    );
  }
}

// ── Per-course helper ────────────────────────────────────────────────────────

/// Lets the teacher pick one of their own courses, then builds [builder] for it.
class CoursePicker extends StatefulWidget {
  final String title;
  final String note;
  final Widget Function(
      BuildContext context, String courseId, String courseTitle) builder;
  const CoursePicker(
      {required this.title, required this.note, required this.builder});

  @override
  State<CoursePicker> createState() => CoursePickerState();
}

class CoursePickerState extends State<CoursePicker> {
  String? _selected;

  @override
  Widget build(BuildContext context) => PageLoader(
        endpoint: '/courses?mine=true',
        builder: (context, data, _) {
          final courses = (data as List).cast<Map<String, dynamic>>();
          if (courses.isEmpty) {
            return ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                children: [
                  pageTitle(context, widget.title, widget.note),
                  const SizedBox(height: 24),
                  const NotebookEmpty(
                      title: 'No courses yet', note: 'create a course first'),
                ]);
          }
          final current = courses.firstWhere((c) => c['courseId'] == _selected,
              orElse: () => courses.first);
          return ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              children: [
                pageTitle(context, widget.title, widget.note),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: current['courseId'] as String,
                  decoration: const InputDecoration(labelText: 'Course'),
                  items: [
                    for (final c in courses)
                      DropdownMenuItem(
                          value: c['courseId'] as String,
                          child: Text(c['title'] as String))
                  ],
                  onChanged: (v) => setState(() => _selected = v),
                ),
                const SizedBox(height: 20),
                widget.builder(context, current['courseId'] as String,
                    current['title'] as String),
              ]);
        },
      );
}

// ── Students ─────────────────────────────────────────────────────────────────

class TeacherStudentsPage extends StatelessWidget {
  const TeacherStudentsPage({super.key});

  @override
  Widget build(BuildContext context) => CoursePicker(
        title: 'Students',
        note: 'who is keeping up, and who has gone quiet',
        builder: (context, courseId, _) =>
            _Roster(key: ValueKey(courseId), courseId: courseId),
      );
}

class _Roster extends StatefulWidget {
  final String courseId;
  const _Roster({super.key, required this.courseId});

  @override
  State<_Roster> createState() => _RosterState();
}

class _RosterState extends State<_Roster> {
  List<Map<String, dynamic>>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance
          .json('GET', '/teacher/courses/${widget.courseId}/students');
      if (mounted)
        setState(() => _rows = (d as List).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_error != null) return NotebookError(message: _error!, onRetry: _load);
    final rows = _rows;
    if (rows == null)
      return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()));
    if (rows.isEmpty)
      return const NotebookEmpty(
          title: 'No students yet', note: 'enrolled students will appear here');
    return Column(children: [
      for (final r in rows)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(r['name'] as String,
                        style: theme.textTheme.titleMedium)),
                if (r['status'] == 'completed')
                  Highlight('finished',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurface)),
              ]),
              Text(r['email'] as String, style: theme.textTheme.bodySmall),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (r['lessonCount'] as int) == 0
                    ? 0
                    : (r['lessonsDone'] as int) / (r['lessonCount'] as int),
                minHeight: 6,
              ),
              const SizedBox(height: 6),
              Text(
                '${r['lessonsDone']}/${r['lessonCount']} lessons · '
                '${r['averageQuizScore'] == null ? 'no quizzes yet' : 'quiz average ${r['averageQuizScore']}%'} · '
                '${r['lastActiveAt'] == null ? 'not started' : 'last active ${timeAgo(DateTime.parse(r['lastActiveAt'] as String))}'}',
                style: theme.textTheme.bodySmall,
              ),
            ]),
          ),
        ),
    ]);
  }
}

// ── Announcements ────────────────────────────────────────────────────────────

class TeacherAnnouncementsPage extends StatelessWidget {
  const TeacherAnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) => CoursePicker(
        title: 'Announcements',
        note: 'goes to the students enrolled in one course',
        builder: (context, courseId, courseTitle) => _AnnounceForm(
            key: ValueKey(courseId),
            courseId: courseId,
            courseTitle: courseTitle),
      );
}

class _AnnounceForm extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  const _AnnounceForm(
      {super.key, required this.courseId, required this.courseTitle});

  @override
  State<_AnnounceForm> createState() => _AnnounceFormState();
}

class _AnnounceFormState extends State<_AnnounceForm> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final r = await ApiClient.instance.json(
          'POST', '/teacher/courses/${widget.courseId}/announce',
          body: {'title': _title.text.trim(), 'message': _message.text.trim()});
      _title.clear();
      _message.clear();
      if (mounted) showToast(context, r['message'] as String? ?? 'Sent');
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) => NoteCard(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(
              controller: _message,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Message')),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.send, size: 18),
              label: Text('Send to ${widget.courseTitle}'),
            ),
          ),
        ]),
      );
}
