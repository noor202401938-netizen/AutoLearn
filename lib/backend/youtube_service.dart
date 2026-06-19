// lib/backend/youtube_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/video_progress_model.dart';

class YouTubeService {
  // Extract YouTube video ID from URL
  static String? extractVideoId(String url) {
    final regex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  // Get video information (requires YouTube Data API v3)
  // Note: You'll need to add your YouTube API key
  Future<Map<String, dynamic>?> getVideoInfo(String videoId) async {
    try {
      // TODO: Replace with your YouTube Data API key
      const apiKey = 'AIzaSyAsj1Hqcs0aRovTropSo0BRRy3AWgOEcr4';
      final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/videos?id=$videoId&key=$apiKey&part=snippet,contentDetails,statistics',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data['items'][0];
        }
      }
      return null;
    } catch (e) {
      // If API key is not set, return null (graceful degradation)
      return null;
    }
  }

  // Get captions from YouTube (requires YouTube Data API v3)
  Future<VideoCaptionModel?> getVideoCaptions(String videoId, {String language = 'en'}) async {
    try {
      const apiKey = 'AIzaSyAsj1Hqcs0aRovTropSo0BRRy3AWgOEcr4';
      
      // First, get caption track ID
      final captionListUrl = Uri.parse(
        'https://www.googleapis.com/youtube/v3/captions?videoId=$videoId&key=$apiKey&part=snippet',
      );

      final captionListResponse = await http.get(captionListUrl);
      
      if (captionListResponse.statusCode != 200) {
        return null;
      }

      final captionListData = json.decode(captionListResponse.body);
      if (captionListData['items'] == null || captionListData['items'].isEmpty) {
        return null;
      }

      // Find caption track for the requested language
      String? captionTrackId;
      for (var item in captionListData['items']) {
        if (item['snippet']['language'] == language) {
          captionTrackId = item['id'];
          break;
        }
      }

      if (captionTrackId == null) {
        // Fallback to first available caption
        captionTrackId = captionListData['items'][0]['id'];
      }

      // Download captions
      final captionUrl = Uri.parse(
        'https://www.googleapis.com/youtube/v3/captions/$captionTrackId?key=$apiKey',
      );

      final captionResponse = await http.get(captionUrl);
      
      if (captionResponse.statusCode == 200) {
        // Parse WebVTT or SRT format
        final captions = _parseCaptions(captionResponse.body);
        return VideoCaptionModel(
          videoId: videoId,
          language: language,
          captions: captions,
          lastUpdated: DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      // Graceful degradation if API is not available
      return null;
    }
  }

  // Parse WebVTT or SRT caption format
  List<CaptionItem> _parseCaptions(String captionText) {
    final captions = <CaptionItem>[];
    final lines = captionText.split('\n');
    
    double? startTime;
    double? endTime;
    final textBuffer = StringBuffer();

    for (var line in lines) {
      line = line.trim();
      
      // Skip empty lines and metadata
      if (line.isEmpty || line.startsWith('WEBVTT') || line.startsWith('NOTE')) {
        continue;
      }

      // Parse timestamp line (format: 00:00:00.000 --> 00:00:05.000)
      final timestampMatch = RegExp(r'(\d{2}):(\d{2}):(\d{2})\.(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})\.(\d{3})')
          .firstMatch(line);
      
      if (timestampMatch != null) {
        // Save previous caption if exists
        if (startTime != null && endTime != null && textBuffer.isNotEmpty) {
          captions.add(CaptionItem(
            startTime: startTime,
            endTime: endTime,
            text: textBuffer.toString().trim(),
          ));
          textBuffer.clear();
        }

        // Parse new timestamps
        startTime = _parseTimestamp(
          timestampMatch.group(1)!,
          timestampMatch.group(2)!,
          timestampMatch.group(3)!,
          timestampMatch.group(4)!,
        );
        endTime = _parseTimestamp(
          timestampMatch.group(5)!,
          timestampMatch.group(6)!,
          timestampMatch.group(7)!,
          timestampMatch.group(8)!,
        );
      } else if (startTime != null && endTime != null && line.isNotEmpty) {
        // This is caption text
        if (textBuffer.isNotEmpty) {
          textBuffer.write(' ');
        }
        textBuffer.write(line);
      }
    }

    // Add last caption
    if (startTime != null && endTime != null && textBuffer.isNotEmpty) {
      captions.add(CaptionItem(
        startTime: startTime,
        endTime: endTime,
        text: textBuffer.toString().trim(),
      ));
    }

    return captions;
  }

  double _parseTimestamp(String hours, String minutes, String seconds, String milliseconds) {
    return int.parse(hours) * 3600.0 +
        int.parse(minutes) * 60.0 +
        int.parse(seconds) +
        int.parse(milliseconds) / 1000.0;
  }

  // Get video duration in seconds from ISO 8601 duration format
  int parseDuration(String isoDuration) {
    try {
      final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
      final match = regex.firstMatch(isoDuration);
      
      if (match == null) return 0;

      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

      return hours * 3600 + minutes * 60 + seconds;
    } catch (e) {
      return 0;
    }
  }
}

