// lib/repository/chat_repository.dart
import 'dart:convert';
import '../backend/api_client.dart';
import '../model/chat_message_model.dart';

class ChatRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<ChatMessageModel?> sendMessage({required String sessionId, required dynamic message}) async {
    return newMessage;
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

  Future<List<dynamic>> getUserSessions(String userId) async {
    return [];
  }

  Future<void> deleteSession(String sessionId) async {}
}

