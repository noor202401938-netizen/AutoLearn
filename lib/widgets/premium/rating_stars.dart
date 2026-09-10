import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int ratingCount;
  final double starSize;
  final bool showCount;
  final bool showBadge;

  const RatingStars({
    super.key,
    required this.rating,
    this.ratingCount = 0,
    this.starSize = 14.0,
    this.showCount = true,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFE5A100);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBadge) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: goldColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: goldColor.withOpacity(0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              rating > 0 ? rating.toStringAsFixed(1) : 'New',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFFFD56B) : const Color(0xFF8C6200),
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
        ...List.generate(5, (index) {
          final currentStar = index + 1;
          if (rating >= currentStar) {
            return Icon(CupertinoIcons.star_fill, size: starSize, color: goldColor);
          } else if (rating >= currentStar - 0.5) {
            return Icon(CupertinoIcons.star_lefthalf_fill, size: starSize, color: goldColor);
          } else {
            return Icon(CupertinoIcons.star, size: starSize, color: goldColor.withOpacity(0.35));
          }
        }),
        if (showCount && ratingCount > 0) ...[
          const SizedBox(width: 5),
          Text(
            '($ratingCount)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ],
    );
  }
}
