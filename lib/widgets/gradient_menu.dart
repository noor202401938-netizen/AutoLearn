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
    final items = [
      {
        'title': 'Home',
        'icon': Icons.home_outlined,
        'colors': const [Color(0xFFa955ff), Color(0xFFea51ff)],
      },
      {
        'title': 'Courses',
        'icon': Icons.school_outlined,
        'colors': const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
      },
      {
        'title': 'Progress',
        'icon': Icons.show_chart_outlined,
        'colors': const [Color(0xFFFF9966), Color(0xFFFF5E62)],
      },
      {
        'title': 'Profile',
        'icon': Icons.person_outline,
        'colors': const [Color(0xFF80FF72), Color(0xFF7EE8FA)],
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = selectedIndex == index;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0), // Minimized gap
              child: GestureDetector(
                onTap: () => onItemSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 130.0 : 60.0,
                  height: 60.0,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (item['colors'] as List<Color>)[0].withOpacity(0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Theme.of(context).shadowColor.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                    gradient: isSelected
                        ? LinearGradient(
                            colors: item['colors'] as List<Color>,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          (item['title'] as String).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
