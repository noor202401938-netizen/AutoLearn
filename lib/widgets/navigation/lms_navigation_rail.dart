import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class LmsNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const LmsNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isExpanded = true,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final destinations = [
      _NavDestination(icon: CupertinoIcons.home, label: 'Dashboard'),
      _NavDestination(icon: CupertinoIcons.compass, label: 'Explore Courses'),
      _NavDestination(icon: CupertinoIcons.play_rectangle, label: 'My Learning'),
      _NavDestination(icon: CupertinoIcons.rosette, label: 'Certificates'),
      _NavDestination(icon: CupertinoIcons.chat_bubble_2, label: 'AI Study Copilot'),
      _NavDestination(icon: CupertinoIcons.person, label: 'My Profile'),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 240 : 72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF071514) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF15302C) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: destinations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final item = destinations[index];
                final isSelected = selectedIndex == index;

                return InkWell(
                  onTap: () => onDestinationSelected(index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(
                      horizontal: isExpanded ? 14 : 0,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF004741).withOpacity(isDark ? 0.35 : 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: const Color(0xFF004741).withOpacity(0.3),
                              width: 1.0,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment:
                          isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isSelected
                              ? const Color(0xFF004741)
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                        if (isExpanded) ...[
                          const SizedBox(width: 12),
                          Text(
                            item.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741))
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (onToggleExpand != null) ...[
            const Divider(height: 1),
            ListTile(
              onTap: onToggleExpand,
              leading: Icon(
                isExpanded ? CupertinoIcons.chevron_left_2 : CupertinoIcons.chevron_right_2,
                size: 18,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              title: isExpanded
                  ? Text(
                      'Collapse Rail',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    )
                  : null,
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final String label;
  const _NavDestination({required this.icon, required this.label});
}
