import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/api_client.dart';
import '../../repository/quiz_repository.dart';
import '../../widgets/notebook/notebook.dart';
import 'assignment_screen.dart';

/// Every assignment across the student's courses: to do, waiting to be
/// marked, and marked.
class AssignmentsHubScreen extends StatefulWidget {
  final bool embedded;
  const AssignmentsHubScreen({super.key, this.embedded = false});

  @override
  State<AssignmentsHubScreen> createState() => _AssignmentsHubScreenState();
}

class _AssignmentsHubScreenState extends State<AssignmentsHubScreen> {
  final _repo = QuizRepository();
  List<Map<String, dynamic>>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await _repo.myAssignments();
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _open(Map<String, dynamic> a) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentScreen(
          courseId: a['courseId'] as String,
          courseTitle: a['courseTitle'] as String? ?? '',
          moduleId: a['moduleId'] as String? ?? '',
          moduleTitle: a['moduleTitle'] as String? ?? '',
          lessonId: a['lessonId'] as String,
          lessonTitle: a['lessonTitle'] as String? ?? a['title'] as String,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_error != null) {
      content = NotebookError(message: _error!, onRetry: _load);
    } else if (_items == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = _list(_items!);
    }
    return widget.embedded ? content : NotebookPage(title: 'Assignments', body: content);
  }

  Widget _list(List<Map<String, dynamic>> items) {
    final theme = Theme.of(context);
    Map<String, dynamic>? sub(Map<String, dynamic> a) => a['submission'] as Map<String, dynamic>?;
    final todo = items.where((a) => sub(a) == null).toList();
    final waiting = items.where((a) => sub(a) != null && sub(a)!['isGraded'] != true).toList();
    final marked = items.where((a) => sub(a)?['isGraded'] == true).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
        Text('Assignments', style: theme.textTheme.displaySmall),
        MarginNote(todo.isEmpty ? 'nothing due — nice' : '${todo.length} to do'),
        const SizedBox(height: 24),
        if (items.isEmpty)
          const NotebookEmpty(
            title: 'No assignments yet',
            note: 'they appear here once your courses set them',
          ),
        if (todo.isNotEmpty) ..._section('To do', todo),
        if (waiting.isNotEmpty) ..._section('Waiting to be marked', waiting),
        if (marked.isNotEmpty) ..._section('Marked', marked),
      ]),
    );
  }

  List<Widget> _section(String title, List<Map<String, dynamic>> items) => [
        NoteHeading(title),
        const SizedBox(height: 14),
        for (final a in items) ...[_row(a), const SizedBox(height: 12)],
        const SizedBox(height: 24),
      ];

  Widget _row(Map<String, dynamic> a) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final due = DateTime.tryParse('${a['dueDate']}');
    final sub = a['submission'] as Map<String, dynamic>?;
    final overdue = sub == null && due != null && due.isBefore(DateTime.now());
    final score = sub?['score'];

    return NoteCard(
      onTap: () => _open(a),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((a['courseTitle'] as String? ?? '').toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(a['title'] as String? ?? '', style: theme.textTheme.titleMedium),
            if (due != null)
              Text(
                sub == null ? 'due ${DateFormat('EEE d MMM').format(due)}' : 'handed in ${timeAgo(DateTime.parse('${sub['submittedAt']}'))}',
                style: theme.textTheme.bodySmall?.copyWith(color: overdue ? theme.colorScheme.error : null),
              ),
          ]),
        ),
        if (score != null)
          Text('$score/${a['maxPoints']}', style: nb.hand(size: 26))
        else if (overdue)
          MarginNote('overdue!', size: 20)
        else
          const Icon(Icons.chevron_right),
      ]),
    );
  }
}
