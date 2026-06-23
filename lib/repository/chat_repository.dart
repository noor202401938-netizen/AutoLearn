import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../backend/api_client.dart';
import '../model/chat_message_model.dart';

class ChatRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<ChatMessageModel?> sendMessage({
    required String userId,
    required String role,
    required String content,
    required String sessionId,
    String? courseId,
    String? lessonId,
  }) async {
    try {
      final response = await _apiClient.post('/chat/$sessionId/message', {
        'userId': userId,
        'role': role,
        'content': content,
        'courseId': courseId,
        'lessonId': lessonId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatMessageModel.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to send message: ${response.body}');
    } catch (e) {
      debugPrint('Error sending message: $e');
      throw Exception('Network error sending message');
    }
  }

  Future<List<ChatMessageModel>> getSessionHistory(String sessionId) async {
    try {
      final response = await _apiClient.get('/chat/$sessionId/history');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatMessageModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting session history: $e');
      return [];
    }
  }

  Future<String> getOrCreateCurrentSession(String userId) async {
    try {
      final response = await _apiClient.post('/chat/session', {'userId': userId});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['sessionId'] != null) {
          return data['sessionId'];
        }
        throw Exception('API returned success but no sessionId was provided');
      }
      throw Exception('Failed to create session with status: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error creating session: $e');
      throw Exception('Network error creating session: $e');
    }
  }

  Future<List<ChatMessageModel>> getSessionMessages(String sessionId) async {
    return getSessionHistory(sessionId);
  }

  Stream<List<ChatMessageModel>> watchSessionMessages(String sessionId) {
    return Stream.periodic(const Duration(seconds: 3))
        .asyncMap((_) => getSessionHistory(sessionId))
        .distinct();
  }

  Future<List<ChatSessionModel>> getUserSessions(String userId) async {
    try {
      final response = await _apiClient.get('/user/chat-sessions');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatSessionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting user sessions: $e');
      return [];
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _apiClient.delete('/chat/$sessionId');
    } catch (e) {
      debugPrint('Error deleting session: $e');
      throw Exception('Failed to delete session');
    }
  }
}
