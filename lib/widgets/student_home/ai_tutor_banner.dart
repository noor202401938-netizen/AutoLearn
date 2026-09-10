import 'package:flutter/material.dart';

class AITutorBanner extends StatefulWidget {
  final VoidCallback onTap;

  const AITutorBanner({super.key, required this.onTap});

  @override
  State<AITutorBanner> createState() => _AITutorBannerState();
}

class _AITutorBannerState extends State<AITutorBanner> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.008 : 1.0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  Color.lerp(colorScheme.primary, Colors.black, 0.15)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: _isHovered ? 0.35 : 0.2),
                  blurRadius: _isHovered ? 28 : 18,
                  offset: Offset(0, _isHovered ? 12 : 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Minimalist geometric watermark
                Positioned(
                  right: -24,
                  bottom: -24,
                  child: Opacity(
                    opacity: 0.08,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 180,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Capsule pill badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.onPrimary.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'AI MENTOR • 24/7',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Instant Economic Insights & Tutoring',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Text(
                          'Ask conceptual questions, generate practice quizzes, and analyze real-world market scenarios with your personalized AI tutor.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.82),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Action pill button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Start Conversation',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedSlide(
                              offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

