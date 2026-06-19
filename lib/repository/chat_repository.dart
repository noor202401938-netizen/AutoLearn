// lib/repository/chat_repository.dart
import 'dart:convert';
import '../backend/api_client.dart';
import '../model/chat_message_model.dart';

class ChatRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<ChatMessageModel?> sendMessage(List<ChatMessageModel> history, ChatMessageModel newMessage) async {
    try {
      // Map history + new message to OpenAI format for our backend
      final messages = [...history, newMessage].map((msg) => {
        'role': msg.role,
        'content': msg.content,
      }).toList();

      final response = await _apiClient.post('/ai/chat', {
        'sessionId': newMessage.sessionId,
        'messages': messages,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sessionId: newMessage.sessionId,
          role: data['role'] ?? 'assistant',
          content: data['content'] ?? '',
          timestamp: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      print('Error sending chat message: $e');
      return null;
    }
  }

  Future<List<ChatMessageModel>> getSessionHistory(String sessionId) async {
    try {
      final response = await _apiClient.get('/ai/chat/history/$sessionId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List messages = data['messages'] ?? [];
        return messages.map((msg) => ChatMessageModel(
          id: msg['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          sessionId: msg['sessionId'] ?? sessionId,
          role: msg['role'] ?? 'user',
          content: msg['content'] ?? '',
          timestamp: msg['timestamp'] != null ? DateTime.parse(msg['timestamp']) : DateTime.now(),
        )).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching session history: $e');
      return [];
    }
  }
}
