import 'package:flutter/material.dart';
import '../../backend/api_client.dart';
import '../../repository/community_repository.dart';
import '../../widgets/notebook/notebook.dart';
import 'course_content_screen.dart';

/// Curated sequences of courses, drawn as a route down the margin.
class LearningPathsScreen extends StatefulWidget {
  final bool embedded;
  const LearningPathsScreen({super.key, this.embedded = false});

  @override
  State<LearningPathsScreen> createState() => _LearningPathsScreenState();
}

class _LearningPathsScreenState extends State<LearningPathsScreen> {
  final _repo = CommunityRepository();
  List<LearningPath>? _paths;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final paths = await _repo.learningPaths();
      if (mounted) setState(() => _paths = paths);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_error != null) {
      content = NotebookError(message: _error!, onRetry: _load);
    } else if (_paths == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      final theme = Theme.of(context);
      content = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
          Text('Learning paths', style: theme.textTheme.displaySmall),
          const MarginNote('courses in the order they build on each other'),
          const SizedBox(height: 28),
          if (_paths!.isEmpty)
            const NotebookEmpty(title: 'No learning paths yet', note: 'your instructors are still drawing the map'),
          for (final p in _paths!) ...[
            _PathCard(path: p, onOpen: _open),
            const SizedBox(height: 28),
          ],
        ]),
      );
    }
    return widget.embedded ? content : NotebookPage(title: 'Learning paths', body: content);
  }

  Future<void> _open(PathStep step) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseContentScreen(courseId: step.courseId, title: step.title)),
    );
    _load(); // progress may have changed
  }
}

class _PathCard extends StatelessWidget {
  final LearningPath path;
  final ValueChanged<PathStep> onOpen;
  const _PathCard({required this.path, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    // The first course not yet finished is "you are here".
    final nextIndex = path.courses.indexWhere((c) => c.completion < 1);

    return NoteCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(path.level.toUpperCase(), style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(path.title, style: theme.textTheme.headlineSmall),
            ]),
          ),
          Column(children: [
            Text('${(path.progress * 100).round()}%',
                style: NotebookColors.figures(size: 22, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            Text('complete', style: nb.note(size: 13)),
          ]),
        ]),
        const SizedBox(height: 8),
        Text(path.description, style: theme.textTheme.bodyMedium),
        if (path.skills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final s in path.skills) Highlight(s, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface)),
          ]),
        ],
        const SizedBox(height: 20),
        for (final (i, c) in path.courses.indexed)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // The route: a dot per course joined by a pencil line.
              SizedBox(
                width: 32,
                child: Column(children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == nextIndex ? nb.highlighter : nb.sheet,
                      border: Border.all(color: c.completion >= 1 ? nb.correct : theme.colorScheme.onSurface, width: 1.5),
                    ),
                    child: c.completion >= 1
                        ? Text('✓', style: nb.hand(size: 18, color: nb.correct))
                        : Text('${i + 1}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface)),
                  ),
                  if (i < path.courses.length - 1)
                    Expanded(child: Container(width: 1.5, color: theme.colorScheme.outline)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => onOpen(c),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.title, style: theme.textTheme.titleMedium),
                          Text(
                            c.completion >= 1
                                ? 'finished'
                                : c.enrolled
                                    ? '${(c.completion * 100).round()}% done'
                                    : c.level,
                            style: theme.textTheme.bodySmall,
                          ),
                        ]),
                      ),
                      if (i == nextIndex) MarginNote('you are here', size: 18),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}
