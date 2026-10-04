// Teacher sections for money and teamwork: earnings from sales of their own
// courses, and the co-teachers who share a course.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/api_client.dart';
import '../../widgets/notebook/notebook.dart';
import '../admin/admin_pages.dart';
import 'teacher_pages.dart' show CoursePicker;

String _money(num amount, String currency) => NumberFormat.simpleCurrency(name: currency).format(amount);

// ── Earnings ─────────────────────────────────────────────────────────────────

class TeacherEarningsPage extends StatelessWidget {
  const TeacherEarningsPage({super.key});

  @override
  Widget build(BuildContext context) => PageLoader(
        endpoint: '/teacher/earnings',
        builder: (context, d, _) {
          final theme = Theme.of(context);
          final totals = (d['totals'] as List).cast<Map<String, dynamic>>();
          final courses = (d['courses'] as List).cast<Map<String, dynamic>>();
          final recent = (d['recent'] as List).cast<Map<String, dynamic>>();
          return ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
            pageTitle(context, 'Earnings', 'sales of courses you created'),
            const SizedBox(height: 24),
            if (totals.isEmpty)
              const NotebookEmpty(title: 'No sales yet', note: 'paid enrolments will appear here')
            else ...[
              NoteCard(
                child: Wrap(spacing: 24, runSpacing: 20, children: [
                  for (final t in totals)
                    figureTile(context, _money(t['amount'] as num, t['currency'] as String), '${t['sales']} ${t['sales'] == 1 ? 'sale' : 'sales'}'),
                ]),
              ),
              const SizedBox(height: 28),
              const NoteHeading('By course'),
              const SizedBox(height: 8),
              for (final c in courses)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c['title'] as String),
                  subtitle: Text('${c['sales']} ${c['sales'] == 1 ? 'sale' : 'sales'}'),
                  trailing: Text(_money(c['amount'] as num, c['currency'] as String),
                      style: NotebookColors.figures(size: 14, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                ),
              const SizedBox(height: 28),
              const NoteHeading('Latest sales'),
              const SizedBox(height: 8),
              for (final p in recent)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p['title'] as String),
                  subtitle: Text(DateFormat('d MMM yyyy').format(DateTime.parse(p['createdAt'] as String))),
                  trailing: Text(_money(p['amount'] as num, p['currency'] as String), style: NotebookColors.figures(size: 13, color: theme.colorScheme.onSurface)),
                ),
            ],
          ]);
        },
      );
}

// ── Team ─────────────────────────────────────────────────────────────────────

class TeacherTeamPage extends StatelessWidget {
  const TeacherTeamPage({super.key});

  @override
  Widget build(BuildContext context) => CoursePicker(
        title: 'Co-teachers',
        note: 'share a course with another teacher',
        builder: (context, courseId, _) => _Team(key: ValueKey(courseId), courseId: courseId),
      );
}

class _Team extends StatefulWidget {
  final String courseId;
  const _Team({super.key, required this.courseId});

  @override
  State<_Team> createState() => _TeamState();
}

class _TeamState extends State<_Team> {
  final _email = TextEditingController();
  Map<String, dynamic>? _data;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance.json('GET', '/teacher/courses/${widget.courseId}/co-teachers');
      if (mounted) setState(() => _data = d as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _add() => _run(() async {
        await ApiClient.instance.json('POST', '/teacher/courses/${widget.courseId}/co-teachers', body: {'email': _email.text.trim()});
        _email.clear();
      });

  Future<void> _remove(String userId) =>
      _run(() => ApiClient.instance.json('DELETE', '/teacher/courses/${widget.courseId}/co-teachers/$userId'));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_error != null) return NotebookError(message: _error!, onRetry: _load);
    final data = _data;
    if (data == null) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
    final members = (data['members'] as List).cast<Map<String, dynamic>>();
    final canEdit = data['canEdit'] == true;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final m in members)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(m['name'] as String),
            subtitle: Text(m['email'] as String),
            leading: m['isOwner'] == true ? Highlight('creator', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface)) : null,
            trailing: canEdit && m['isOwner'] != true
                ? IconButton(
                    tooltip: 'Remove from course',
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: _busy ? null : () => _remove(m['userId'] as String),
                  )
                : null,
          ),
        ),
      const SizedBox(height: 12),
      if (canEdit)
        NoteCard(
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Add a teacher by email'),
                onSubmitted: (_) => _busy ? null : _add(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _busy ? null : _add, child: const Text('Add')),
          ]),
        )
      else
        const MarginNote('only the course creator can change the team'),
    ]);
  }
}
