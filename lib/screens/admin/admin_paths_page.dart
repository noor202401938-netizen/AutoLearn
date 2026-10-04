import 'package:flutter/material.dart';
import '../../backend/api_client.dart';
import '../../model/course_model.dart';
import '../../repository/community_repository.dart';
import '../../repository/course_repository.dart';
import '../../widgets/notebook/notebook.dart';

/// Curate learning paths: an ordered list of courses with a description.
class AdminPathsPage extends StatefulWidget {
  const AdminPathsPage({super.key});

  @override
  State<AdminPathsPage> createState() => _AdminPathsPageState();
}

class _AdminPathsPageState extends State<AdminPathsPage> {
  List<LearningPath>? _paths;
  List<CourseModel> _courses = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([CommunityRepository().learningPaths(), CourseRepository().getAllCourses()]);
      if (!mounted) return;
      setState(() {
        _paths = results[0] as List<LearningPath>;
        _courses = results[1] as List<CourseModel>;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _edit([LearningPath? p]) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _PathDialog(path: p, courses: _courses));
    if (saved == true) _load();
  }

  Future<void> _delete(LearningPath p) async {
    try {
      await ApiClient.instance.json('DELETE', '/learning-paths/${p.id}');
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_error != null) return NotebookError(message: _error!, onRetry: _load);
    final paths = _paths;
    return ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Learning paths', style: theme.textTheme.displaySmall),
            const MarginNote('string courses together in order'),
          ]),
        ),
        ElevatedButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('New path')),
      ]),
      const SizedBox(height: 24),
      if (paths == null)
        const Center(child: CircularProgressIndicator())
      else if (paths.isEmpty)
        NotebookEmpty(title: 'No paths yet', note: 'a path is just an ordered list of courses', actionLabel: 'New path', onAction: _edit)
      else
        for (final p in paths) ...[
          NoteCard(
            onTap: () => _edit(p),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.level.toUpperCase(), style: theme.textTheme.labelSmall),
                  Text(p.title, style: theme.textTheme.titleLarge),
                  Text(p.courses.map((c) => c.title).join('  →  '), style: theme.textTheme.bodySmall),
                ]),
              ),
              IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(p)),
            ]),
          ),
          const SizedBox(height: 12),
        ],
    ]);
  }
}

class _PathDialog extends StatefulWidget {
  final LearningPath? path;
  final List<CourseModel> courses;
  const _PathDialog({this.path, required this.courses});

  @override
  State<_PathDialog> createState() => _PathDialogState();
}

class _PathDialogState extends State<_PathDialog> {
  late final _title = TextEditingController(text: widget.path?.title);
  late final _description = TextEditingController(text: widget.path?.description);
  late final _skills = TextEditingController(text: widget.path?.skills.join(', '));
  late String _level = widget.path?.level ?? 'beginner';
  late final List<String> _ids = [...?widget.path?.courses.map((c) => c.courseId)];
  String? _error;

  String _name(String id) => widget.courses.firstWhere((c) => c.courseId == id, orElse: () => widget.courses.first).title;

  Future<void> _save() async {
    final body = {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'level': _level,
      'skills': _skills.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'courseIds': _ids,
    };
    try {
      if (widget.path == null) {
        await ApiClient.instance.json('POST', '/learning-paths', body: body);
      } else {
        await ApiClient.instance.json('PUT', '/learning-paths/${widget.path!.id}', body: body);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.courses.where((c) => !_ids.contains(c.courseId)).toList();
    return AlertDialog(
      title: Text(widget.path == null ? 'New learning path' : 'Edit learning path'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: _description, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Who is it for, and where does it lead?')),
            const SizedBox(height: 12),
            TextField(controller: _skills, decoration: const InputDecoration(labelText: 'Skills (comma separated)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Level'),
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
              ],
              onChanged: (v) => _level = v!,
            ),
            const SizedBox(height: 16),
            Text('Courses, in order', style: Theme.of(context).textTheme.titleSmall),
            ReorderableListView(
              shrinkWrap: true,
              buildDefaultDragHandles: true,
              onReorder: (a, b) => setState(() => _ids.insert(b > a ? b - 1 : b, _ids.removeAt(a))),
              children: [
                for (final (i, id) in _ids.indexed)
                  ListTile(
                    key: ValueKey(id),
                    leading: Text('${i + 1}.'),
                    title: Text(_name(id)),
                    trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _ids.remove(id))),
                  ),
              ],
            ),
            if (available.isNotEmpty)
              DropdownButton<String>(
                hint: const Text('Add a course…'),
                isExpanded: true,
                value: null,
                items: [for (final c in available) DropdownMenuItem(value: c.courseId, child: Text(c.title))],
                onChanged: (v) => setState(() => _ids.add(v!)),
              ),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
