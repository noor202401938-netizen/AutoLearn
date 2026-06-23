import 'package:flutter/material.dart';
import '../../model/course_model.dart';
import 'dart:math';

class DashboardColors {
  static const Color pinkCardLight = Color(0xFFFFD6DE);
  static const Color pinkCardDark = Color(0xFF6B3A45);
  
  static const Color orangeCardLight = Color(0xFFFFE8D6);
  static const Color orangeCardDark = Color(0xFF6B533A);
  
  static const Color blueCardLight = Color(0xFFD6E4FF);
  static const Color blueCardDark = Color(0xFF3A4B6B);
  
  static const Color greenCardLight = Color(0xFFD6FFED);
  static const Color greenCardDark = Color(0xFF3A6B53);

  static Color getCardColor(BuildContext context, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (index % 4) {
      case 0: return isDark ? pinkCardDark : pinkCardLight;
      case 1: return isDark ? orangeCardDark : orangeCardLight;
      case 2: return isDark ? blueCardDark : blueCardLight;
      case 3: return isDark ? greenCardDark : greenCardLight;
      default: return isDark ? pinkCardDark : pinkCardLight;
    }
  }
}

class DashboardCourseCard extends StatelessWidget {
  final CourseModel course;
  final int index;
  final VoidCallback onTap;

  const DashboardCourseCard({
    super.key,
    required this.course,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = DashboardColors.getCardColor(context, index);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.2 : 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.computer, size: 20, color: textColor),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      course.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${course.enrollmentCount} students',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 16, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FilterChips extends StatelessWidget {
  final List<String> categories = ['All', 'IT & Software', 'Media Training', 'Business', 'Interior'];
  
  FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat == 'All';
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected 
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white : Colors.black87),
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              onSelected: (bool value) {},
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              selectedColor: isDark ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ActivityChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<double> monthlyData; // Array of 7 values for the months

  const ActivityChart({
    super.key,
    required this.stats,
    this.monthlyData = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardBgColor = isDark ? Colors.grey[900] : Colors.white;
    final months = ['Jan', 'Jun', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // Calculate total hours based on totalLessonsWatched (assuming 0.5h per lesson as an estimate if no exact time is available, but let's use actual data or 0)
    final lessonsWatched = stats['totalLessonsWatched'] as int? ?? 0;
    final totalHours = (lessonsWatched * 0.5).toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text('Year', style: TextStyle(fontSize: 12, color: textColor)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: textColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${totalHours}h',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Great result!',
                  style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar Chart mock
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(months.length, (index) {
                // Ensure we don't go out of bounds and provide a minimum height of 4.0 for visibility of 0
                final dataValue = (index < monthlyData.length) ? monthlyData[index] : 0.0;
                final height = 4.0 + (dataValue * 20); // Scale data for display
                final isCurrent = index == months.length - 1;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 24,
                      height: height,
                      decoration: BoxDecoration(
                        color: isCurrent 
                            ? (isDark ? Colors.white : Colors.black)
                            : DashboardColors.getCardColor(context, index),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      months[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrent ? textColor : textColor.withOpacity(0.5),
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
