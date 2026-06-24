import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
// lib/screens/student/ai_tutor_chat_screen.dart
import 'package:flutter/material.dart';
import '../../business_logic/ai_tutor_engine.dart';
import '../../model/chat_message_model.dart';
import '../../repository/auth_repository.dart';

class AITutorChatScreen extends StatefulWidget {
  final String? courseId;
  final String? lessonId;
  
  const AITutorChatScreen({
    super.key,
    this.courseId,
    this.lessonId,
  });

  @override
  State<AITutorChatScreen> createState() => _AITutorChatScreenState();
}

class _AITutorChatScreenState extends State<AITutorChatScreen> {
  final AITutorEngine _aiTutorEngine = AITutorEngine();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _currentSessionId;
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthRepository().getCurrentUser();
      final uid = user?['uid'] as String?;
      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }

      _currentSessionId = await _aiTutorEngine.getOrCreateSession(uid);
      
      if (_currentSessionId != null) {
        _messages = await _aiTutorEngine.getConversationHistory(_currentSessionId!);
        
        _aiTutorEngine.watchConversation(_currentSessionId!).listen((messages) {
          if (mounted) {
            setState(() {
              _messages = messages;
            });
            _scrollToBottom();
          }
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: ')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    final user = await AuthRepository().getCurrentUser();
    final uid = user?['uid'] as String?;
    if (uid == null) return;

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    try {
      await _aiTutorEngine.sendMessage(
        userId: uid,
        userMessage: message,
        sessionId: _currentSessionId,
        courseId: widget.courseId,
        lessonId: widget.lessonId,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: '),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _startNewConversation() async {
    final user = await AuthRepository().getCurrentUser();
    final uid = user?['uid'] as String?;
    if (uid == null) return;

    try {
      final newSessionId = await _aiTutorEngine.startNewConversation(uid);
      setState(() {
        _currentSessionId = newSessionId;
        _messages = [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting new conversation: ')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 1,
        shadowColor: Colors.black12,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: Text(
          'AI Tutor',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4231C0),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF474554)),
            tooltip: 'New Conversation',
            onPressed: _startNewConversation,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFDEE9FC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC8C4D7)),
              ),
              child: const ClipOval(
                child: Icon(Icons.person, color: Color(0xFF5548D3)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: const Color(0xFF4231C0)))
            : Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: _messages.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 24,
                                  bottom: 160,
                                ),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildContextHeader(),
                                        const SizedBox(height: 24),
                                        _buildMessageBubble(_messages[index]),
                                      ],
                                    );
                                  }
                                  return _buildMessageBubble(_messages[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildFloatingInputArea(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildContextHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LEARNING MODULE',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: const Color(0xFF4231C0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.lessonId ?? 'Advanced Prototyping',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF121C2A),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContextHeader(),
            const SizedBox(height: 48),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9DDFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD0BCFF)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8455EF).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 64,
                  color: Color(0xFF6B38D4),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'AI Tutor',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF121C2A),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Ask me anything about your subjects!\nI\'m here to help you learn.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF474554),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: isUser ? _buildUserMessage(message) : _buildAIMessage(message),
    );
  }

  Widget _buildUserMessage(ChatMessageModel message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4ED9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B4ED9).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE2DEFF),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _formatTime(message.timestamp),
          style: GoogleFonts.inter(
            color: const Color(0xFF787586),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAIMessage(ChatMessageModel message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF8455EF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI Tutor',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF121C2A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: const Color(0xFFC8C4D7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B4ED9).withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF474554),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFC8C4D7)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.thumb_up_outlined, size: 18),
                    color: const Color(0xFF4231C0),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.thumb_down_outlined, size: 18),
                    color: const Color(0xFF474554),
                    onPressed: () {},
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 18),
                    color: const Color(0xFF474554),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatTime(message.timestamp),
          style: GoogleFonts.inter(
            color: const Color(0xFF787586),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Colors.white.withOpacity(0.8),
          padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSuggestedPrompts(),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EEFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF4231C0)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.inter(color: const Color(0xFF121C2A)),
                        decoration: InputDecoration(
                          hintText: 'Ask AI Tutor anything...',
                          hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF474554).withOpacity(0.5)),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4231C0), Color(0xFF6B38D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.arrow_upward, color: Colors.white),
                        onPressed: _isSending ? null : _sendMessage,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedPrompts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CONTINUE LEARNING',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: const Color(0xFF787586),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSuggestionChip('Smart Animate Tips'),
              const SizedBox(width: 12),
              _buildSuggestionChip('Variables in Prototypes'),
              const SizedBox(width: 12),
              _buildSuggestionChip('Overlay Logic'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF4231C0).withOpacity(0.2)),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: const Color(0xFF4231C0),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return 'm ago';
    } else if (difference.inDays < 1) {
      return 'h ago';
    } else {
      return ':';
    }
  }
}
