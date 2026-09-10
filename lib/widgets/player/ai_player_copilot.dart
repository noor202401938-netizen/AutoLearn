import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../backend/api_client.dart';
import '../premium/skill_badge.dart';

class AiPlayerCopilot extends StatefulWidget {
  final String courseTitle;
  final String lessonTitle;
  final String? lessonContent;
  final VoidCallback? onClose;

  const AiPlayerCopilot({
    super.key,
    required this.courseTitle,
    required this.lessonTitle,
    this.lessonContent,
    this.onClose,
  });

  @override
  State<AiPlayerCopilot> createState() => _AiPlayerCopilotState();
}

class _AiPlayerCopilotState extends State<AiPlayerCopilot> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'content':
          '👋 Hello! I am your AI Study Copilot for **${widget.lessonTitle}**.\n\nAsk me any question about this lesson, or pick a quick action below!',
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userMessage = text.trim();
    _inputController.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final contextPrompt =
          "Lesson: ${widget.lessonTitle}\nContext: ${widget.lessonContent ?? ''}\nQuestion: $userMessage";

      final response = await ApiClient.instance.post('/ai/chat', {
        'message': contextPrompt,
        'history': _messages
            .where((m) => m['role'] != 'system')
            .map((m) => {'role': m['role']!, 'content': m['content']!})
            .toList(),
      });

      String reply =
          '💡 In ${widget.lessonTitle}, focus on understanding the core definitions and their practical applications.';

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['response'] != null) {
          reply = data['response'];
        }
      }

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                '💡 **Key Takeaway**: This lesson on ${widget.lessonTitle} focuses on the foundational economic models. Practice calculating these equilibrium points.',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF071514) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF15302C) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D2220) : const Color(0xFFF8F7F4),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF15302C) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004741),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.sparkles, color: Color(0xFFF0EDE4), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Study Copilot',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741),
                        ),
                      ),
                      Text(
                        'Context: ${widget.lessonTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(CupertinoIcons.xmark, size: 16),
                  ),
              ],
            ),
          ),

          // Quick Prompt Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                SkillBadge(
                  label: '💡 Explain simply',
                  onTap: () => _sendMessage('Can you explain this lesson in simple terms?'),
                ),
                const SizedBox(width: 6),
                SkillBadge(
                  label: '📝 Key takeaways',
                  onTap: () => _sendMessage('Summarize the 3 key takeaways of this lesson.'),
                ),
                const SizedBox(width: 6),
                SkillBadge(
                  label: '❓ Quiz me',
                  onTap: () => _sendMessage('Give me 2 multiple choice questions to test my understanding.'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: const BoxConstraints(maxWidth: 290),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF004741)
                          : (isDark ? const Color(0xFF0D2220) : const Color(0xFFF0EDE4)),
                      borderRadius: BorderRadius.circular(14),
                      border: isUser
                          ? null
                          : Border.all(
                              color: isDark ? const Color(0xFF22433F) : const Color(0xFFCDC6B5),
                              width: 0.8,
                            ),
                    ),
                    child: Text(
                      message['content'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.4,
                        color: isUser
                            ? const Color(0xFFF0EDE4)
                            : (isDark ? const Color(0xFFF0EDE4) : const Color(0xFF0A2421)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Copilot is thinking...',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D2220) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF15302C) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF071514) : const Color(0xFFF8F7F4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: TextField(
                      controller: _inputController,
                      onSubmitted: _sendMessage,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Ask your copilot anything...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _sendMessage(_inputController.text),
                  icon: const Icon(CupertinoIcons.arrow_up_circle_fill,
                      color: Color(0xFF004741), size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
