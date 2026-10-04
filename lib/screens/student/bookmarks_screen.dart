import 'package:flutter/material.dart';
import '../../backend/api_client.dart';
import '../../repository/community_repository.dart';
import '../../widgets/notebook/notebook.dart';
import 'course_content_screen.dart';

/// Saved courses, lessons and video moments, laid out like index cards.
class BookmarksScreen extends StatefulWidget {
  final bool embedded;
  const BookmarksScreen({super.key, this.embedded = false});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _repo = CommunityRepository();
  List<Bookmark>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await _repo.bookmarks();
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _remove(Bookmark b) async {
    setState(() => _items = _items!.where((x) => x.id != b.id).toList());
    try {
      await _repo.deleteBookmark(b.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _body();
    return widget.embedded ? content : NotebookPage(title: 'Bookmarks', body: content);
  }

  Widget _body() {
    if (_error != null) return NotebookError(message: _error!, onRetry: _load);
    final items = _items;
    if (items == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final byCourse = <String, List<Bookmark>>{};
    for (final b in items) {
      byCourse.putIfAbsent(b.courseTitle, () => []).add(b);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
        Text('Bookmarks', style: theme.textTheme.displaySmall),
        const MarginNote('the pages you folded down'),
        const SizedBox(height: 24),
        if (items.isEmpty)
          const NotebookEmpty(
            title: 'No bookmarks yet',
            note: 'tap the bookmark icon on any course, lesson or video moment',
          ),
        for (final entry in byCourse.entries) ...[
          NoteHeading(entry.key),
          const SizedBox(height: 14),
          Wrap(spacing: 16, runSpacing: 16, children: [
            for (final b in entry.value) SizedBox(width: 300, child: _card(b)),
          ]),
          const SizedBox(height: 32),
        ],
      ]),
    );
  }

  Widget _card(Bookmark b) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final pos = b.positionSeconds;
    final kind = pos != null ? 'video moment' : (b.lessonId != null ? 'lesson' : 'course');
    return NoteCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseContentScreen(courseId: b.courseId, title: b.courseTitle, initialLessonId: b.lessonId),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(kind.toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 6),
            Text(b.title, style: theme.textTheme.titleMedium),
            if (pos != null)
              Text('at ${pos ~/ 60}:${(pos % 60).toString().padLeft(2, '0')}',
                  style: NotebookColors.figures(size: 13, color: theme.colorScheme.onSurfaceVariant)),
            if ((b.note ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(b.note!, style: nb.hand(size: 18)),
            ],
            const SizedBox(height: 6),
            Text('saved ${timeAgo(b.createdAt)}', style: theme.textTheme.bodySmall),
          ]),
        ),
        IconButton(tooltip: 'Remove bookmark', icon: const Icon(Icons.bookmark_remove_outlined), onPressed: () => _remove(b)),
      ]),
    );
  }
}
