import 'package:flutter/material.dart';

class GradientBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const GradientBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Home',
        'icon': Icons.home_outlined,
        'selectedIcon': Icons.home,
        'colors': [const Color(0xFFa955ff), const Color(0xFFea51ff)],
      },
      {
        'title': 'Courses',
        'icon': Icons.school_outlined,
        'selectedIcon': Icons.school,
        'colors': [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
      },
      {
        'title': 'Progress',
        'icon': Icons.show_chart_outlined,
        'selectedIcon': Icons.show_chart,
        'colors': [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
      },
      {
        'title': 'Profile',
        'icon': Icons.person_outline,
        'selectedIcon': Icons.person,
        'colors': [const Color(0xFF80FF72), const Color(0xFF7EE8FA)],
      },
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(menuItems.length, (index) {
          final isSelected = selectedIndex == index;
          final item = menuItems[index];
          final colors = item['colors'] as List<Color>;

          return GestureDetector(
            onTap: () => onItemSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 0,
                vertical: 8,
              ),
              width: isSelected ? 120 : 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isSelected
                    ? LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors[0].withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? item['selectedIcon'] : item['icon'],
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
