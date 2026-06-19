// lib/screens/student/video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  bool _showCaptions = false;
  bool _showSummary = false;
  Timer? _progressTimer;
  String? _errorMessage;
  final CertificateManager _certificateManager = CertificateManager();
  bool _certificateShown = false;

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

      // Extract YouTube video ID
      final videoId = widget.videoManager.extractVideoId(widget.lesson.videoURL!);
      if (videoId == null) {
        setState(() {
          _errorMessage = 'Invalid YouTube URL';
          _isLoading = false;
        });
        return;
      }

      // Initialize YouTube player
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
        ),
      );

      // Load existing progress
      _progress = await widget.videoManager.getVideoProgress(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        lessonId: widget.lesson.lessonId,
      );

      // Seek to last position if progress exists
      if (_progress != null && _progress!.currentPosition > 0) {
        _youtubeController?.seekTo(Duration(seconds: _progress!.currentPosition));
      }

      // Load captions
      _captions = await widget.videoManager.getVideoCaptions(widget.lesson.videoURL!);

      // Generate AI summary
      _aiSummary = await widget.videoManager.generateAISummary(
        widget.lesson.videoURL!,
        widget.lesson.title,
      );

      // Start progress tracking timer
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

        widget.videoManager.saveProgress(
          courseId: widget.courseId,
          moduleId: widget.moduleId,
          lessonId: widget.lesson.lessonId,
          videoURL: widget.lesson.videoURL!,
          currentPosition: currentPosition,
          totalDuration: totalDuration,
          isCompleted: currentPosition >= totalDuration * 0.95, // 95% watched = completed
        );

        // Mark as completed if watched 95% or more
        if (currentPosition >= totalDuration * 0.95 && _progress?.isCompleted != true) {
          widget.videoManager.markVideoCompleted(
            courseId: widget.courseId,
            moduleId: widget.moduleId,
            lessonId: widget.lesson.lessonId,
          );
          
          // Generate and show certificate
          if (!_certificateShown) {
            _certificateShown = true;
            _showCertificate();
          }
        }
      }
    });
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Captions toggle
          IconButton(
            icon: Icon(_showCaptions ? Icons.closed_caption : Icons.closed_caption_outlined, color: Colors.white),
            onPressed: () {
              setState(() {
                _showCaptions = !_showCaptions;
              });
            },
            tooltip: 'Toggle Captions',
          ),
          // Summary toggle
          IconButton(
            icon: Icon(_showSummary ? Icons.summarize : Icons.summarize_outlined, color: Colors.white),
            onPressed: () {
              setState(() {
                _showSummary = !_showSummary;
              });
            },
            tooltip: 'AI Summary',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
              Theme.of(context).colorScheme.background,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage != null
                  ? _buildErrorView()
                  : _buildVideoPlayer(),
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
            Icon(Icons.error_outline, size: 64, color: Colors.redAccent.withOpacity(0.8)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // YouTube Player
          if (_youtubeController != null)
            YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Theme.of(context).colorScheme.secondary,
                progressColors: ProgressBarColors(
                  playedColor: Theme.of(context).colorScheme.secondary,
                  handleColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
              builder: (context, player) => player,
            ),

          // Video Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson Title
                Text(
                  widget.lesson.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Module and Course Info
                Text(
                  '${widget.moduleTitle} • ${widget.courseTitle}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),

                // Progress Indicator
                if (_progress != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20, color: Colors.greenAccent),
                      const SizedBox(width: 8),
                      Text(
                        _progress!.isCompleted
                            ? 'Completed'
                            : '${_progress!.completionPercentage.toStringAsFixed(0)}% Watched',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // AI Summary Section
                if (_showSummary && _aiSummary != null) _buildAISummary(),

                // Captions Section
                if (_showCaptions && _captions != null) _buildCaptions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISummary() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'AI Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _aiSummary!.summary,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white),
            ),
            if (_aiSummary!.keyPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Key Points:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ..._aiSummary!.keyPoints.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_right, size: 20, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCaptions() {
    if (_captions == null || _captions!.captions.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orangeAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Captions not available for this video. Connect YouTube API to enable captions.',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.closed_caption, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                const Text(
                  'Captions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _captions!.captions.length,
                itemBuilder: (context, index) {
                  final caption = _captions!.captions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      caption.text,
                      style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white.withOpacity(0.8)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
        // Show certificate after a short delay
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
}

