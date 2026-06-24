import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../business_logic/video_manager.dart';
import '../../business_logic/certificate_manager.dart';
import '../../model/video_progress_model.dart';
import '../../model/course_model.dart';
import 'certificate_screen.dart';
import 'dart:async';

class VideoPlayerScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String moduleId;
  final String moduleTitle;
  final LessonModel lesson;
  final VideoManager videoManager;

  const VideoPlayerScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.moduleId,
    required this.moduleTitle,
    required this.lesson,
    required this.videoManager,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _youtubeController;
  VideoProgressModel? _progress;
  VideoSummaryModel? _aiSummary;
  VideoCaptionModel? _captions;
  bool _isLoading = true;
  Timer? _progressTimer;
  String? _errorMessage;
  final CertificateManager _certificateManager = CertificateManager();
  bool _certificateShown = false;
  
  String _activeTab = 'about';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.lesson.videoURL == null || widget.lesson.videoURL!.isEmpty) {
        setState(() {
          _errorMessage = 'No video URL provided';
          _isLoading = false;
        });
        return;
      }

      final videoId = widget.videoManager.extractVideoId(widget.lesson.videoURL!);
      if (videoId == null) {
        setState(() {
          _errorMessage = 'Invalid YouTube URL';
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
        moduleId: widget.moduleId,
        lessonId: widget.lesson.lessonId,
      );

      if (_progress != null && _progress!.currentPosition > 0) {
        _youtubeController?.seekTo(Duration(seconds: _progress!.currentPosition));
      }

      _captions = await widget.videoManager.getVideoCaptions(widget.lesson.videoURL!);
      _aiSummary = await widget.videoManager.generateAISummary(
        widget.lesson.videoURL!,
        widget.lesson.title,
      );

      _startProgressTracking();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load video: $e';
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
          moduleId: widget.moduleId,
          lessonId: widget.lesson.lessonId,
          videoURL: widget.lesson.videoURL!,
          currentPosition: currentPosition,
          totalDuration: totalDuration,
          isCompleted: currentPosition >= totalDuration * 0.95,
        );

        if (currentPosition >= totalDuration * 0.95 && _progress?.isCompleted != true) {
          widget.videoManager.markVideoCompleted(
            courseId: widget.courseId,
            moduleId: widget.moduleId,
            lessonId: widget.lesson.lessonId,
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
        lessonId: widget.lesson.lessonId,
        lessonName: widget.lesson.title,
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
      print('Error showing certificate: $e');
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 1,
        shadowColor: Colors.black12,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4231C0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AutoLearn',
          style: GoogleFonts.geist(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4231C0),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF474554)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF5B4ED9), width: 2),
                image: const DecorationImage(
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuC4wCagtlYgQZ4aUHGGZsVqv55EJUqhoMfsHGVcW8bMjYKtL5UhVQs9MludjJQK8xy3Qv6LUVLKnRetoFONw1wqOTGDJNtmFBzSoC-XavdOjhiwbxWczLbDbRyzMH9o58Xw-B1skueABPWzSThnuOZsMcy5_GJLX3PGWCCJe07QmGITbTQRuPZXdOGXYIaG9LYO40Cyr1oawGOfyuxEr83b4BUI2J5jv0-H-y9wlThHk6z76YAS_T-EHUSGojJFdl9hA1Ful5xqfCFo'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4231C0)))
            : _errorMessage != null
                ? _buildErrorView()
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildVideoPlayer(),
                            _buildContentArea(),
                            _buildUpNext(),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFBA1A1A)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF121C2A)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4231C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      color: Colors.black,
      child: _youtubeController != null
          ? YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: const Color(0xFF6B38D4),
                progressColors: const ProgressBarColors(
                  playedColor: Color(0xFF6B38D4),
                  handleColor: Color(0xFF5B4ED9),
                ),
              ),
              builder: (context, player) => player,
            )
          : const AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: Text('Video Not Available', style: TextStyle(color: Colors.white))),
            ),
    );
  }

  Widget _buildContentArea() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson Info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4ED9).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.moduleTitle.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF3D2ABB)),
                ),
              ),
              const SizedBox(width: 8),
              Text('• 12k Students', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF474554))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.lesson.title,
            style: GoogleFonts.geist(fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFF121C2A)),
          ),
          const SizedBox(height: 8),
          Text(
            widget.lesson.description,
            style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF474554), height: 1.5),
          ),
          const SizedBox(height: 24),
          
          // Tabs
          Row(
            children: [
              _buildTab('about', 'About'),
              _buildTab('transcript', 'Transcript'),
              _buildTab('resources', 'Resources'),
            ],
          ),
          const SizedBox(height: 24),
          
          // Tab Content
          if (_activeTab == 'about') _buildAboutTab(),
          if (_activeTab == 'transcript') _buildTranscriptTab(),
          if (_activeTab == 'resources') _buildResourcesTab(),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String title) {
    final isActive = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF4231C0) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF4231C0) : const Color(0xFF474554),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return Column(
      children: [
        if (_aiSummary != null)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Summary & Key Takeaways', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF4231C0))),
                const SizedBox(height: 12),
                Text(_aiSummary!.summary, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF121C2A), height: 1.5)),
                const SizedBox(height: 12),
                ..._aiSummary!.keyPoints.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF00573A), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(point, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF121C2A)))),
                    ],
                  ),
                )).toList()
              ],
            ),
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC8C4D7)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDEU2cObnezz6wy6A_Ne8mkAbvFV69v2Suz83oXOEDZN6bGvooNB8xVYvv2Lod_hp7OjLU7wzHTJAFaJakF17fr68RTkAdYHqGHWFVPLTm3wcQaY4br98ELbQ0aobLwvMPg9o5ZA1_W8U-N_LQVyHqVCF2-eW5xjSTwIIQA8RhGyp_JRy07-i_0kqqu8u-cMI6lkHjUa_q5lg_iyBeSkUXB5ewzJRniJAyb3F23mcEdECgTOpl9NfMlssTiEtAqmIKqRM1tNT9r394f'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. Julian Vance', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF121C2A))),
                    Text('Senior AI Architect @ DeepFlow', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4231C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Follow', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTranscriptTab() {
    if (_captions == null || _captions!.captions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No transcript available', style: GoogleFonts.inter(color: const Color(0xFF474554))),
        ),
      );
    }
    
    return Column(
      children: _captions!.captions.map((caption) {
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  _formatDuration(Duration(seconds: caption.startTime)),
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF4231C0)),
                ),
              ),
              Expanded(
                child: Text(
                  caption.text,
                  style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF121C2A)),
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '\$minutes:\$seconds';
  }

  Widget _buildResourcesTab() {
    return Column(
      children: [
        _buildResourceCard(Icons.description, 'Lesson_Handout.pdf', '2.4 MB', const Color(0xFFFFDAD6), const Color(0xFFBA1A1A)),
        const SizedBox(height: 16),
        _buildResourceCard(Icons.code, 'Source_Code.ipynb', '156 KB', const Color(0xFFE6EEFF), const Color(0xFF4231C0)),
      ],
    );
  }
  
  Widget _buildResourceCard(IconData icon, String title, String subtitle, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF121C2A))),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
              ],
            ),
          ),
          const Icon(Icons.download, color: Color(0xFF787586)),
        ],
      ),
    );
  }

  Widget _buildUpNext() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Up Next', style: GoogleFonts.geist(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF121C2A))),
              Text('View Syllabus', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF4231C0), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          _buildNextLessonCard('05. Production Deployment', 'Deployment Patterns', '12:40', false),
          const SizedBox(height: 16),
          _buildNextLessonCard('06. Security in AI Ops', 'Privacy & Ethics', '08:15', true),
        ],
      ),
    );
  }
  
  Widget _buildNextLessonCard(String title, String subtitle, String duration, bool locked) {
    return Opacity(
      opacity: locked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC8C4D7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
            )
          ]
        ),
        child: Row(
          children: [
            Container(
              width: 96,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFD0DBED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.play_circle_outline, color: Colors.white)),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(duration, style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF121C2A)), overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
                ],
              ),
            ),
            if (locked) const Icon(Icons.lock, color: Color(0xFF787586)),
          ],
        ),
      ),
    );
  }
}
