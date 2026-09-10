import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakIndicator extends StatelessWidget {
  final int streakDays;
  final int weeklyGoalHours;
  final double currentWeeklyHours;

  const StreakIndicator({
    super.key,
    this.streakDays = 4,
    this.weeklyGoalHours = 5,
    this.currentWeeklyHours = 3.5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (currentWeeklyHours / (weeklyGoalHours > 0 ? weeklyGoalHours : 1)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2220) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flame Streak Badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9900), Color(0xFFFF5E00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(CupertinoIcons.flame_fill, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '$streakDays Day Streak',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF0A2421),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.sparkles, size: 13, color: Color(0xFFFF9900)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${currentWeeklyHours.toStringAsFixed(1)} of ${weeklyGoalHours}h this week',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Circular Progress Indicator
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3.5,
                  backgroundColor: isDark ? const Color(0xFF15302C) : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
