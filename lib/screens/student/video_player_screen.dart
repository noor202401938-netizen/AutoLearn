import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../business_logic/video_manager.dart';
import '../../business_logic/certificate_manager.dart';
import '../../model/video_progress_model.dart';
import '../../model/course_model.dart';
import 'certificate_screen.dart';
import '../../widgets/player/ai_player_copilot.dart';
import '../../widgets/premium/skill_badge.dart';
import 'dart:async';

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
  YoutubePlayerController? _youtubeController;
  late LessonModel _currentLesson;
  late String _currentModuleTitle;
  late String _currentModuleId;

  VideoProgressModel? _progress;
  VideoSummaryModel? _aiSummary;
  VideoCaptionModel? _captions;
  bool _isLoading = true;
  Timer? _progressTimer;
  String? _errorMessage;
  final CertificateManager _certificateManager = CertificateManager();
  bool _certificateShown = false;

  String _activeTab = 'about';
  bool _showCurriculumPane = true;
  bool _showCopilotPane = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.lesson;
    _currentModuleTitle = widget.moduleTitle;
    _currentModuleId = widget.moduleId;
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    setState(() => _isLoading = true);
    _progressTimer?.cancel();
    _youtubeController?.dispose();
    _youtubeController = null;

    try {
      if (_currentLesson.videoURL == null || _currentLesson.videoURL!.isEmpty) {
        setState(() {
          _errorMessage = 'No video URL provided for this lesson';
          _isLoading = false;
        });
        return;
      }

      final videoId = widget.videoManager.extractVideoId(_currentLesson.videoURL!);
      if (videoId == null) {
        setState(() {
          _errorMessage = 'Invalid YouTube video link';
          _isLoading = false;
        });
        return;
      }

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
        ),
      );

      _progress = await widget.videoManager.getVideoProgress(
        courseId: widget.courseId,
        moduleId: _currentModuleId,
        lessonId: _currentLesson.lessonId,
      );

      if (_progress != null && _progress!.currentPosition > 0) {
        _youtubeController?.seekTo(Duration(seconds: _progress!.currentPosition));
      }

      try {
        _captions = await widget.videoManager.getVideoCaptions(_currentLesson.videoURL!);
      } catch (e) {
        debugPrint('Failed to load captions: $e');
      }

      try {
        _aiSummary = await widget.videoManager.generateAISummary(
          _currentLesson.videoURL!,
          _currentLesson.title,
        );
      } catch (e) {
        debugPrint('Failed to generate AI summary: $e');
      }

      _startProgressTracking();

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize player: $e';
        _isLoading = false;
      });
    }
  }

  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_youtubeController != null && _youtubeController!.value.isReady) {
        final currentPosition = _youtubeController!.value.position.inSeconds;
        final totalDuration = _youtubeController!.value.metaData.duration.inSeconds;
        if (totalDuration == 0) return;

        widget.videoManager.saveProgress(
          courseId: widget.courseId,
          moduleId: _currentModuleId,
          lessonId: _currentLesson.lessonId,
          videoURL: _currentLesson.videoURL!,
          currentPosition: currentPosition,
          totalDuration: totalDuration,
          isCompleted: currentPosition >= totalDuration * 0.95,
        );

        if (currentPosition >= totalDuration * 0.95 && _progress?.isCompleted != true) {
          widget.videoManager.markVideoCompleted(
            courseId: widget.courseId,
            moduleId: _currentModuleId,
            lessonId: _currentLesson.lessonId,
          );

          if (!_certificateShown) {
            _certificateShown = true;
            _showCertificate();
          }
        }
      }
    });
  }

  Future<void> _showCertificate() async {
    try {
      final certificate = await _certificateManager.generateCertificate(
        courseId: widget.courseId,
        courseName: widget.courseTitle,
        lessonId: _currentLesson.lessonId,
        lessonName: _currentLesson.title,
      );

      if (certificate != null && mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CertificateScreen(certificate: certificate),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error showing certificate: $e');
    }
  }

  void _switchLesson(ModuleModel module, LessonModel lesson) {
    if (lesson.lessonId == _currentLesson.lessonId) return;
    setState(() {
      _currentModuleTitle = module.title;
      _currentModuleId = module.moduleId;
      _currentLesson = lesson;
    });
    _initializeVideo();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _youtubeController?.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF071514) : const Color(0xFFF8F7F4),
      appBar: _buildPlayerAppBar(isDark),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  // 1. Left Curriculum Sidebar
                  if (_showCurriculumPane)
                    Container(
                      width: 320,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D2220) : Colors.white,
                        border: Border(
                          right: BorderSide(
                            color: isDark ? const Color(0xFF15302C) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: _buildCurriculumDrawer(isDark),
                    ),

                  // 2. Center Player & Workspace Area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCinemaPlayer(isDark),
                          const SizedBox(height: 20),
                          _buildLessonMetadata(isDark),
                          const SizedBox(height: 20),
                          _buildWorkspaceTabs(isDark),
                          const SizedBox(height: 20),
                          _buildTabBody(isDark),
                        ],
                      ),
                    ),
                  ),

                  // 3. Right Embedded AI Copilot
                  if (_showCopilotPane)
                    AiPlayerCopilot(
                      courseTitle: widget.courseTitle,
                      lessonTitle: _currentLesson.title,
                      lessonContent: _currentLesson.content,
                      onClose: () => setState(() => _showCopilotPane = false),
                    ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCinemaPlayer(isDark),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLessonMetadata(isDark),
                          const SizedBox(height: 16),
                          _buildWorkspaceTabs(isDark),
                          const SizedBox(height: 16),
                          if (_activeTab == 'curriculum')
                            _buildCurriculumDrawer(isDark)
                          else
                            _buildTabBody(isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildPlayerAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF071514) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.chevron_left, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.courseTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741),
            ),
          ),
          Text(
            '$_currentModuleTitle • ${_currentLesson.title}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
      actions: [
        // Toggle Curriculum Pane Button
        IconButton(
          tooltip: 'Toggle Curriculum Sidebar',
          icon: Icon(
            _showCurriculumPane ? CupertinoIcons.sidebar_left : CupertinoIcons.sidebar_left,
            color: _showCurriculumPane ? const Color(0xFF004741) : Colors.grey,
            size: 20,
          ),
          onPressed: () => setState(() => _showCurriculumPane = !_showCurriculumPane),
        ),

        // Toggle AI Copilot Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _showCopilotPane = !_showCopilotPane),
            icon: const Icon(CupertinoIcons.sparkles, size: 14),
            label: Text(
              'AI Copilot',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _showCopilotPane
                  ? const Color(0xFF004741)
                  : (isDark ? const Color(0xFF152E2B) : const Color(0xFFE5E0D3)),
              foregroundColor: _showCopilotPane
                  ? const Color(0xFFF0EDE4)
                  : (isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741)),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCinemaPlayer(bool isDark) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF004741)),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D2220) : const Color(0xFF152E2B),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle, color: Colors.amber, size: 40),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _initializeVideo,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Try Reloading'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _youtubeController != null
            ? YoutubePlayerBuilder(
                player: YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: const Color(0xFF004741),
                  progressColors: const ProgressBarColors(
                    playedColor: Color(0xFF004741),
                    handleColor: Color(0xFFC69234),
                  ),
                ),
                builder: (context, player) => player,
              )
            : const AspectRatio(aspectRatio: 16 / 9, child: Center(child: Text('Loading video...'))),
      ),
    );
  }

  Widget _buildLessonMetadata(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkillBadge(label: _currentModuleTitle),
                  const SizedBox(width: 8),
                  if (_progress?.isCompleted == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.checkmark_seal_fill,
                              size: 13, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _currentLesson.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF0A2421),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceTabs(bool isDark) {
    final tabs = [
      {'id': 'about', 'label': 'Overview & AI Key Points'},
      {'id': 'transcript', 'label': 'Interactive Transcript'},
      {'id': 'notes', 'label': 'My Notes'},
      {'id': 'resources', 'label': 'Downloads & Resources'},
      if (MediaQuery.of(context).size.width < 1024) {'id': 'curriculum', 'label': 'Curriculum'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final isSelected = _activeTab == t['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => setState(() => _activeTab = t['id']!),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF004741)
                      : (isDark ? const Color(0xFF0D2220) : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF004741)
                        : (isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(
                  t['label']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFFF0EDE4)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBody(bool isDark) {
    switch (_activeTab) {
      case 'about':
        return _buildAboutTab(isDark);
      case 'transcript':
        return _buildTranscriptTab(isDark);
      case 'notes':
        return _buildNotesTab(isDark);
      case 'resources':
        return _buildResourcesTab(isDark);
      default:
        return _buildAboutTab(isDark);
    }
  }

  Widget _buildAboutTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_aiSummary != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D2220) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.sparkles, color: Color(0xFFC69234), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'AI Lesson Summary & Core Principles',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _aiSummary!.summary,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                ..._aiSummary!.keyPoints.map((point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              point,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D2220) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lesson Description',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF0A2421),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _currentLesson.content != null && _currentLesson.content!.isNotEmpty
                    ? _currentLesson.content!
                    : 'In this module, you study the core economic frameworks that drive market supply, consumer choices, and elasticity equilibrium.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptTab(bool isDark) {
    if (_captions == null || _captions!.captions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Text(
          'Transcript is currently processing for this video.',
          style: GoogleFonts.plusJakartaSans(color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2220) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: _captions!.captions.map((cap) {
          return InkWell(
            onTap: () {
              _youtubeController?.seekTo(Duration(seconds: cap.startTime.toInt()));
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004741).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${cap.startTime.toInt() ~/ 60}:${(cap.startTime.toInt() % 60).toString().padLeft(2, '0')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF004741),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cap.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF0A2421),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotesTab(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2220) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Personal Study Notes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF0A2421),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notes saved to cloud storage.')),
                  );
                },
                icon: const Icon(CupertinoIcons.floppy_disk, size: 14),
                label: const Text('Save Notes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004741),
                  foregroundColor: const Color(0xFFF0EDE4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 8,
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Type your takeaways, equations, or timestamp bookmarks here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
                ),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF071514) : const Color(0xFFF8F7F4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesTab(bool isDark) {
    final resources = [
      {'title': 'Lesson Slide Deck (PDF)', 'size': '2.4 MB'},
      {'title': 'Case Study Worksheet', 'size': '840 KB'},
      {'title': 'Formulas & Cheat Sheet', 'size': '520 KB'},
    ];

    return Column(
      children: resources.map((res) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D2220) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.doc_text_fill, color: Color(0xFF004741), size: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res['title']!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    res['size']!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading ${res['title']}...')),
                  );
                },
                icon: const Icon(CupertinoIcons.arrow_down_to_line, size: 18),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCurriculumDrawer(bool isDark) {
    final course = widget.course;
    if (course == null || course.syllabus.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Curriculum: $_currentModuleTitle',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      children: [
        Text(
          'Course Curriculum',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF0A2421),
          ),
        ),
        const SizedBox(height: 12),
        ...course.syllabus.map((module) {
          final isCurrentModule = module.moduleId == _currentModuleId;

          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isCurrentModule,
              tilePadding: EdgeInsets.zero,
              leading: Icon(
                CupertinoIcons.folder_fill,
                size: 16,
                color: isCurrentModule ? const Color(0xFF004741) : Colors.grey,
              ),
              title: Text(
                module.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF0A2421),
                ),
              ),
              children: module.lessons.map((lesson) {
                final isCurrent = lesson.lessonId == _currentLesson.lessonId;

                return InkWell(
                  onTap: () => _switchLesson(module, lesson),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF004741).withOpacity(isDark ? 0.35 : 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isCurrent
                          ? Border.all(
                              color: const Color(0xFF004741).withOpacity(0.3),
                              width: 1.0,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrent
                              ? CupertinoIcons.play_circle_fill
                              : CupertinoIcons.play_circle,
                          size: 16,
                          color: isCurrent ? const Color(0xFF004741) : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lesson.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              color: isCurrent
                                  ? (isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741))
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}
