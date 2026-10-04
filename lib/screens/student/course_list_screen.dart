import 'package:flutter/material.dart';
import '../../business_logic/course_manager.dart';
import '../../model/course_model.dart';
import '../../repository/enrollment_repository.dart';
import '../../widgets/notebook/notebook.dart';
import 'course_content_screen.dart';

const _levels = ['all', 'beginner', 'intermediate', 'advanced'];

/// The course catalogue: a shelf of index cards you can search and filter.
class CourseListScreen extends StatefulWidget {
  final bool embedded;
  const CourseListScreen({super.key, this.embedded = false});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final _courses = CourseManager();
  final _enrollments = EnrollmentRepository();

  List<CourseModel>? _all;
  Map<String, double> _progress = {}; // enrolled courseId -> 0..1
  bool _failed = false;
  String _query = '';
  String _category = 'all';
  String _level = 'all';
  bool _mineOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final results = await Future.wait([_courses.getPublishedCourses(), _enrollments.getUserEnrollments('')]);
      if (!mounted) return;
      setState(() {
        _all = results[0] as List<CourseModel>;
        _progress = {
          for (final e in results[1] as List<Map<String, dynamic>>)
            e['courseId'] as String: (e['progressPercent'] as num?)?.toDouble() ?? 0,
        };
      });
    } on Exception {
      if (mounted) setState(() => _failed = true);
    }
  }

  List<CourseModel> get _visible {
    final q = _query.toLowerCase();
    return _all!.where((c) {
      if (_mineOnly && !_progress.containsKey(c.courseId)) return false;
      if (_category != 'all' && c.category != _category) return false;
      if (_level != 'all' && c.level.toLowerCase() != _level) return false;
      return q.isEmpty || '${c.title} ${c.description} ${c.instructor} ${c.category}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _open(CourseModel c) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CourseContentScreen(courseId: c.courseId, title: c.title)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_failed) {
      content = NotebookError(message: "Couldn't load the catalogue", onRetry: _load);
    } else if (_all == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = RefreshIndicator(onRefresh: _load, child: _page());
    }
    return widget.embedded ? content : NotebookPage(title: 'Courses', body: content);
  }

  Widget _page() {
    final theme = Theme.of(context);
    final categories = ['all', ...{for (final c in _all!) c.category}];
    final visible = _visible;
    return ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
      Text('Courses', style: theme.textTheme.displaySmall),
      MarginNote('${_all!.length} on the shelf · ${_progress.length} in your bag'),
      const SizedBox(height: 20),
      TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by topic, title or instructor'),
        onChanged: (v) => setState(() => _query = v.trim()),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilterChip(label: const Text('My courses'), selected: _mineOnly, onSelected: (v) => setState(() => _mineOnly = v)),
        for (final c in categories)
          ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        for (final l in _levels)
          ChoiceChip(label: Text(l == 'all' ? 'any level' : l), selected: _level == l, onSelected: (_) => setState(() => _level = l)),
      ]),
      const SizedBox(height: 24),
      if (visible.isEmpty)
        NotebookEmpty(
          title: _all!.isEmpty ? 'No courses published yet' : 'Nothing matches those filters',
          note: _all!.isEmpty ? 'check back soon' : 'try a broader search',
        )
      else
        LayoutBuilder(builder: (context, box) {
          final cols = (box.maxWidth / 320).floor().clamp(1, 4);
          final w = (box.maxWidth - (cols - 1) * 20) / cols;
          return Wrap(spacing: 20, runSpacing: 20, children: [
            for (final c in visible) SizedBox(width: w, child: _CourseCard(course: c, progress: _progress[c.courseId], onTap: () => _open(c))),
          ]);
        }),
    ]);
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final double? progress; // null = not enrolled
  final VoidCallback onTap;
  const _CourseCard({required this.course, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final c = course;
    final lessons = c.syllabus.fold<int>(0, (n, m) => n + m.lessons.length);
    return NoteCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(c.category.toUpperCase(), style: theme.textTheme.labelSmall)),
          if (progress != null) Highlight('enrolled', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface)),
        ]),
        const SizedBox(height: 10),
        Text(c.title, style: theme.textTheme.headlineSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Text(c.description, style: theme.textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        Text('${c.instructor} · ${c.level}', style: nb.note(size: 13, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 10),
        Row(children: [
          Text('$lessons lessons', style: theme.textTheme.bodySmall),
          if (c.rating > 0) ...[
            const SizedBox(width: 12),
            Icon(Icons.star_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
            Text(' ${c.rating.toStringAsFixed(1)}', style: theme.textTheme.bodySmall),
          ],
          const Spacer(),
          if (progress != null)
            Text('${(progress! * 100).round()}% done', style: NotebookColors.figures(size: 13, weight: FontWeight.w600, color: theme.colorScheme.onSurface))
          else
            Text(c.price > 0 ? '${c.currency} ${c.price.toStringAsFixed(2)}' : 'Free',
                style: NotebookColors.figures(size: 13, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        ]),
      ]),
    );
  }
}
