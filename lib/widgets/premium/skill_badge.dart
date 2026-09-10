import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SkillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback? onTap;

  const SkillBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = color ?? theme.colorScheme.primary;

    final bgColor = isSelected
        ? primaryColor
        : (isDark ? const Color(0xFF152E2B) : const Color(0xFFE8E5DC));

    final textColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741));

    final borderColor = isSelected
        ? primaryColor
        : (isDark ? const Color(0xFF22433F) : const Color(0xFFCDC6B5));

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: child,
      );
    }
    return child;
  }
}
