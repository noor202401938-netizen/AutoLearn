// Course authoring for admins: the course list, and one editor page for a
// course's details, its syllabus, and each lesson's quiz or assignment brief.
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/api_client.dart';
import '../../backend/xml_course_parser.dart';
import '../../model/course_model.dart';
import '../../model/quiz_model.dart';
import '../../repository/course_repository.dart';
import '../../repository/quiz_repository.dart';
import '../../widgets/notebook/notebook.dart';

const _lessonTypes = {
  'reading': Icons.article_outlined,
  'video': Icons.play_circle_outline,
  'quiz': Icons.quiz_outlined,
  'assignment': Icons.assignment_outlined,
  'project': Icons.construction_outlined,
};

bool _saved(String id) => RegExp(r'^[a-f0-9]{24}$').hasMatch(id);

// ── Course list ──────────────────────────────────────────────────────────────

class AdminCoursesPage extends StatefulWidget {
  const AdminCoursesPage({super.key});

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  final _repo = CourseRepository();
  List<CourseModel>? _courses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _repo.getAllCourses();
    if (mounted) setState(() => _courses = c);
  }

  Future<void> _edit([CourseModel? c]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CourseEditorPage(course: c)));
    _load();
  }

  Future<void> _togglePublished(CourseModel c) async {
    final ok = await _repo.updateCourse(c.courseId, c.copyWith(isPublished: !c.isPublished));
    if (ok == null && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't update the course")));
    _load();
  }

  Future<void> _delete(CourseModel c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Delete "${c.title}"?'),
        content: const Text('Its lessons, quizzes, student progress and enrolments will be removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Keep it')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) {
      await _repo.deleteCourse(c.courseId);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courses = _courses;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Courses', style: theme.textTheme.displaySmall),
              const MarginNote('write, organise and publish'),
            ]),
          ),
          ElevatedButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('New course')),
        ]),
        const SizedBox(height: 24),
        if (courses == null)
          const Center(child: CircularProgressIndicator())
        else if (courses.isEmpty)
          NotebookEmpty(title: 'No courses yet', note: 'start with a blank one or import XML', actionLabel: 'New course', onAction: _edit)
        else
          for (final c in courses) ...[
            NoteCard(
              onTap: () => _edit(c),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(c.category.toUpperCase(), style: theme.textTheme.labelSmall),
                      const SizedBox(width: 10),
                      c.isPublished
                          ? Highlight('published', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface))
                          : Text('draft', style: NotebookColors.of(context).hand(size: 16)),
                    ]),
                    const SizedBox(height: 4),
                    Text(c.title, style: theme.textTheme.titleLarge),
                    Text(
                      '${c.syllabus.length} chapters · ${c.syllabus.fold<int>(0, (n, m) => n + m.lessons.length)} lessons · '
                      '${c.enrollmentCount} enrolled${c.ratingCount > 0 ? ' · ★ ${c.rating.toStringAsFixed(1)}' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ]),
                ),
                TextButton(onPressed: () => _togglePublished(c), child: Text(c.isPublished ? 'Unpublish' : 'Publish')),
                IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(c)),
              ]),
            ),
            const SizedBox(height: 12),
          ],
      ]),
    );
  }
}

// ── Editor ───────────────────────────────────────────────────────────────────

class _Lesson {
  String id, title, type;
  int duration;
  String videoURL, content;
  _Lesson({this.id = '', this.title = '', this.type = 'reading', this.duration = 10, this.videoURL = '', this.content = ''});
  _Lesson.from(LessonModel l)
      : id = l.lessonId,
        title = l.title,
        type = l.type,
        duration = l.duration,
        videoURL = l.videoURL ?? '',
        content = l.content ?? '';
  LessonModel toModel() => LessonModel(
        lessonId: id,
        title: title,
        duration: duration,
        type: type,
        videoURL: videoURL.isEmpty ? null : videoURL,
        content: content.isEmpty ? null : content,
      );
}

class _Chapter {
  String id;
  final TextEditingController title;
  final List<_Lesson> lessons;
  _Chapter({this.id = '', String title = '', List<_Lesson>? lessons})
      : title = TextEditingController(text: title),
        lessons = lessons ?? [];
}

class CourseEditorPage extends StatefulWidget {
  final CourseModel? course;
  const CourseEditorPage({super.key, this.course});

  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends State<CourseEditorPage> {
  final _repo = CourseRepository();
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.course?.title);
  late final _description = TextEditingController(text: widget.course?.description);
  late final _instructor = TextEditingController(text: widget.course?.instructor ?? '');
  late final _category = TextEditingController(text: widget.course?.category ?? 'Microeconomics');
  late final _hours = TextEditingController(text: '${widget.course?.duration ?? 0}');
  late final _price = TextEditingController(text: (widget.course?.price ?? 0).toStringAsFixed(2));
  late String _level = widget.course?.level ?? 'beginner';
  late bool _published = widget.course?.isPublished ?? false;
  late CourseModel? _course = widget.course;
  late List<_Chapter> _chapters = [
    for (final m in widget.course?.syllabus ?? <ModuleModel>[])
      _Chapter(id: m.moduleId, title: m.title, lessons: m.lessons.map(_Lesson.from).toList()),
  ];
  bool _saving = false;
  bool _dirty = false;

  void _touch(VoidCallback f) => setState(() {
        f();
        _dirty = true;
      });

  CourseModel _build() {
    final now = DateTime.now();
    return CourseModel(
      courseId: _course?.courseId ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      instructor: _instructor.text.trim().isEmpty ? 'AutoLearn Faculty' : _instructor.text.trim(),
      category: _category.text.trim().isEmpty ? 'General' : _category.text.trim(),
      level: _level,
      duration: int.tryParse(_hours.text) ?? 0,
      thumbnailURL: _course?.thumbnailURL ?? '',
      price: double.tryParse(_price.text) ?? 0,
      currency: _course?.currency ?? 'USD',
      isPublished: _published,
      createdAt: _course?.createdAt ?? now,
      createdBy: _course?.createdBy ?? '',
      syllabus: [
        for (final c in _chapters)
          ModuleModel(moduleId: c.id, title: c.title.text.trim(), lessons: c.lessons.map((l) => l.toModel()).toList()),
      ],
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final model = _build();
    final saved = _course == null ? await _repo.createCourse(model) : await _repo.updateCourse(_course!.courseId, model);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't save — check the details and try again")));
      return;
    }
    // Reload from the server so new chapters/lessons get their real ids.
    setState(() {
      _course = saved;
      _chapters = [
        for (final m in saved.syllabus) _Chapter(id: m.moduleId, title: m.title, lessons: m.lessons.map(_Lesson.from).toList()),
      ];
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  Future<void> _importXml() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xml'], withData: true);
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return;
    final xml = utf8.decode(bytes);
    if (!XmlCourseParser.validateXml(xml)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("That file isn't a valid course XML")));
      return;
    }
    final modules = XmlCourseParser.parseModulesFromXml(xml);
    _touch(() {
      // Imported items are new: blank ids so the server creates them.
      _chapters.addAll(modules.map((m) => _Chapter(
            title: m.title,
            lessons: m.lessons.map((l) => _Lesson.from(l)..id = '').toList(),
          )));
    });
  }

  Future<void> _editLesson(_Chapter ch, [_Lesson? lesson]) async {
    final result = await showDialog<_Lesson>(context: context, builder: (_) => _LessonDialog(lesson: lesson));
    if (result == null) return;
    _touch(() {
      if (lesson == null) ch.lessons.add(result);
    });
  }

  void _move<T>(List<T> list, int i, int by) {
    final j = i + by;
    if (j < 0 || j >= list.length) return;
    _touch(() => list.insert(j, list.removeAt(i)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Leave without saving?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Stay')),
              TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Discard changes')),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: NotebookPage(
        title: _course == null ? 'New course' : 'Edit course',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(onPressed: _saving ? null : _save, child: Text(_dirty || _course == null ? 'Save' : 'Saved')),
          ),
        ],
        body: Form(
          key: _form,
          onChanged: () => _dirty = true,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 64), children: [
                NoteCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    TextFormField(
                      controller: _title,
                      style: theme.textTheme.headlineSmall,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Give the course a title' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'What students will learn'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Add a short description' : null,
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      SizedBox(width: 260, child: TextFormField(controller: _instructor, decoration: const InputDecoration(labelText: 'Instructor'))),
                      SizedBox(width: 220, child: TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'Category'))),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: _level,
                          decoration: const InputDecoration(labelText: 'Level'),
                          items: const [
                            DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                            DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                            DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                          ],
                          onChanged: (v) => _touch(() => _level = v!),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: TextFormField(controller: _hours, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hours of study')),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: 'Price (${_course?.currency ?? 'USD'})', helperText: '0 = free'),
                          validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? 'Enter a price' : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Published'),
                      subtitle: const Text('Students can see and enrol in published courses'),
                      value: _published,
                      onChanged: (v) => _touch(() => _published = v),
                    ),
                  ]),
                ),
                const SizedBox(height: 32),
                NoteHeading('Syllabus', trailing: Wrap(spacing: 8, children: [
                  TextButton.icon(onPressed: _importXml, icon: const Icon(Icons.upload_file, size: 18), label: const Text('Import XML')),
                  OutlinedButton.icon(
                    onPressed: () => _touch(() => _chapters.add(_Chapter(title: 'Chapter ${_chapters.length + 1}'))),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Chapter'),
                  ),
                ])),
                const SizedBox(height: 14),
                if (_chapters.isEmpty) const NotebookEmpty(title: 'No chapters yet', note: 'add one, or import an XML syllabus'),
                for (final (ci, ch) in _chapters.indexed) ...[
                  NoteCard(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                    child: Column(children: [
                      Row(children: [
                        Text('${ci + 1}.', style: theme.textTheme.titleLarge),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: ch.title,
                            style: theme.textTheme.titleLarge,
                            decoration: const InputDecoration(hintText: 'Chapter title', filled: false, border: InputBorder.none),
                            onChanged: (_) => _dirty = true,
                          ),
                        ),
                        IconButton(tooltip: 'Move up', icon: const Icon(Icons.arrow_upward, size: 18), onPressed: () => _move(_chapters, ci, -1)),
                        IconButton(tooltip: 'Move down', icon: const Icon(Icons.arrow_downward, size: 18), onPressed: () => _move(_chapters, ci, 1)),
                        IconButton(tooltip: 'Delete chapter', icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => _touch(() => _chapters.removeAt(ci))),
                      ]),
                      for (final (li, l) in ch.lessons.indexed)
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 8),
                          leading: Icon(_lessonTypes[l.type] ?? Icons.circle_outlined),
                          title: Text(l.title.isEmpty ? 'Untitled lesson' : l.title),
                          subtitle: Text('${l.type}${l.duration > 0 ? ' · ${l.duration} min' : ''}'),
                          onTap: () => _editLesson(ch, l),
                          trailing: Wrap(children: [
                            if ({'quiz', 'assignment', 'project'}.contains(l.type))
                              TextButton(
                                onPressed: _saved(l.id) && !_dirty
                                    ? () => showDialog<void>(
                                          context: context,
                                          builder: (_) => l.type == 'quiz'
                                              ? _QuizDialog(course: _course!, moduleId: ch.id, lesson: l)
                                              : _BriefDialog(course: _course!, moduleId: ch.id, lesson: l),
                                        )
                                    : null,
                                child: Text(l.type == 'quiz' ? 'Questions' : 'Brief'),
                              ),
                            IconButton(tooltip: 'Move up', icon: const Icon(Icons.arrow_upward, size: 18), onPressed: () => _move(ch.lessons, li, -1)),
                            IconButton(tooltip: 'Move down', icon: const Icon(Icons.arrow_downward, size: 18), onPressed: () => _move(ch.lessons, li, 1)),
                            IconButton(tooltip: 'Delete lesson', icon: const Icon(Icons.close, size: 18), onPressed: () => _touch(() => ch.lessons.removeAt(li))),
                          ]),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(onPressed: () => _editLesson(ch), icon: const Icon(Icons.add, size: 18), label: const Text('Lesson')),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],
                if (_dirty && _chapters.any((c) => c.lessons.any((l) => {'quiz', 'assignment', 'project'}.contains(l.type))))
                  const MarginNote('save first, then write quiz questions and assignment briefs', tilt: 0, size: 18),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonDialog extends StatefulWidget {
  final _Lesson? lesson;
  const _LessonDialog({this.lesson});

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  late final _l = widget.lesson ?? _Lesson();
  late final _title = TextEditingController(text: _l.title);
  late final _minutes = TextEditingController(text: '${_l.duration}');
  late final _video = TextEditingController(text: _l.videoURL);
  late final _content = TextEditingController(text: _l.content);
  late String _type = _l.type;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.lesson == null ? 'New lesson' : 'Edit lesson'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in _lessonTypes.keys)
                  ChoiceChip(avatar: Icon(_lessonTypes[t], size: 16), label: Text(t), selected: _type == t, onSelected: (_) => setState(() => _type = t)),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _minutes, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutes')),
              if (_type == 'video') ...[
                const SizedBox(height: 12),
                TextField(controller: _video, decoration: const InputDecoration(labelText: 'YouTube link')),
              ],
              if (_type == 'reading') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _content,
                  minLines: 8,
                  maxLines: 20,
                  decoration: const InputDecoration(
                    labelText: 'Lesson text',
                    helperText: 'Blank lines separate paragraphs. **bold**, *italic*, "- " for lists, "## " for headings.',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _l
                ..title = _title.text.trim()
                ..type = _type
                ..duration = int.tryParse(_minutes.text) ?? 0
                ..videoURL = _type == 'video' ? _video.text.trim() : ''
                ..content = _type == 'reading' ? _content.text : '';
              Navigator.pop(context, _l);
            },
            child: const Text('Done'),
          ),
        ],
      );
}

/// Multiple-choice quiz editor. Questions can be written by hand or drafted
/// by the AI and then edited.
class _QuizDialog extends StatefulWidget {
  final CourseModel course;
  final String moduleId;
  final _Lesson lesson;
  const _QuizDialog({required this.course, required this.moduleId, required this.lesson});

  @override
  State<_QuizDialog> createState() => _QuizDialogState();
}

class _Q {
  final text = TextEditingController();
  final options = List.generate(4, (_) => TextEditingController());
  final explanation = TextEditingController();
  int correct = 0;
}

class _QuizDialogState extends State<_QuizDialog> {
  final _repo = QuizRepository();
  final List<_Q> _questions = [];
  int _passing = 70;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _fill(QuizModel quiz) {
    _questions
      ..clear()
      ..addAll(quiz.questions.map((q) {
        final e = _Q()
          ..correct = q.correctOptionIndex.clamp(0, 3)
          ..text.text = q.questionText
          ..explanation.text = q.explanation ?? '';
        for (var i = 0; i < 4 && i < q.options.length; i++) {
          e.options[i].text = q.options[i].text;
        }
        return e;
      }));
    _passing = quiz.passingScore;
  }

  Future<void> _load() async {
    try {
      // Admins get the answer key back from this endpoint.
      _fill(QuizModel.fromMap(await ApiClient.instance.json('GET', '/quizzes/lesson/${widget.lesson.id}')));
    } on ApiException catch (e) {
      if (e.status != 404) _error = e.message;
      _questions.add(_Q());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _draftWithAi() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _fill(await _repo.getQuizForLesson(
        courseId: widget.course.courseId,
        moduleId: widget.moduleId,
        lessonId: widget.lesson.id,
        lessonTitle: widget.lesson.title,
      ));
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    final qs = _questions.where((q) => q.text.text.trim().isNotEmpty).toList();
    if (qs.isEmpty) {
      setState(() => _error = 'Write at least one question');
      return;
    }
    setState(() => _busy = true);
    try {
      await _repo.saveQuiz(QuizModel(
        quizId: '',
        courseId: widget.course.courseId,
        moduleId: widget.moduleId,
        lessonId: widget.lesson.id,
        title: widget.lesson.title,
        questions: [
          for (final (i, q) in qs.indexed)
            QuestionModel(
              questionId: 'q${i + 1}',
              questionText: q.text.text.trim(),
              type: QuestionType.multipleChoice,
              options: [
                for (final (j, o) in q.options.indexed)
                  if (o.text.trim().isNotEmpty) OptionModel(optionId: 'q${i + 1}o${j + 1}', text: o.text.trim()),
              ],
              correctOptionIndex: q.correct,
              explanation: q.explanation.text.trim().isEmpty ? null : q.explanation.text.trim(),
            ),
        ],
        timeLimit: qs.length * 2,
        passingScore: _passing,
        createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Quiz — ${widget.lesson.title}'),
      content: SizedBox(
        width: 720,
        child: _loading
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    OutlinedButton.icon(onPressed: _busy ? null : _draftWithAi, icon: const Icon(Icons.auto_awesome, size: 18), label: const Text('Draft with AI')),
                    const Spacer(),
                    Text('Pass mark', style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _passing,
                      items: [for (final p in [50, 60, 70, 80, 90]) DropdownMenuItem(value: p, child: Text('$p%'))],
                      onChanged: (v) => setState(() => _passing = v!),
                    ),
                  ]),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                  for (final (i, q) in _questions.indexed) ...[
                    const SizedBox(height: 20),
                    Row(children: [
                      Text('${i + 1}.', style: theme.textTheme.titleMedium),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: q.text, decoration: const InputDecoration(hintText: 'Question'))),
                      IconButton(tooltip: 'Remove question', icon: const Icon(Icons.close), onPressed: () => setState(() => _questions.removeAt(i))),
                    ]),
                    for (final (j, o) in q.options.indexed)
                      Row(children: [
                        Radio<int>(value: j, groupValue: q.correct, onChanged: (v) => setState(() => q.correct = v!)),
                        Expanded(
                          child: TextField(
                            controller: o,
                            decoration: InputDecoration(hintText: 'Option ${'abcd'[j]}${j == q.correct ? ' (correct)' : ''}', isDense: true),
                          ),
                        ),
                      ]),
                    TextField(controller: q.explanation, decoration: const InputDecoration(hintText: 'Why is it correct? (shown after submitting)', isDense: true)),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(onPressed: () => setState(() => _questions.add(_Q())), icon: const Icon(Icons.add), label: const Text('Question')),
                  ),
                ]),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _busy ? null : _save, child: const Text('Save quiz')),
      ],
    );
  }
}

/// Assignment/project brief editor.
class _BriefDialog extends StatefulWidget {
  final CourseModel course;
  final String moduleId;
  final _Lesson lesson;
  const _BriefDialog({required this.course, required this.moduleId, required this.lesson});

  @override
  State<_BriefDialog> createState() => _BriefDialogState();
}

class _BriefDialogState extends State<_BriefDialog> {
  final _repo = QuizRepository();
  final _summary = TextEditingController();
  final _instructions = TextEditingController();
  final _points = TextEditingController(text: '100');
  DateTime _due = DateTime.now().add(const Duration(days: 14));
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final a = await _repo.getAssignmentForLesson(widget.lesson.id);
      if (a != null) {
        _summary.text = a.description;
        _instructions.text = a.instructions;
        _points.text = '${a.maxPoints}';
        _due = a.dueDate;
      }
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_instructions.text.trim().isEmpty) {
      setState(() => _error = 'Write the instructions students will follow');
      return;
    }
    setState(() => _busy = true);
    try {
      await _repo.saveAssignment(AssignmentModel(
        assignmentId: '',
        courseId: widget.course.courseId,
        moduleId: widget.moduleId,
        lessonId: widget.lesson.id,
        title: widget.lesson.title,
        description: _summary.text.trim(),
        instructions: _instructions.text.trim(),
        dueDate: _due,
        maxPoints: int.tryParse(_points.text) ?? 100,
        createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Brief — ${widget.lesson.title}'),
        content: SizedBox(
          width: 640,
          child: _loading
              ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
              : SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    TextField(controller: _summary, decoration: const InputDecoration(labelText: 'One-line summary')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _instructions,
                      minLines: 6,
                      maxLines: 16,
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        helperText: 'The AI marks submissions against these, so be specific about what a good answer covers.',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      SizedBox(width: 120, child: TextField(controller: _points, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Points'))),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.event_outlined),
                        label: Text('Due ${DateFormat('EEE d MMM yyyy').format(_due)}'),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _due,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (d != null) setState(() => _due = d);
                        },
                      ),
                    ]),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                  ]),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _busy ? null : _save, child: const Text('Save brief')),
        ],
      );
}
