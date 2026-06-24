import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_courses_screen.dart';
import 'admin_finance_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_announcements_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminAnalyticsScreen(),
    const AdminAnnouncementsScreen(),
    const AdminUsersScreen(),
    const AdminCoursesScreen(),
    const AdminFinanceScreen(),
  ];

  Widget _getSelectedScreen() {
    return _screens[_currentIndex];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 1,
        shadowColor: colorScheme.shadow,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 2),
                color: colorScheme.primaryContainer,
              ),
              child: Icon(Icons.person, color: colorScheme.onPrimaryContainer, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'AutoLearn Admin',
              style: GoogleFonts.geist(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: colorScheme.primary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop) ...[
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onItemTapped,
                labelType: NavigationRailLabelType.all,
                backgroundColor: colorScheme.surface,
                selectedIconTheme: IconThemeData(color: colorScheme.primary),
                unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
                selectedLabelTextStyle: GoogleFonts.inter(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelTextStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 12),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(Icons.analytics),
                    label: Text('Analytics'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.notifications_outlined),
                    selectedIcon: Icon(Icons.notifications),
                    label: Text('Alerts'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.group_outlined),
                    selectedIcon: Icon(Icons.group),
                    label: Text('Users'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.school_outlined),
                    selectedIcon: Icon(Icons.school),
                    label: Text('Courses'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.payments_outlined),
                    selectedIcon: Icon(Icons.payments),
                    label: Text('Financials'),
                  ),
                ],
              ),
              VerticalDivider(thickness: 1, width: 1, color: Theme.of(context).dividerColor),
            ],
            Expanded(
              child: _getSelectedScreen(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: colorScheme.surface,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurfaceVariant,
              showUnselectedLabels: true,
              selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined),
                  activeIcon: Icon(Icons.analytics),
                  label: 'Analytics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_outlined),
                  activeIcon: Icon(Icons.notifications),
                  label: 'Alerts',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_outlined),
                  activeIcon: Icon(Icons.group),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.school_outlined),
                  activeIcon: Icon(Icons.school),
                  label: 'Courses',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payments_outlined),
                  activeIcon: Icon(Icons.payments),
                  label: 'Financials',
                ),
              ],
            ),
    );
  }
}
