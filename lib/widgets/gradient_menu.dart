import 'package:flutter/material.dart';

class GradientMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const GradientMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = [
      {
        'title': 'Home',
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home_rounded,
      },
      {
        'title': 'Courses',
        'icon': Icons.school_outlined,
        'activeIcon': Icons.school_rounded,
      },
      {
        'title': 'Progress',
        'icon': Icons.show_chart_outlined,
        'activeIcon': Icons.show_chart_rounded,
      },
      {
        'title': 'Profile',
        'icon': Icons.person_outline,
        'activeIcon': Icons.person_rounded,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;

              return GestureDetector(
                onTap: () => onItemSelected(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? (item['activeIcon'] as IconData) : (item['icon'] as IconData),
                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.26,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
