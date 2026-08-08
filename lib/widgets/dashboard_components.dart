import 'package:flutter/material.dart';
import '../../model/course_model.dart';

class DashboardCourseCard extends StatelessWidget {
  final CourseModel course;
  final int index;
  final VoidCallback onTap;
  final bool isHorizontal;

  const DashboardCourseCard({
    super.key,
    required this.course,
    required this.index,
    required this.onTap,
    this.isHorizontal = false,
  });

  static Color _getCardColor(ColorScheme colorScheme, int index) {
    switch (index % 5) {
      case 0: return colorScheme.primaryContainer;
      case 1: return colorScheme.tertiaryContainer;
      case 2: return colorScheme.primaryContainer;
      case 3: return colorScheme.secondaryContainer;
      case 4: return colorScheme.primaryContainer;
      default: return colorScheme.primaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = _getCardColor(colorScheme, index);
    final isDark = theme.brightness == Brightness.dark;

    if (isHorizontal) {
      return _buildHorizontalCard(context, theme, colorScheme, bgColor, isDark);
    }

    return _buildGridCard(context, theme, colorScheme, bgColor, isDark);
  }

  Widget _buildGridCard(BuildContext context, ThemeData theme, ColorScheme colorScheme, Color bgColor, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: isDark ? 0.2 : 1.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.play_circle_rounded, size: 22, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: colorScheme.tertiary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      course.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.15,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${course.enrollmentCount} students',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.surface.withValues(alpha: isDark ? 0.2 : 1.0),
                  child: Icon(Icons.person, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context, ThemeData theme, ColorScheme colorScheme, Color bgColor, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: isDark ? 0.2 : 1.0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.play_circle_rounded, size: 24, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: colorScheme.tertiary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${course.enrollmentCount} students',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4), size: 20),
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
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat == 'All';
          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (bool value) {},
              backgroundColor: colorScheme.surface,
              selectedColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ActivityChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<double> monthlyData;

  const ActivityChart({
    super.key,
    required this.stats,
    this.monthlyData = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final months = ['Jan', 'Jun', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final lessonsWatched = stats['totalLessonsWatched'] as int? ?? 0;
    final totalHours = (lessonsWatched * 0.5).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text('Year', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '${totalHours}h',
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 28),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Great result!',
                style: TextStyle(fontSize: 11, color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(months.length, (index) {
              final dataValue = (index < monthlyData.length) ? monthlyData[index] : 0.0;
              final height = 4.0 + (dataValue * 20);
              final isCurrent = index == months.length - 1;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 24,
                    height: height,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? colorScheme.primary
                          : DashboardCourseCard._getCardColor(colorScheme, index),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    months[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrent ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
