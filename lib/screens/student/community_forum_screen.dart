import 'dart:async';
import 'package:flutter/material.dart';
import '../../backend/api_client.dart';
import '../../repository/auth_repository.dart';
import '../../repository/community_repository.dart';
import '../../widgets/notebook/notebook.dart';

const _categories = ['all', 'course questions', 'study help', 'assignments', 'resources', 'general'];

/// Study-group forum: questions, answers, upvotes, and an accepted answer.
class CommunityForumScreen extends StatefulWidget {
  final bool embedded;
  const CommunityForumScreen({super.key, this.embedded = false});

  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen> {
  final _repo = CommunityRepository();
  List<ForumThread>? _threads;
  String? _error;
  String _category = 'all';
  String _sort = 'new';
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final t = await _repo.threads(category: _category, query: _query, sort: _sort);
      if (mounted) setState(() => _threads = t);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _ask() async {
    final created = await showDialog<ForumThread>(context: context, builder: (_) => const _AskDialog());
    if (created != null) {
      _load();
      if (mounted) _openThread(created.id);
    }
  }

  Future<void> _openThread(String id) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _ThreadPage(threadId: id)));
    _load();
  }

  Future<void> _vote(ForumThread t) async {
    try {
      final (n, mine) = await _repo.toggleThreadVote(t.id);
      if (mounted) {
        setState(() {
          t.upvotes = n;
          t.upvotedByMe = mine;
        });
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 96), children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Study group', style: theme.textTheme.displaySmall),
            const MarginNote('ask, answer, learn from each other'),
          ]),
        ),
        ElevatedButton.icon(onPressed: _ask, icon: const Icon(Icons.edit_outlined), label: const Text('Ask a question')),
      ]),
      const SizedBox(height: 20),
      TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search questions'),
        onChanged: (v) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 350), () {
            _query = v.trim();
            _load();
          });
        },
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final c in _categories)
          ChoiceChip(
            label: Text(c),
            selected: _category == c,
            onSelected: (_) {
              setState(() => _category = c);
              _load();
            },
          ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _sort,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'new', child: Text('Newest')),
            DropdownMenuItem(value: 'top', child: Text('Most upvoted')),
            DropdownMenuItem(value: 'unanswered', child: Text('Unanswered')),
          ],
          onChanged: (v) {
            setState(() => _sort = v!);
            _load();
          },
        ),
      ]),
      const SizedBox(height: 20),
      if (_error != null)
        NotebookError(message: _error!, onRetry: _load)
      else if (_threads == null)
        const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
      else if (_threads!.isEmpty)
        NotebookEmpty(
          title: _query.isEmpty ? 'No questions here yet' : 'Nothing matches "$_query"',
          note: 'be the first to ask',
          actionLabel: 'Ask a question',
          onAction: _ask,
        )
      else
        for (final t in _threads!) ...[
          _ThreadRow(thread: t, onTap: () => _openThread(t.id), onVote: () => _vote(t)),
          const SizedBox(height: 12),
        ],
    ]);
    final content = RefreshIndicator(onRefresh: _load, child: list);
    return widget.embedded ? content : NotebookPage(title: 'Study group', body: content);
  }
}

class _VoteTally extends StatelessWidget {
  final int count;
  final bool mine;
  final VoidCallback onTap;
  const _VoteTally({required this.count, required this.mine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    return Semantics(
      button: true,
      selected: mine,
      label: 'Upvote, $count ${count == 1 ? 'vote' : 'votes'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(children: [
            Icon(mine ? Icons.thumb_up : Icons.thumb_up_outlined, size: 18, color: mine ? nb.annotation : theme.colorScheme.onSurfaceVariant),
            Text('$count', style: NotebookColors.figures(size: 14, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          ]),
        ),
      ),
    );
  }
}

class _AuthorLine extends StatelessWidget {
  final ForumAuthor author;
  final DateTime at;
  const _AuthorLine(this.author, this.at);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
      Text(author.name, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface)),
      if (author.isStaff) Highlight('instructor', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface)),
      Text('· ${timeAgo(at)}', style: theme.textTheme.bodySmall),
    ]);
  }
}

class _ThreadRow extends StatelessWidget {
  final ForumThread thread;
  final VoidCallback onTap;
  final VoidCallback onVote;
  const _ThreadRow({required this.thread, required this.onTap, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final t = thread;
    return NoteCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(10, 14, 18, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _VoteTally(count: t.upvotes, mine: t.upvotedByMe, onTap: onVote),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.category.toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(t.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(t.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            _AuthorLine(t.author, t.createdAt),
          ]),
        ),
        const SizedBox(width: 12),
        Column(children: [
          Text('${t.replyCount}', style: NotebookColors.figures(size: 18, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          Text(t.replyCount == 1 ? 'reply' : 'replies', style: theme.textTheme.bodySmall),
          if (t.acceptedReplyId != null) Text('✓ answered', style: nb.hand(size: 17, color: nb.correct)),
        ]),
      ]),
    );
  }
}

class _AskDialog extends StatefulWidget {
  const _AskDialog();

  @override
  State<_AskDialog> createState() => _AskDialogState();
}

class _AskDialogState extends State<_AskDialog> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _category = 'course questions';
  bool _saving = false;
  String? _error;

  Future<void> _post() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final t = await CommunityRepository().createThread(title: _title.text.trim(), body: _body.text.trim(), category: _category);
      if (mounted) Navigator.pop(context, t);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Ask the study group'),
        content: SizedBox(
          width: 520,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Your question in one line')),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Details — what have you tried, where are you stuck?'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Topic'),
              items: [for (final c in _categories.skip(1)) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => _category = v!,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _saving ? null : _post, child: const Text('Post question')),
        ],
      );
}

class _ThreadPage extends StatefulWidget {
  final String threadId;
  const _ThreadPage({required this.threadId});

  @override
  State<_ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<_ThreadPage> {
  final _repo = CommunityRepository();
  final _reply = TextEditingController();
  ForumThread? _thread;
  String? _error;
  String? _me;
  bool _isAdmin = false;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final user = await AuthRepository().getCurrentUser();
      final t = await _repo.thread(widget.threadId);
      if (!mounted) return;
      setState(() {
        _me = user?['uid'] as String?;
        _isAdmin = user?['role'] == 'admin';
        _thread = t;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _post() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await _repo.reply(widget.threadId, text);
      _reply.clear();
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    if (mounted) setState(() => _posting = false);
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _thread;
    final Widget body;
    if (_error != null) {
      body = NotebookError(message: _error!, onRetry: _load);
    } else if (t == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = _page(t);
    }
    final canDelete = t != null && (t.author.id == _me || _isAdmin);
    return NotebookPage(
      title: 'Study group',
      actions: [
        if (canDelete)
          IconButton(
            tooltip: 'Delete question',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _run(() async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Delete this question?'),
                  content: const Text('The question and all its replies will be removed.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok != true) return;
              await _repo.deleteThread(t.id);
              if (mounted) Navigator.pop(context);
            }),
          ),
      ],
      body: body,
    );
  }

  Widget _page(ForumThread t) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final canAccept = t.author.id == _me || _isAdmin;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 48), children: [
          Text(t.category.toUpperCase(), style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(t.title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          _AuthorLine(t.author, t.createdAt),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _VoteTally(
              count: t.upvotes,
              mine: t.upvotedByMe,
              onTap: () => _run(() async {
                final (n, mine) = await _repo.toggleThreadVote(t.id);
                setState(() {
                  t.upvotes = n;
                  t.upvotedByMe = mine;
                });
              }),
            ),
            const SizedBox(width: 12),
            Expanded(child: NoteText(t.body)),
          ]),
          const SizedBox(height: 28),
          NoteHeading('${t.replies.length} ${t.replies.length == 1 ? 'reply' : 'replies'}'),
          const SizedBox(height: 14),
          for (final r in t.replies) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: r.accepted ? nb.correct : theme.colorScheme.outlineVariant, width: r.accepted ? 3 : 1.5)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _VoteTally(
                  count: r.upvotes,
                  mine: r.upvotedByMe,
                  onTap: () => _run(() async {
                    final (n, mine) = await _repo.toggleReplyVote(r.id);
                    setState(() {
                      r.upvotes = n;
                      r.upvotedByMe = mine;
                    });
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (r.accepted) MarginNote('✓ accepted answer', size: 19, tilt: 0, color: nb.correct),
                    _AuthorLine(r.author, r.createdAt),
                    const SizedBox(height: 6),
                    NoteText(r.body, style: theme.textTheme.bodyLarge),
                    if (canAccept)
                      TextButton(
                        onPressed: () => _run(() async {
                          await _repo.acceptReply(t.id, r.id);
                          await _load();
                        }),
                        child: Text(r.accepted ? 'Un-accept' : 'Accept as the answer'),
                      ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _reply,
            minLines: 3,
            maxLines: 10,
            decoration: const InputDecoration(hintText: 'Write a reply — explain your reasoning'),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(onPressed: _posting ? null : _post, child: const Text('Post reply')),
          ),
        ]),
      ),
    );
  }
}
