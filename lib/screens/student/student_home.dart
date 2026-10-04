// lib/screens/student/student_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/api_client.dart';
import '../../business_logic/recommendation_engine.dart';
import '../../model/course_model.dart';
import '../../repository/enrollment_repository.dart';
import '../../repository/auth_repository.dart';
import '../../widgets/notebook/notebook.dart';
import '../../widgets/notebook/shell.dart';
import '../../widgets/student_home/profile_tab.dart';
import 'ai_tutor_chat_screen.dart';
import 'assignments_hub_screen.dart';
import 'bookmarks_screen.dart';
import 'certificates_list_screen.dart';
import 'community_forum_screen.dart';
import 'course_content_screen.dart';
import 'course_list_screen.dart';
import 'learning_paths_screen.dart';

const _sections = [
  ShellSection('Today', Icons.edit_note),
  ShellSection('Courses', Icons.menu_book_outlined),
  ShellSection('Learning paths', Icons.route_outlined),
  ShellSection('AI tutor', Icons.forum_outlined),
  ShellSection('Assignments', Icons.assignment_outlined),
  ShellSection('Bookmarks', Icons.bookmark_border),
  ShellSection('Forum', Icons.groups_outlined),
  ShellSection('Certificates', Icons.workspace_premium_outlined),
  ShellSection('Profile', Icons.person_outline),
];

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  Widget _page() => switch (_index) {
        0 => _TodayPage(onNavigate: _go),
        1 => const CourseListScreen(embedded: true),
        2 => const LearningPathsScreen(embedded: true),
        3 => const AITutorChatScreen(embedded: true),
        4 => const AssignmentsHubScreen(embedded: true),
        5 => const BookmarksScreen(embedded: true),
        6 => const CommunityForumScreen(embedded: true),
        7 => const CertificatesListScreen(embedded: true),
        _ => const _ProfilePage(),
      };

  @override
  Widget build(BuildContext context) => NotebookShell(
        sections: _sections,
        index: _index,
        onSelect: _go,
        page: _page(),
        tagline: 'learn anything, in your own notes',
        mobileTabs: const [0, 1, 3, 4],
      );
}

/// The "Today" page — a fresh notebook page with the date at the top.
class _TodayPage extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const _TodayPage({required this.onNavigate});

  @override
  State<_TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<_TodayPage> {
  final _enrollments = EnrollmentRepository();
  final _recommendations = RecommendationEngine();

  String _name = '';
  Map<String, dynamic> _stats = const {};
  List<Map<String, dynamic>> _enrolled = [];
  List<CourseModel> _recommended = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final api = ApiClient.instance;
      final results = await Future.wait([
        api.get('/user/profile'),
        api.get('/user/stats'),
        _enrollments.getUserEnrollments(''),
      ]);
      final profile = results[0] as dynamic;
      final stats = results[1] as dynamic;
      if (!mounted) return;
      setState(() {
        if (profile.statusCode == 200) {
          final p = jsonDecode(profile.body) as Map<String, dynamic>;
          _name = (p['displayName'] as String?)?.trim().isNotEmpty == true
              ? p['displayName'] as String
              : (p['email'] as String? ?? '').split('@').first;
        }
        if (stats.statusCode == 200) _stats = jsonDecode(stats.body) as Map<String, dynamic>;
        _enrolled = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } on Exception {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
    // Recommendations are a nice-to-have; never block the page on them.
    try {
      final recs = await _recommendations.getRecommendations();
      if (mounted) setState(() => _recommended = recs);
    } on Exception {
      // leave empty
    }
  }

  Future<void> _openCourse(String id, String title) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseContentScreen(courseId: id, title: title)),
    );
    // Progress and enrolments may have changed while the course was open.
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) return NotebookError(message: "Couldn't load today's page", onRetry: _load);

    final theme = Theme.of(context);
    final wide = MediaQuery.of(context).size.width >= 700;
    final streak = (_stats['streakDays'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(wide ? 48 : 20, 32, wide ? 48 : 20, 48),
        children: [
          MarginNote(DateFormat('EEEE, d MMMM').format(DateTime.now()), size: 22),
          const SizedBox(height: 6),
          Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 16, runSpacing: 4, children: [
            Text(
              // New students get a welcome; returning ones a welcome back.
              '${_enrolled.isEmpty ? 'Welcome' : 'Welcome back'}${_name.isEmpty ? '' : ', ${_name.split(' ').first}'}.',
              style: theme.textTheme.displaySmall,
            ),
            if (streak > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: MarginNote('$streak days in a row — keep going!', size: 19),
              ),
          ]),
          const SizedBox(height: 28),
          _Ledger(stats: _stats),
          const SizedBox(height: 36),
          NoteHeading(
            'Pick up where you left off',
            trailing: TextButton(onPressed: () => widget.onNavigate(1), child: const Text('All courses')),
          ),
          const SizedBox(height: 16),
          if (_enrolled.isEmpty)
            NotebookEmpty(
              title: 'Your notebook is empty',
              note: 'enrol in a course to start taking notes',
              actionLabel: 'Browse courses',
              onAction: () => widget.onNavigate(1),
            )
          else
            for (final e in _enrolled.take(3)) ...[
              _ContinueCard(enrollment: e, onTap: () {
                final c = (e['course'] as Map?) ?? const {};
                _openCourse(c['courseId'] as String? ?? '', c['title'] as String? ?? '');
              }),
              const SizedBox(height: 14),
            ],
          const SizedBox(height: 24),
          _TutorStickyNote(onTap: () => widget.onNavigate(3)),
          if (_recommended.isNotEmpty) ...[
            const SizedBox(height: 40),
            const NoteHeading('Worth reading next', note: 'picked for you'),
            const SizedBox(height: 16),
            Wrap(spacing: 16, runSpacing: 16, children: [
              for (final c in _recommended.take(4))
                SizedBox(
                  width: wide ? 240 : double.infinity,
                  child: NoteCard(
                    onTap: () => _openCourse(c.courseId, c.title),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.category.toUpperCase(), style: theme.textTheme.labelSmall),
                      const SizedBox(height: 8),
                      Text(c.title, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text(c.level, style: NotebookColors.of(context).hand(size: 17)),
                    ]),
                  ),
                ),
            ]),
          ],
        ],
      ),
    );
  }
}

/// The week's numbers, written like a ledger: figures in mono, labels by hand.
class _Ledger extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _Ledger({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int n(String k) => (stats[k] as num?)?.toInt() ?? 0;
    final hours = (stats['hoursLearned'] as num?)?.toDouble() ?? 0;
    final items = [
      ('${n('enrolledCourses')}', n('enrolledCourses') == 1 ? 'course' : 'courses'),
      (hours < 10 ? hours.toStringAsFixed(1) : hours.toStringAsFixed(0), 'hours studied'),
      ('${n('totalLessonsWatched')}', n('totalLessonsWatched') == 1 ? 'lesson done' : 'lessons done'),
      ('${n('certificates')}', n('certificates') == 1 ? 'certificate' : 'certificates'),
    ];
    final wide = MediaQuery.of(context).size.width >= 700;
    Widget cell((String, String) it) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.$1, style: NotebookColors.figures(size: 30, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            MarginNote(it.$2, size: 18, tilt: 0, color: theme.colorScheme.onSurfaceVariant),
          ]),
        );

    return NoteCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: wide
          ? IntrinsicHeight(
              child: Row(children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const VerticalDivider(width: 32),
                  Expanded(child: cell(items[i])),
                ],
              ]),
            )
          : GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              children: [for (final it in items) cell(it)],
            ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final Map<String, dynamic> enrollment;
  final VoidCallback onTap;
  const _ContinueCard({required this.enrollment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final course = (enrollment['course'] as Map?) ?? const {};
    final pct = ((enrollment['progressPercent'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
    return NoteCard(
      onTap: onTap,
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(course['title'] as String? ?? 'Course', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(course['instructor'] as String? ?? '', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 14),
            // Progress drawn as a pencil line over a dotted track.
            LayoutBuilder(builder: (context, c) {
              return Stack(children: [
                Container(height: 6, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 2)))),
                Container(width: c.maxWidth * pct, height: 6, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 3)))),
              ]);
            }),
          ]),
        ),
        const SizedBox(width: 20),
        Column(children: [
          Text('${(pct * 100).round()}%', style: NotebookColors.figures(size: 22, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          Text(pct == 0 ? 'not started' : 'done', style: nb.hand(size: 16)),
        ]),
      ]),
    );
  }
}

/// A yellow sticky note stuck to the page, pointing at the AI tutor.
class _TutorStickyNote extends StatelessWidget {
  final VoidCallback onTap;
  const _TutorStickyNote({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nb = NotebookColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Theme.of(context).colorScheme.onSurface : const Color(0xFF3B3415);
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.rotate(
        angle: -0.012,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: NoteCard(
            onTap: onTap,
            color: nb.highlighter.withValues(alpha: dark ? 0.18 : 0.85),
            child: Row(children: [
              const NotebookMark(size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Stuck on something?', style: nb.hand(size: 26, color: ink)),
                  Text('Ask the AI tutor — it explains step by step and checks your reasoning.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ink)),
                ]),
              ),
              Icon(Icons.arrow_forward, color: ink),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage();

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  final _auth = AuthRepository();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await _auth.getCurrentUser();
    if (mounted) setState(() => _user = u);
  }

  @override
  Widget build(BuildContext context) => ProfileTab(userProfile: _user, onProfileUpdated: _load);
}
