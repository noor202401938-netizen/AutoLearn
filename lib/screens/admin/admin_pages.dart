// Admin sections other than course authoring. Every figure shown here is
// read from the server; failures show an error, never a placeholder number.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/api_client.dart';
import '../../business_logic/auth_manager.dart';
import '../../widgets/notebook/notebook.dart';
import '../student/change_password_screen.dart';

/// Loads one JSON endpoint and renders it, with loading/error states.
class _Loader extends StatefulWidget {
  final String endpoint;
  final Widget Function(BuildContext, dynamic data, Future<void> Function() reload) builder;
  const _Loader({super.key, required this.endpoint, required this.builder});

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  dynamic _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance.json('GET', widget.endpoint);
      if (mounted) {
        setState(() {
          _data = d;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return NotebookError(message: _error!, onRetry: _load);
    if (_data == null) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(onRefresh: _load, child: widget.builder(context, _data, _load));
  }
}

Widget _pageTitle(BuildContext context, String title, String note) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(title, style: Theme.of(context).textTheme.displaySmall), MarginNote(note)],
    );

Widget _figure(BuildContext context, String value, String label) {
  final theme = Theme.of(context);
  return SizedBox(
    width: 170,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: NotebookColors.figures(size: 28, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
      MarginNote(label, size: 18, tilt: 0, color: theme.colorScheme.onSurfaceVariant),
    ]),
  );
}

void _toast(BuildContext context, String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

// ── Overview ─────────────────────────────────────────────────────────────────

class AdminOverviewPage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const AdminOverviewPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) => _Loader(
        endpoint: '/admin/analytics',
        builder: (context, d, _) {
          final theme = Theme.of(context);
          final money = NumberFormat.simpleCurrency(name: 'USD');
          final avgQuiz = d['averageQuizScore'] as num?;
          final weeks = (d['signupsByWeek'] as List).cast<Map<String, dynamic>>();
          final courses = (d['courses'] as List).cast<Map<String, dynamic>>();
          final toMark = d['assignmentsToMark'] as int;
          final unanswered = d['unansweredQuestions'] as int;
          return ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
            _pageTitle(context, 'Overview', DateFormat('EEEE, d MMMM').format(DateTime.now())),
            const SizedBox(height: 24),
            NoteCard(
              child: Wrap(spacing: 24, runSpacing: 20, children: [
                _figure(context, '${d['students']}', 'students'),
                _figure(context, '${d['activeLearners7d']}', 'active this week'),
                _figure(context, '${d['totalEnrollments']}', 'enrolments'),
                _figure(context, '${((d['completionRate'] as num) * 100).round()}%', 'complete their course'),
                _figure(context, avgQuiz == null ? '—' : '${avgQuiz.round()}%', 'average quiz score'),
                _figure(context, money.format(d['totalRevenue'] as num), 'revenue'),
              ]),
            ),
            if (toMark > 0 || unanswered > 0) ...[
              const SizedBox(height: 28),
              const NoteHeading('Needs you'),
              const SizedBox(height: 10),
              if (unanswered > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.help_outline),
                  title: Text('$unanswered forum ${unanswered == 1 ? 'question has' : 'questions have'} no replies yet'),
                ),
              if (toMark > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.assignment_late_outlined),
                  title: Text('$toMark assignment ${toMark == 1 ? 'submission is' : 'submissions are'} waiting for a mark'),
                  subtitle: const Text('These were saved while the AI marker was unavailable.'),
                ),
            ],
            const SizedBox(height: 28),
            const NoteHeading('New students', note: 'last 8 weeks'),
            const SizedBox(height: 14),
            SizedBox(height: 140, child: _WeekBars(weeks)),
            const SizedBox(height: 28),
            NoteHeading('Courses', trailing: TextButton(onPressed: () => onNavigate(1), child: const Text('Manage'))),
            const SizedBox(height: 8),
            for (final c in courses)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(c['title'] as String),
                subtitle: Text(c['isPublished'] == true ? 'published' : 'draft'),
                trailing: Text(
                  '${c['enrollmentCount']} enrolled${(c['ratingCount'] as int) > 0 ? '  ·  rated ${(c['rating'] as num).toStringAsFixed(1)}' : ''}',
                  style: NotebookColors.figures(size: 13, color: theme.colorScheme.onSurface),
                ),
              ),
          ]);
        },
      );
}

/// Hand-drawn weekly bar chart.
class _WeekBars extends StatelessWidget {
  final List<Map<String, dynamic>> weeks;
  const _WeekBars(this.weeks);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final most = weeks.fold<int>(1, (m, w) => math.max(m, w['count'] as int));
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (final w in weeks)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('${w['count']}', style: NotebookColors.figures(size: 12, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 4),
              Container(
                height: 90 * (w['count'] as int) / most + 2,
                decoration: BoxDecoration(
                  color: nb.highlighter.withValues(alpha: 0.7),
                  border: Border.all(color: theme.colorScheme.onSurface, width: 1.2),
                ),
              ),
              const SizedBox(height: 4),
              Text(DateFormat('d MMM').format(DateTime.parse(w['weekStart'] as String)), style: theme.textTheme.bodySmall),
            ]),
          ),
        ),
    ]);
  }
}

// ── Students ─────────────────────────────────────────────────────────────────

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  String _query = '';

  Future<void> _act(BuildContext context, Future<void> Function() f, Future<void> Function() reload) async {
    try {
      await f();
      await reload();
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => _Loader(
        endpoint: '/auth/users',
        builder: (context, data, reload) {
          final theme = Theme.of(context);
          final api = ApiClient.instance;
          final users = (data as List).cast<Map<String, dynamic>>().where((u) {
            final q = _query.toLowerCase();
            return q.isEmpty || '${u['displayName']} ${u['email']}'.toLowerCase().contains(q);
          }).toList();
          return ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
            _pageTitle(context, 'People', '${(data).length} accounts'),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name or email'),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
            const SizedBox(height: 16),
            for (final u in users)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text((u['displayName'] as String?)?.isNotEmpty == true ? u['displayName'] as String : u['email'] as String),
                  subtitle: Text(
                    '${u['email']} · ${u['enrollmentCount']} courses · joined ${DateFormat('d MMM yyyy').format(DateTime.parse(u['createdAt'] as String))}',
                  ),
                  leading: u['role'] == 'admin'
                      ? Highlight('admin', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface))
                      : null,
                  trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                    if (u['isActive'] != true) MarginNote('disabled', size: 17, tilt: 0),
                    PopupMenuButton<String>(
                      tooltip: 'Actions',
                      onSelected: (a) => switch (a) {
                        'toggle' => _act(context, () => api.json('PATCH', '/auth/users/${u['uid']}/toggle-status', body: {}), reload),
                        'role' => _act(
                            context,
                            () => api.json('PUT', '/users/${u['uid']}/role', body: {'role': u['role'] == 'admin' ? 'student' : 'admin'}),
                            reload,
                          ),
                        _ => _confirmDelete(context, u, reload),
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'toggle', child: Text(u['isActive'] == true ? 'Disable sign-in' : 'Enable sign-in')),
                        PopupMenuItem(value: 'role', child: Text(u['role'] == 'admin' ? 'Make student' : 'Make admin')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete account')),
                      ],
                    ),
                  ]),
                ),
              ),
          ]);
        },
      );

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> u, Future<void> Function() reload) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Delete ${u['email']}?'),
        content: const Text('Their enrolments, progress, submissions and posts are removed too. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true && context.mounted) await _act(context, () => ApiClient.instance.json('DELETE', '/users/${u['uid']}'), reload);
  }
}

// ── Payments ─────────────────────────────────────────────────────────────────

class AdminPaymentsPage extends StatelessWidget {
  const AdminPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) => _Loader(
        endpoint: '/finance/stats',
        builder: (context, stats, reloadStats) {
          final money = NumberFormat.simpleCurrency(name: 'USD');
          final monthly = (stats['monthly'] as List).cast<Map<String, dynamic>>();
          return ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
            _pageTitle(context, 'Payments', 'course sales through Stripe'),
            const SizedBox(height: 24),
            NoteCard(
              child: Wrap(spacing: 24, runSpacing: 20, children: [
                _figure(context, money.format(stats['totalRevenue'] as num), 'revenue'),
                _figure(context, '${stats['successfulTransactions']}', 'sales'),
                _figure(context, money.format(stats['refunded'] as num), 'refunded'),
                _figure(context, money.format(stats['pending'] as num), 'pending'),
              ]),
            ),
            const SizedBox(height: 28),
            const NoteHeading('By month'),
            const SizedBox(height: 14),
            SizedBox(
              height: 140,
              child: _WeekBars([
                for (final m in monthly) {'count': (m['revenue'] as num).round(), 'weekStart': '${m['month']}-01'},
              ]),
            ),
            const SizedBox(height: 28),
            const NoteHeading('Transactions'),
            const SizedBox(height: 8),
            SizedBox(height: 560, child: _Transactions(onChanged: reloadStats)),
          ]);
        },
      );
}

class _Transactions extends StatelessWidget {
  final Future<void> Function() onChanged;
  const _Transactions({required this.onChanged});

  @override
  Widget build(BuildContext context) => _Loader(
        endpoint: '/payments',
        builder: (context, data, reload) {
          final theme = Theme.of(context);
          final rows = (data as List).cast<Map<String, dynamic>>();
          if (rows.isEmpty) return const NotebookEmpty(title: 'No payments yet', note: 'sales appear here as they happen');
          return ListView(children: [
            for (final p in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${p['course']?['title'] ?? 'Course'} — ${p['user']?['email'] ?? ''}'),
                subtitle: Text('${DateFormat('d MMM yyyy').format(DateTime.parse(p['createdAt'] as String))} · ${p['status']}'),
                trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                  Text('${p['currency']} ${(p['amount'] as num).toStringAsFixed(2)}',
                      style: NotebookColors.figures(size: 14, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                  if (p['status'] == 'succeeded')
                    TextButton(
                      onPressed: () async {
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (d) => AlertDialog(
                            title: const Text('Refund this payment?'),
                            content: const Text('The money goes back through Stripe and the student loses access to the course.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Refund')),
                            ],
                          ),
                        );
                        if (yes != true) return;
                        try {
                          await ApiClient.instance.json('POST', '/payments/${p['id']}/refund', body: {});
                          await reload();
                          await onChanged();
                        } on ApiException catch (e) {
                          if (context.mounted) _toast(context, e.message);
                        }
                      },
                      child: const Text('Refund'),
                    ),
                ]),
              ),
          ]);
        },
      );
}

// ── Announcements ────────────────────────────────────────────────────────────

class AdminAnnouncementsPage extends StatefulWidget {
  const AdminAnnouncementsPage({super.key});

  @override
  State<AdminAnnouncementsPage> createState() => _AdminAnnouncementsPageState();
}

class _AdminAnnouncementsPageState extends State<AdminAnnouncementsPage> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  String _type = 'system';
  bool _sending = false;
  int _historyKey = 0;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final r = await ApiClient.instance.json('POST', '/user/notifications/broadcast',
          body: {'title': _title.text.trim(), 'message': _message.text.trim(), 'type': _type});
      _title.clear();
      _message.clear();
      if (mounted) {
        _toast(context, r['message'] as String? ?? 'Sent');
        setState(() => _historyKey++);
      }
    } on ApiException catch (e) {
      if (mounted) _toast(context, e.message);
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
      _pageTitle(context, 'Announcements', 'goes to every student\'s notifications'),
      const SizedBox(height: 24),
      NoteCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(controller: _message, minLines: 3, maxLines: 8, decoration: const InputDecoration(labelText: 'Message')),
          const SizedBox(height: 12),
          Row(children: [
            for (final t in const ['system', 'course', 'event'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(t), selected: _type == t, onSelected: (_) => setState(() => _type = t)),
              ),
            const Spacer(),
            ElevatedButton.icon(onPressed: _sending ? null : _send, icon: const Icon(Icons.send, size: 18), label: const Text('Send to all students')),
          ]),
        ]),
      ),
      const SizedBox(height: 28),
      const NoteHeading('Sent'),
      const SizedBox(height: 8),
      SizedBox(
        height: 480,
        child: _Loader(
          key: ValueKey(_historyKey),
          endpoint: '/user/notifications/broadcast-history',
          builder: (context, data, _) {
            final rows = (data as List).cast<Map<String, dynamic>>();
            if (rows.isEmpty) return const NotebookEmpty(title: 'Nothing sent yet', note: 'your announcements will be listed here');
            return ListView(children: [
              for (final b in rows)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(b['title'] as String),
                  subtitle: Text(b['message'] as String, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(timeAgo(DateTime.parse(b['sentAt'] as String)), style: theme.textTheme.bodySmall),
                ),
            ]);
          },
        ),
      ),
    ]);
  }
}

// ── Account ──────────────────────────────────────────────────────────────────

class AdminAccountPage extends StatelessWidget {
  const AdminAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
      _pageTitle(context, 'Account', 'administrator'),
      const SizedBox(height: 24),
      NoteCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Change password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
        ),
      ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: () async {
          await AuthManager().logout();
          if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
        },
        style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error, side: BorderSide(color: theme.colorScheme.error)),
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
      ),
    ]);
  }
}
