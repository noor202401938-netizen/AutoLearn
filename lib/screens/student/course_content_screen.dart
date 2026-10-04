// lib/screens/student/course_content_screen.dart
import 'package:flutter/material.dart';
import '../../backend/api_client.dart';
import '../../business_logic/enrollment_manager.dart';
import '../../business_logic/video_manager.dart';
import '../../model/course_model.dart';
import '../../model/video_progress_model.dart';
import '../../repository/community_repository.dart';
import '../../repository/course_repository.dart';
import '../../repository/progress_repository.dart';
import '../../widgets/economics/supply_demand_widget.dart';
import '../../widgets/notebook/notebook.dart';
import 'ai_quiz_screen.dart';
import 'ai_tutor_chat_screen.dart';
import 'assignment_screen.dart';
import 'payment_screen.dart';
import 'video_player_screen.dart';

const _kindLabel = {
  'video': 'video',
  'reading': 'reading',
  'quiz': 'quiz',
  'assignment': 'assignment',
  'project': 'project',
};

/// A course as a notebook: the cover page, then the table of contents with a
/// tick next to every lesson you've finished.
class CourseContentScreen extends StatefulWidget {
  final String courseId;
  final String title;

  /// Open this lesson straight away (e.g. from a bookmark).
  final String? initialLessonId;

  const CourseContentScreen({super.key, required this.courseId, required this.title, this.initialLessonId});

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen> {
  final _courses = CourseRepository();
  final _progress = ProgressRepository();
  final _enrollment = EnrollmentManager();
  final _community = CommunityRepository();
  final _videoManager = VideoManager();

  CourseModel? _course;
  Map<String, VideoProgressModel> _done = {};
  bool _enrolled = false;
  bool _loading = true;
  bool _failed = false;
  bool _enrolling = false;
  bool _openedInitial = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _course == null;
      _failed = false;
    });
    try {
      final course = await _courses.getCourseById(widget.courseId);
      if (course == null) throw Exception('missing');
      final results = await Future.wait([
        _progress.getCourseProgress(userId: '', courseId: widget.courseId),
        _enrollment.isEnrolled(widget.courseId),
      ]);
      if (!mounted) return;
      setState(() {
        _course = course;
        _done = {for (final p in results[0] as List<VideoProgressModel>) p.lessonId: p};
        _enrolled = results[1] as bool;
        _loading = false;
      });
      _openInitialLesson();
    } on Exception {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _openInitialLesson() {
    if (_openedInitial || widget.initialLessonId == null || !_enrolled) return;
    _openedInitial = true;
    for (final m in _course!.syllabus) {
      for (final l in m.lessons) {
        if (l.lessonId == widget.initialLessonId) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _open(m, l));
          return;
        }
      }
    }
  }

  int get _lessonCount => _course!.syllabus.fold(0, (n, m) => n + m.lessons.length);
  bool _isDone(LessonModel l) => _done[l.lessonId]?.isCompleted ?? false;
  int get _doneCount => _course!.syllabus.expand((m) => m.lessons).where(_isDone).length;

  (ModuleModel, LessonModel)? get _next {
    for (final m in _course!.syllabus) {
      for (final l in m.lessons) {
        if (!_isDone(l)) return (m, l);
      }
    }
    return null;
  }

  Future<void> _enrol() async {
    final c = _course!;
    if (c.price > 0) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            courseId: c.courseId,
            courseTitle: c.title,
            amountCents: (c.price * 100).round(),
            currency: c.currency,
          ),
        ),
      );
      return _load();
    }
    setState(() => _enrolling = true);
    final error = await _enrollment.enrollInCourse(c.courseId);
    if (!mounted) return;
    setState(() => _enrolling = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      setState(() => _enrolled = true);
    }
  }

  Future<void> _bookmark({LessonModel? lesson}) async {
    try {
      await _community.addBookmark(courseId: widget.courseId, title: lesson?.title ?? _course!.title, lessonId: lesson?.lessonId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmarked')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _open(ModuleModel m, LessonModel l) async {
    if (!_enrolled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrol in the course to start this lesson')));
      return;
    }
    final Widget page = switch (l.type) {
      'quiz' => AIQuizScreen(
          courseId: widget.courseId,
          courseTitle: _course!.title,
          moduleId: m.moduleId,
          moduleTitle: m.title,
          lessonId: l.lessonId,
          lessonTitle: l.title,
        ),
      'assignment' || 'project' => AssignmentScreen(
          courseId: widget.courseId,
          courseTitle: _course!.title,
          moduleId: m.moduleId,
          moduleTitle: m.title,
          lessonId: l.lessonId,
          lessonTitle: l.title,
        ),
      'video' when (l.videoURL ?? '').isNotEmpty => VideoPlayerScreen(
          courseId: widget.courseId,
          courseTitle: _course!.title,
          moduleId: m.moduleId,
          moduleTitle: m.title,
          lesson: l,
          videoManager: _videoManager,
          course: _course,
        ),
      _ => _ReadingPage(
          courseId: widget.courseId,
          lesson: l,
          done: _isDone(l),
          onBookmark: () => _bookmark(lesson: l),
        ),
    };
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_failed) {
      body = NotebookError(message: "Couldn't open this course", onRetry: _load);
    } else {
      body = RefreshIndicator(onRefresh: _load, child: _page());
    }
    return NotebookPage(
      title: '',
      actions: [
        if (_course != null)
          IconButton(tooltip: 'Bookmark course', icon: const Icon(Icons.bookmark_add_outlined), onPressed: _bookmark),
      ],
      body: body,
    );
  }

  Widget _page() {
    final theme = Theme.of(context);
    final c = _course!;
    final wide = MediaQuery.of(context).size.width >= 900;
    final isEconomics = '${c.category} ${c.title}'.toLowerCase().contains('econ');

    final cover = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(c.category.toUpperCase(), style: theme.textTheme.labelSmall),
      const SizedBox(height: 8),
      Text(c.title, style: theme.textTheme.displaySmall),
      const SizedBox(height: 6),
      MarginNote('with ${c.instructor} · ${c.level}', size: 20),
      const SizedBox(height: 16),
      Text(c.description, style: theme.textTheme.bodyLarge),
    ]);

    return ListView(padding: EdgeInsets.fromLTRB(wide ? 48 : 20, 8, wide ? 48 : 20, 64), children: [
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: cover),
          const SizedBox(width: 40),
          SizedBox(width: 300, child: _statusCard()),
        ])
      else ...[
        cover,
        const SizedBox(height: 20),
        _statusCard(),
      ],
      const SizedBox(height: 40),
      NoteHeading('Contents', note: '$_lessonCount lessons'),
      const SizedBox(height: 16),
      if (c.syllabus.isEmpty)
        const NotebookEmpty(title: 'No lessons yet', note: 'the instructor is still writing this one')
      else
        for (final (i, m) in c.syllabus.indexed) _chapter(i, m),
      if (isEconomics) ...[
        const SizedBox(height: 32),
        const NoteHeading('Lab', note: 'drag the curves'),
        const SizedBox(height: 16),
        const SupplyDemandInteractiveWidget(),
      ],
    ]);
  }

  Widget _statusCard() {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final c = _course!;
    final total = _lessonCount;
    final done = _doneCount;
    final next = _next;
    return NoteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_enrolled) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('$done', style: NotebookColors.figures(size: 34, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            Text(' / $total lessons', style: theme.textTheme.bodyMedium),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: total == 0 ? 0 : done / total, minHeight: 4),
          ),
          const SizedBox(height: 16),
          if (next != null) ...[
            MarginNote('next up', size: 18, tilt: 0),
            Text(next.$2.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => _open(next.$1, next.$2), child: const Text('Continue')),
            ),
          ] else
            MarginNote('course complete ✓', size: 22, tilt: 0, color: nb.correct),
        ] else ...[
          Text(c.price > 0 ? '${c.currency} ${c.price.toStringAsFixed(2)}' : 'Free',
              style: NotebookColors.figures(size: 28, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          MarginNote('$total lessons · ${c.duration}h of study', size: 18, tilt: 0),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enrolling ? null : _enrol,
              child: Text(c.price > 0 ? 'Buy and enrol' : 'Enrol — it\'s free'),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _chapter(int i, ModuleModel m) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Chapter ${i + 1} — ${m.title}', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        for (final (j, l) in m.lessons.indexed)
          InkWell(
            onTap: () => _open(m, l),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                SizedBox(
                  width: 44,
                  child: Text('${i + 1}.${j + 1}', style: NotebookColors.figures(size: 13, color: theme.colorScheme.onSurfaceVariant)),
                ),
                Flexible(child: Text(l.title, style: theme.textTheme.bodyLarge)),
                // Dotted leader, like a printed table of contents.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: LayoutBuilder(
                      builder: (_, box) => Text(
                        '·' * (box.maxWidth / 6).floor().clamp(0, 400),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ),
                  ),
                ),
                Text(
                  '${_kindLabel[l.type] ?? l.type}${l.duration > 0 ? ' · ${l.duration} min' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(
                  width: 32,
                  child: _isDone(l)
                      ? Text(' ✓', style: nb.hand(size: 22, color: nb.correct))
                      : null,
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// A reading lesson: the text on a ruled page, with a "done" button at the end
/// that records it as complete.
class _ReadingPage extends StatefulWidget {
  final String courseId;
  final LessonModel lesson;
  final bool done;
  final VoidCallback onBookmark;
  const _ReadingPage({required this.courseId, required this.lesson, required this.done, required this.onBookmark});

  @override
  State<_ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<_ReadingPage> {
  late bool _done = widget.done;
  bool _saving = false;

  Future<void> _markDone() async {
    setState(() => _saving = true);
    try {
      await ProgressRepository().saveVideoProgress(
        userId: '',
        courseId: widget.courseId,
        moduleId: '',
        lessonId: widget.lesson.lessonId,
        videoURL: '',
        // Counts the lesson's reading time towards "hours studied".
        currentPosition: widget.lesson.duration * 60,
        totalDuration: widget.lesson.duration * 60,
        isCompleted: true,
      );
      if (!mounted) return;
      setState(() => _done = true);
      Navigator.pop(context);
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't save your progress — try again")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final l = widget.lesson;
    return NotebookPage(
      title: '',
      actions: [IconButton(tooltip: 'Bookmark lesson', icon: const Icon(Icons.bookmark_add_outlined), onPressed: widget.onBookmark)],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 64), children: [
            Text(l.title, style: theme.textTheme.displaySmall),
            if (l.duration > 0) MarginNote('${l.duration} min read', size: 19),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.only(left: 20),
              decoration: BoxDecoration(border: Border(left: BorderSide(color: nb.marginLine.withValues(alpha: 0.6), width: 1.5))),
              child: NoteText((l.content ?? '').isEmpty ? 'This lesson has no text yet.' : l.content!),
            ),
            const SizedBox(height: 32),
            Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              if (_done)
                MarginNote('done ✓', size: 22, tilt: 0, color: nb.correct)
              else
                ElevatedButton(onPressed: _saving ? null : _markDone, child: const Text("I've read this")),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AITutorChatScreen(contextTitle: l.title)),
                ),
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Ask the tutor about this'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
