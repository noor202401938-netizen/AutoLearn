import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../backend/api_client.dart';
import '../../business_logic/video_manager.dart';
import '../../model/course_model.dart';
import '../../model/video_progress_model.dart';
import '../../repository/certificate_repository.dart';
import '../../repository/community_repository.dart';
import '../../widgets/notebook/notebook.dart';
import 'ai_tutor_chat_screen.dart';
import 'certificate_screen.dart';

/// Watch a lesson: the video, notes you pin to moments in it, AI study notes,
/// and the tutor in a side pane.
class VideoPlayerScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String moduleId;
  final String moduleTitle;
  final LessonModel lesson;
  final VideoManager videoManager;
  final CourseModel? course;

  const VideoPlayerScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.moduleId,
    required this.moduleTitle,
    required this.lesson,
    required this.videoManager,
    this.course,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final _community = CommunityRepository();
  final _certificates = CertificateRepository();
  final _note = TextEditingController();

  YoutubePlayerController? _player;
  late LessonModel _lesson = widget.lesson;
  late String _moduleId = widget.moduleId;
  String? _error;
  VideoSummaryModel? _summary;
  bool _summaryLoaded = false;
  List<Bookmark> _moments = [];
  bool _completed = false;
  bool _showTutor = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _player?.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    _ticker?.cancel();
    _player?.dispose();
    setState(() {
      _player = null;
      _error = null;
      _summary = null;
      _summaryLoaded = false;
    });

    final id = widget.videoManager.extractVideoId(_lesson.videoURL ?? '');
    if (id == null) {
      setState(() => _error = "This lesson's video link doesn't work");
      return;
    }
    final progress = await widget.videoManager.getVideoProgress(
      courseId: widget.courseId,
      moduleId: _moduleId,
      lessonId: _lesson.lessonId,
    );
    if (!mounted) return;
    _completed = progress?.isCompleted ?? false;
    setState(() {
      _player = YoutubePlayerController(
        initialVideoId: id,
        flags: YoutubePlayerFlags(autoPlay: false, enableCaption: true, startAt: progress?.currentPosition ?? 0),
      );
    });
    // Save the position every 10s; past 95% the lesson counts as complete.
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) => _saveProgress());
    _loadMoments();
    final summary = await widget.videoManager.generateAISummary(_lesson.videoURL!, _lesson.title);
    if (mounted) {
      setState(() {
        _summary = summary;
        _summaryLoaded = true;
      });
    }
  }

  Future<void> _saveProgress() async {
    final p = _player;
    if (p == null || !p.value.isReady) return;
    final pos = p.value.position.inSeconds;
    final total = p.value.metaData.duration.inSeconds;
    if (total == 0) return;
    final finished = pos >= total * 0.95;
    await widget.videoManager.saveProgress(
      courseId: widget.courseId,
      moduleId: _moduleId,
      lessonId: _lesson.lessonId,
      videoURL: _lesson.videoURL!,
      currentPosition: pos,
      totalDuration: total,
      isCompleted: finished,
    );
    if (finished && !_completed) {
      _completed = true;
      // Only shows anything if this finished the whole course.
      try {
        final cert = await _certificates.issueIfEarned(courseId: widget.courseId);
        if (cert != null && mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CertificateScreen(certificate: cert)));
        }
      } on ApiException {
        // Certificate can be claimed later from the course page.
      }
    }
  }

  Future<void> _loadMoments() async {
    try {
      final all = await _community.bookmarks();
      if (mounted) {
        setState(() => _moments = all.where((b) => b.lessonId == _lesson.lessonId && b.positionSeconds != null).toList()
          ..sort((a, b) => a.positionSeconds!.compareTo(b.positionSeconds!)));
      }
    } on ApiException {
      // Notes are optional; the video still plays.
    }
  }

  Future<void> _pinNote() async {
    final pos = _player?.value.position.inSeconds ?? 0;
    final text = _note.text.trim();
    try {
      await _community.addBookmark(
        courseId: widget.courseId,
        lessonId: _lesson.lessonId,
        title: _lesson.title,
        note: text.isEmpty ? null : text,
        positionSeconds: pos,
      );
      _note.clear();
      _loadMoments();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _switchTo(ModuleModel m, LessonModel l) {
    if (l.lessonId == _lesson.lessonId) return;
    _saveProgress();
    setState(() {
      _lesson = l;
      _moduleId = m.moduleId;
    });
    _start();
  }

  String _clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 1100;
    final main = ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 48), children: _mainColumn());
    return NotebookPage(
      title: widget.courseTitle,
      actions: [
        TextButton.icon(
          onPressed: () => setState(() => _showTutor = !_showTutor),
          icon: const Icon(Icons.forum_outlined),
          label: Text(_showTutor ? 'Hide tutor' : 'Ask the tutor'),
        ),
      ],
      body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (wide && widget.course != null) SizedBox(width: 280, child: _contents()),
        Expanded(child: main),
        if (_showTutor)
          Container(
            width: wide ? 420 : MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: NotebookColors.of(context).sheet,
              border: Border(left: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), width: 1.25)),
            ),
            child: AITutorChatScreen(embedded: true, contextTitle: _lesson.title),
          ),
      ]),
    );
  }

  List<Widget> _mainColumn() {
    final theme = Theme.of(context);
    return [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: NoteCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: _error != null
                  ? AspectRatio(aspectRatio: 16 / 9, child: Center(child: Text(_error!)))
                  : _player == null
                      ? const AspectRatio(aspectRatio: 16 / 9, child: Center(child: CircularProgressIndicator()))
                      : YoutubePlayer(controller: _player!, showVideoProgressIndicator: true),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(_lesson.title, style: theme.textTheme.headlineMedium),
      MarginNote(widget.moduleTitle, size: 19),
      const SizedBox(height: 28),
      const NoteHeading('Your notes', note: 'pinned to the moment'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _note,
            decoration: const InputDecoration(hintText: 'Jot something down at this point in the video…'),
            onSubmitted: (_) => _pinNote(),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(onPressed: _pinNote, icon: const Icon(Icons.push_pin_outlined, size: 18), label: const Text('Pin')),
      ]),
      const SizedBox(height: 10),
      for (final m in _moments)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: TextButton(
            onPressed: () => _player?.seekTo(Duration(seconds: m.positionSeconds!)),
            child: Text(_clock(m.positionSeconds!), style: NotebookColors.figures(size: 14, weight: FontWeight.w600)),
          ),
          title: Text(m.note ?? 'Bookmarked moment', style: NotebookColors.of(context).note(size: 14, color: theme.colorScheme.onSurface)),
          trailing: IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () async {
              await _community.deleteBookmark(m.id);
              _loadMoments();
            },
          ),
        ),
      const SizedBox(height: 28),
      const NoteHeading('Study notes', note: 'written by the AI'),
      const SizedBox(height: 12),
      if (!_summaryLoaded)
        const MarginNote('writing them up…', tilt: 0)
      else if (_summary == null)
        Text('Study notes need the AI tutor, which isn’t available right now.', style: theme.textTheme.bodyMedium)
      else ...[
        NoteText(_summary!.summary),
        for (final k in _summary!.keyPoints)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('→  ', style: NotebookColors.of(context).note(size: 14)),
              Expanded(child: Highlight(k, style: theme.textTheme.bodyLarge)),
            ]),
          ),
      ],
    ];
  }

  Widget _contents() {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 8, 24), children: [
      const MarginNote('contents', size: 20),
      const SizedBox(height: 8),
      for (final m in widget.course!.syllabus) ...[
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(m.title, style: theme.textTheme.titleSmall),
        ),
        for (final l in m.lessons.where((l) => l.type == 'video' && (l.videoURL ?? '').isNotEmpty))
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 8),
            selected: l.lessonId == _lesson.lessonId,
            leading: const Icon(Icons.play_arrow_outlined, size: 18),
            title: Text(l.title),
            onTap: () => _switchTo(m, l),
          ),
      ],
    ]);
  }
}
