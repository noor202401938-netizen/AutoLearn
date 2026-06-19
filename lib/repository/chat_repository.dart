// lib/repository/chat_repository.dart
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
    return null;
  }

  Future<List<ChatMessageModel>> getSessionHistory(String sessionId) async {
    return [];
  }

  Future<String> getOrCreateCurrentSession(String userId) async {
    return "mock_session";
  }

  Future<List<ChatMessageModel>> getSessionMessages(String sessionId) async {
    return [];
  }

  Stream<List<ChatMessageModel>> watchSessionMessages(String sessionId) async* {
    yield [];
  }

  Future<List<ChatSessionModel>> getUserSessions(String userId) async {
    return [];
  }

  Future<void> deleteSession(String sessionId) async {}
}

