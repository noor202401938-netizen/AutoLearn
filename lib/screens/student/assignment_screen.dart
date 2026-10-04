import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../backend/api_client.dart';
import '../../model/quiz_model.dart';
import '../../repository/quiz_repository.dart';
import '../../widgets/notebook/notebook.dart';

/// An assignment brief, a page to write the answer on, and — once handed in —
/// the marked work with feedback in the margin.
class AssignmentScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String moduleId;
  final String moduleTitle;
  final String lessonId;
  final String lessonTitle;

  const AssignmentScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.moduleId,
    required this.moduleTitle,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final _repo = QuizRepository();
  final _answer = TextEditingController();

  AssignmentModel? _assignment;
  AssignmentSubmissionModel? _submission;
  bool _loading = true;
  bool _editing = false;
  bool _submitting = false;
  String? _error;
  String? _fileUrl;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final a = await _repo.getAssignmentForLesson(widget.lessonId);
      final sub = a == null ? null : await _repo.getAssignmentSubmission(a.assignmentId);
      if (!mounted) return;
      setState(() {
        _assignment = a;
        _submission = sub;
        _answer.text = sub?.content ?? '';
        _fileUrl = sub?.fileUrl;
        _fileName = sub?.fileUrl?.split('/').last;
        _editing = sub == null;
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

  Future<void> _attach() async {
    final picked = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'csv', 'xls', 'xlsx', 'png', 'jpg', 'jpeg'],
    );
    final file = picked?.files.single;
    if (file?.bytes == null) return;
    try {
      final url = await ApiClient.instance.upload(file!.bytes!, file.name);
      if (mounted) {
        setState(() {
          _fileUrl = url;
          _fileName = file.name;
        });
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _submit() async {
    if (_answer.text.trim().isEmpty && _fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write your answer or attach a file first')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final sub = await _repo.submitAssignment(_assignment!.assignmentId, content: _answer.text.trim(), fileUrl: _fileUrl);
      if (!mounted) return;
      setState(() {
        _submission = sub;
        _editing = false;
        _submitting = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = NotebookError(message: _error!, onRetry: _load);
    } else if (_assignment == null) {
      body = const NotebookEmpty(
        title: 'No brief has been set for this lesson yet',
        note: "your instructor hasn't written it — check back soon",
      );
    } else {
      body = _page();
    }
    return NotebookPage(title: widget.lessonTitle, body: body);
  }

  Widget _page() {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final a = _assignment!;
    final overdue = a.dueDate.isBefore(DateTime.now());
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 48), children: [
          Text(widget.courseTitle.toUpperCase(), style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(a.title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Wrap(spacing: 16, children: [
            MarginNote('due ${DateFormat('EEE d MMM').format(a.dueDate)}${overdue ? ' — overdue' : ''}', size: 19),
            MarginNote('${a.maxPoints} points', size: 19, color: theme.colorScheme.onSurfaceVariant),
          ]),
          const SizedBox(height: 20),
          NoteCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('The brief', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (a.description.isNotEmpty) NoteText(a.description),
              NoteText(a.instructions.isEmpty ? 'No further instructions.' : a.instructions),
            ]),
          ),
          const SizedBox(height: 28),
          if (_editing) ..._editor() else ..._marked(nb),
        ]),
      ),
    );
  }

  List<Widget> _editor() {
    final theme = Theme.of(context);
    return [
      const NoteHeading('Your answer'),
      const SizedBox(height: 12),
      TextField(
        controller: _answer,
        minLines: 10,
        maxLines: 30,
        decoration: const InputDecoration(hintText: 'Show your reasoning — diagrams in words are fine.'),
      ),
      const SizedBox(height: 12),
      Row(children: [
        TextButton.icon(onPressed: _attach, icon: const Icon(Icons.attach_file), label: Text(_fileName ?? 'Attach a file')),
        if (_fileName != null)
          IconButton(
            tooltip: 'Remove file',
            onPressed: () => setState(() {
              _fileUrl = null;
              _fileName = null;
            }),
            icon: const Icon(Icons.close, size: 18),
          ),
        const Spacer(),
        if (_submission != null)
          TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel')),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Hand it in'),
        ),
      ]),
      if (_submitting) ...[
        const SizedBox(height: 8),
        Text('Marking can take up to a minute.', style: theme.textTheme.bodySmall),
      ],
    ];
  }

  List<Widget> _marked(NotebookColors nb) {
    final theme = Theme.of(context);
    final s = _submission!;
    return [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const NoteHeading('Handed in'),
        const SizedBox(width: 12),
        Padding(padding: const EdgeInsets.only(bottom: 6), child: MarginNote(timeAgo(s.submittedAt), size: 18)),
        const Spacer(),
        if (s.isGraded && s.score != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: nb.annotation, width: 2),
              borderRadius: const BorderRadius.all(Radius.elliptical(50, 30)),
            ),
            child: Text('${s.score}/${_assignment!.maxPoints}', style: nb.hand(size: 30)),
          ),
      ]),
      const SizedBox(height: 14),
      NoteCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (s.content.isNotEmpty) Text(s.content, style: theme.textTheme.bodyLarge),
          if (s.fileUrl != null)
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(ApiClient.baseUrl.replaceFirst(RegExp(r'/api/?$'), '') + s.fileUrl!)),
              icon: const Icon(Icons.description_outlined),
              label: Text(s.fileUrl!.split('/').last),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      if ((s.feedback ?? '').isNotEmpty)
        Container(
          padding: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: nb.marginLine, width: 2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MarginNote('Feedback', size: 21, tilt: 0),
            const SizedBox(height: 4),
            NoteText(s.feedback!),
          ]),
        )
      else
        MarginNote(s.gradingNote ?? 'waiting to be marked', size: 19, tilt: 0),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _editing = true),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Revise and resubmit'),
        ),
      ),
    ];
  }
}
