import '../backend/api_client.dart';
import '../model/chat_message_model.dart';

/// AI tutor conversations. The tutor runs on the server; the app never holds
/// an AI key. Errors surface as [ApiException] with a readable message.
class ChatRepository {
  final ApiClient _api = ApiClient.instance;

  Future<String> createSession() async {
    final data = await _api.json('POST', '/chat/session', body: {});
    return data['sessionId'] as String;
  }

  Future<List<ChatSessionModel>> listSessions() async {
    final data = await _api.json('GET', '/chat/sessions') as List;
    return data.map((j) => ChatSessionModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessageModel>> history(String sessionId) async {
    final data = await _api.json('GET', '/chat/$sessionId/history') as List;
    return data.map((j) => ChatMessageModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Sends the student's message and returns the tutor's reply.
  Future<ChatMessageModel> send(String sessionId, String content, {String? context}) async {
    final data = await _api.json(
      'POST',
      '/chat/$sessionId/message',
      body: {'content': content, if (context != null) 'lessonTitle': context},
      timeout: const Duration(seconds: 60),
    );
    return ChatMessageModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String sessionId) => _api.json('DELETE', '/chat/$sessionId');
}
