import 'package:flutter/material.dart';

class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool enableHoverEffect;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.borderColor,
    this.enableHoverEffect = true,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark ? const Color(0xFF0D2220) : Colors.white;
    final defaultBorder = isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0);
    final hoverBorder = theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) {
        if (widget.enableHoverEffect) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.enableHoverEffect) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: widget.margin,
        transform: _isHovered
            ? (Matrix4.identity()..translate(0.0, -3.0, 0.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? defaultBg,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isHovered ? hoverBorder : (widget.borderColor ?? defaultBorder),
            width: _isHovered ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? hoverBorder.withOpacity(0.12)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: _isHovered ? 16 : 10,
              offset: _isHovered ? const Offset(0, 8) : const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            hoverColor: Colors.transparent,
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(16.0),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
