import 'package:flutter/material.dart';
import 'dart:ui';

class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: theme.colorScheme.surface),
        ),
        // Primary Ambient Blob
        Positioned(
          top: -20,
          left: -20,
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.05, end: 0.15).animate(_controller),
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        // Secondary Ambient Blob
        Positioned(
          bottom: -10,
          right: 10,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0),
              end: const Offset(0, -0.2),
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOutSine,
            )),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.05, end: 0.15).animate(_controller),
              child: Container(
                width: 192,
                height: 192,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF6b38d4), // secondary color
                ),
              ),
            ),
          ),
        ),
        // Heavy blur over everything
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
