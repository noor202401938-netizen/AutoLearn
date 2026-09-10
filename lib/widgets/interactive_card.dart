import 'package:flutter/material.dart';

/// A premium minimalist card with subtle hover micro-interactions,
/// tactile tap feedback, and smooth entrance animation.
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool hasBorder;
  final Duration animationDuration;
  final int entranceDelayMs;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 18,
    this.hasBorder = true,
    this.animationDuration = const Duration(milliseconds: 220),
    this.entranceDelayMs = 0,
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.entranceDelayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.entranceDelayMs), () {
        if (mounted) _entranceController.forward();
      });
    } else {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = widget.backgroundColor ?? colorScheme.surface;
    final border = widget.borderColor ?? colorScheme.outlineVariant;

    final scale = _isPressed ? 0.982 : (_isHovered && widget.onTap != null ? 1.008 : 1.0);
    final translateY = (_isHovered && widget.onTap != null) ? -3.0 : 0.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: widget.margin ?? EdgeInsets.zero,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              child: AnimatedScale(
                scale: scale,
                duration: widget.animationDuration,
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: widget.animationDuration,
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(0, translateY, 0),
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: widget.hasBorder
                        ? Border.all(
                            color: _isHovered && widget.onTap != null
                                ? colorScheme.primary.withValues(alpha: 0.4)
                                : border,
                            width: 1.0,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: _isHovered && widget.onTap != null
                            ? colorScheme.primary.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: _isHovered && widget.onTap != null ? 24 : 12,
                        offset: Offset(0, _isHovered && widget.onTap != null ? 8 : 4),
                      ),
                    ],
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
