// lib/business_logic/ai_tutor_engine.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../repository/chat_repository.dart';
import '../model/chat_message_model.dart';

class AITutorEngine {
  final ChatRepository _chatRepository = ChatRepository();

  // OpenAI API Configuration
  static const String _openAIApiKey =
      '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';
  static const String _openAIApiUrl =
      'https://api.openai.com/v1/chat/completions';

  // System prompt for AI tutor
  static const String _systemPrompt = '''
You are an AI tutor for a learning platform. Your role is to help students learn concepts in a clear, engaging, and supportive way.
Use the provided course context to answer questions accurately. If the user asks something unrelated to the course material, gently guide them back to the relevant topics.

Guidelines:
- Provide clear, concise explanations
- Use examples and analogies when helpful
- Break down complex concepts into simpler parts
- Encourage students and provide positive feedback
- Ask follow-up questions to check understanding
- If you don't know something, admit it and suggest resources
- Keep responses educational and appropriate
- Use a friendly, encouraging tone

Always be helpful, patient, and focused on helping the student learn.
''';

  // Send a message and get AI response
  Future<String> sendMessage({
    required String userId,
    required String userMessage,
    String? sessionId,
    String? courseId,
    String? lessonId,
  }) async {
    try {
      // Get or create session
      final currentSessionId =
          sessionId ?? await _chatRepository.getOrCreateCurrentSession(userId);

      // Save user message
      await _chatRepository.sendMessage(
        userId: userId,
        role: 'user',
        content: userMessage,
        sessionId: currentSessionId,
        courseId: courseId,
        lessonId: lessonId,
      );

      // Get conversation history for context
      final conversationHistory =
          await _buildConversationHistory(currentSessionId);

      // Get AI response
      final aiResponse = await _getAIResponse(userMessage, conversationHistory);

      // Save AI response
      await _chatRepository.sendMessage(
        userId: userId,
        role: 'assistant',
        content: aiResponse,
        sessionId: currentSessionId,
        courseId: courseId,
        lessonId: lessonId,
      );

      return aiResponse;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Build conversation history for context
  Future<List<Map<String, String>>> _buildConversationHistory(
      String sessionId) async {
    try {
      final messages = await _chatRepository.getSessionMessages(sessionId);

      // Convert to OpenAI format (last 10 messages for context)
      final recentMessages = messages.length > 10
          ? messages.sublist(messages.length - 10)
          : messages;

      return recentMessages
          .map((msg) => {
                'role': msg.role,
                'content': msg.content,
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get AI response from OpenAI
  Future<String> _getAIResponse(
    String userMessage,
    List<Map<String, String>> conversationHistory,
  ) async {
    try {
      // Build messages array
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _systemPrompt},
        ...conversationHistory,
        {'role': 'user', 'content': userMessage},
      ];

      // Make API call to OpenAI
      final response = await http.post(
        Uri.parse(_openAIApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final content = responseData['choices'][0]['message']['content'];
        return content.trim();
      } else {
        // Handle API errors
        final errorData = json.decode(response.body);
        throw Exception(
            'OpenAI API error: ${errorData['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      // Return a helpful error message
      if (e.toString().contains('OpenAI API error')) {
        rethrow;
      }
      return 'I apologize, but I\'m having trouble connecting right now. Please try again in a moment.';
    }
  }

  // Get conversation history
  Future<List<ChatMessageModel>> getConversationHistory(
      String sessionId) async {
    try {
      return await _chatRepository.getSessionMessages(sessionId);
    } catch (e) {
      throw Exception('Failed to get conversation history: $e');
    }
  }

  // Watch conversation in real-time
  Stream<List<ChatMessageModel>> watchConversation(String sessionId) {
    return _chatRepository.watchSessionMessages(sessionId);
  }

  // Get or create current session
  Future<String> getOrCreateSession(String userId) async {
    return await _chatRepository.getOrCreateCurrentSession(userId);
  }

  // Get all user sessions
  Future<List<ChatSessionModel>> getUserSessions(String userId) async {
    try {
      return await _chatRepository.getUserSessions(userId);
    } catch (e) {
      throw Exception('Failed to get user sessions: $e');
    }
  }

  // Start a new conversation
  Future<String> startNewConversation(String userId) async {
    try {
      // Create a new session
      final sessionId = await _chatRepository.getOrCreateCurrentSession(userId);
      // Clear any existing messages (optional - you might want to keep them)
      return sessionId;
    } catch (e) {
      throw Exception('Failed to start new conversation: $e');
    }
  }

  // Delete a conversation
  Future<void> deleteConversation(String sessionId) async {
    try {
      await _chatRepository.deleteSession(sessionId);
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }
}
