import 'package:flutter/material.dart';
import '../../backend/api_client.dart';
import '../../model/chat_message_model.dart';
import '../../repository/chat_repository.dart';
import '../../widgets/notebook/notebook.dart';

const _starters = [
  'Explain this topic as if I were new to it.',
  'Give me a worked example, step by step.',
  'Quiz me with three quick questions.',
  'What are the most common mistakes here?',
];

/// The AI tutor: a notebook page where your questions are written in ink and
/// the tutor's answers appear as annotated notes. Past conversations sit in
/// the margin.
class AITutorChatScreen extends StatefulWidget {
  final bool embedded;

  /// Lesson the student came from, passed to the tutor as context.
  final String? contextTitle;

  const AITutorChatScreen({super.key, this.embedded = false, this.contextTitle});

  @override
  State<AITutorChatScreen> createState() => _AITutorChatScreenState();
}

class _AITutorChatScreenState extends State<AITutorChatScreen> {
  final _repo = ChatRepository();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  List<ChatSessionModel> _sessions = [];
  String? _sessionId;
  List<ChatMessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _repo.listSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _open(String id) async {
    setState(() {
      _sessionId = id;
      _messages = [];
      _error = null;
      _loading = true;
    });
    try {
      final msgs = await _repo.history(id);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _toBottom();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  void _newConversation() => setState(() {
        _sessionId = null;
        _messages = [];
        _error = null;
      });

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _sending = true;
      _error = null;
      _messages = [
        ..._messages,
        ChatMessageModel(messageId: 'pending', userId: '', role: 'user', content: text, timestamp: DateTime.now()),
      ];
    });
    _toBottom();
    try {
      final id = _sessionId ?? await _repo.createSession();
      final reply = await _repo.send(id, text, context: widget.contextTitle);
      if (!mounted) return;
      final isNew = _sessionId == null;
      setState(() {
        _sessionId = id;
        _messages = [..._messages, reply];
        _sending = false;
      });
      if (isNew) _loadSessions();
      _toBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        // Put the question back so the student doesn't lose it.
        _messages = _messages.where((m) => m.messageId != 'pending').toList();
        _input.text = text;
        _sending = false;
        _error = e.message;
      });
    }
  }

  Future<void> _delete(ChatSessionModel s) async {
    try {
      await _repo.delete(s.sessionId);
      if (_sessionId == s.sessionId) _newConversation();
      await _loadSessions();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 1000;
    final page = Row(children: [
      if (wide) SizedBox(width: 260, child: _history()),
      Expanded(child: _conversation(showHistoryButton: !wide)),
    ]);
    if (widget.embedded) return page;
    return NotebookPage(title: 'AI tutor', body: page);
  }

  Widget _history({bool inSheet = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 8, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MarginNote('past conversations', size: 20),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            if (inSheet) Navigator.pop(context);
            _newConversation();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New question'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _sessions.isEmpty
              ? Text('Nothing yet — your conversations will be kept here.', style: theme.textTheme.bodySmall)
              : ListView(children: [
                  for (final s in _sessions)
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 4),
                      selected: s.sessionId == _sessionId,
                      title: Text(s.title ?? 'Conversation', maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(timeAgo(s.updatedAt ?? s.createdAt)),
                      trailing: IconButton(
                        tooltip: 'Delete conversation',
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => _delete(s),
                      ),
                      onTap: () {
                        if (inSheet) Navigator.pop(context);
                        _open(s.sessionId);
                      },
                    ),
                ]),
        ),
      ]),
    );
  }

  Widget _conversation({required bool showHistoryButton}) {
    final theme = Theme.of(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
        child: Row(children: [
          Expanded(child: Text('Ask the tutor', style: theme.textTheme.headlineMedium)),
          if (showHistoryButton)
            IconButton(
              tooltip: 'Past conversations',
              icon: const Icon(Icons.history),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                backgroundColor: NotebookColors.of(context).sheet,
                builder: (_) => SizedBox(height: 420, child: _history(inSheet: true)),
              ),
            ),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _messages.isEmpty && !_sending
                ? _emptyPage()
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    children: [
                      for (final m in _messages) _Message(m),
                      if (_sending) Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: MarginNote('the tutor is thinking…', size: 20),
                      ),
                    ],
                  ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: NoteCard(
            color: theme.colorScheme.errorContainer,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
            ]),
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(hintText: 'Write your question…'),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.arrow_upward),
          ),
        ]),
      ),
    ]);
  }

  Widget _emptyPage() {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.all(24), children: [
      const Center(child: NotebookMark(size: 140)),
      const SizedBox(height: 16),
      Center(
        child: Text(
          widget.contextTitle == null
              ? "Ask anything about what you're learning."
              : 'Ask anything about "${widget.contextTitle}".',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 4),
      const Center(child: MarginNote('it explains, then checks you understood', tilt: 0, size: 18)),
      const SizedBox(height: 24),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [for (final s in _starters) ActionChip(label: Text(s), onPressed: () => _send(s))],
      ),
    ]);
  }
}

class _Message extends StatelessWidget {
  final ChatMessageModel m;
  const _Message(this.m);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    if (m.role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 48),
            child: NoteCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(m.content, style: theme.textTheme.bodyLarge),
            ),
          ),
        ),
      );
    }
    // Tutor replies: a red margin rule and a handwritten "Tutor" label.
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, right: 24),
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(border: Border(left: BorderSide(color: nb.marginLine, width: 2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MarginNote('Tutor', size: 20, tilt: 0),
          const SizedBox(height: 4),
          NoteText(m.content),
        ]),
      ),
    );
  }
}
