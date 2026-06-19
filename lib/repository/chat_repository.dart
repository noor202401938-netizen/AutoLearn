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

  // To keep it simple, we might just store history locally or let the backend save it.
  // The Firebase version likely fetched history. We can return an empty list or mock it if there's no backend table.
  Future<List<ChatMessageModel>> getSessionHistory(String sessionId) async {
    // Return empty for now; the UI will maintain the active list
    return [];
  }
}
