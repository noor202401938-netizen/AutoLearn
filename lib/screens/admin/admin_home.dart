// lib/screens/admin/admin_home.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../repository/auth_repository.dart';
import '../../widgets/student_home/ambient_background.dart';
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
  final AuthRepository _authRepository = AuthRepository();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: null, // Removed top AppBar to merge action controls directly into layout
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: colorScheme.surface,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurfaceVariant,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.square_grid_2x2),
                  activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.waveform_path_ecg),
                  activeIcon: Icon(CupertinoIcons.waveform_path_ecg),
                  label: 'Analytics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.bell),
                  activeIcon: Icon(CupertinoIcons.bell_fill),
                  label: 'Alerts',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person_2),
                  activeIcon: Icon(CupertinoIcons.person_2_fill),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.book),
                  activeIcon: Icon(CupertinoIcons.book_fill),
                  label: 'Courses',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.creditcard),
                  activeIcon: Icon(CupertinoIcons.creditcard_fill),
                  label: 'Financials',
                ),
              ],
            )
          : null,
      body: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            const AmbientBackground(),
            Row(
              children: [
                if (!isMobile) _buildAdminSidebar(colorScheme, theme),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: SafeArea(
                        child: _getSelectedScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSidebar(ColorScheme colorScheme, ThemeData theme) {
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Dashboard', 'icon': CupertinoIcons.square_grid_2x2, 'selectedIcon': CupertinoIcons.square_grid_2x2_fill},
      {'title': 'Analytics', 'icon': CupertinoIcons.waveform_path_ecg, 'selectedIcon': CupertinoIcons.waveform_path_ecg},
      {'title': 'Alerts', 'icon': CupertinoIcons.bell, 'selectedIcon': CupertinoIcons.bell_fill},
      {'title': 'Users', 'icon': CupertinoIcons.person_2, 'selectedIcon': CupertinoIcons.person_2_fill},
      {'title': 'Courses', 'icon': CupertinoIcons.book, 'selectedIcon': CupertinoIcons.book_fill},
      {'title': 'Financials', 'icon': CupertinoIcons.creditcard, 'selectedIcon': CupertinoIcons.creditcard_fill},
    ];

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        border: Border(
          right: BorderSide(color: colorScheme.outline),
        ),
      ),
      child: Column(
        children: [
          // Logo Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(CupertinoIcons.shield, color: colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AutoLearn Admin',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation Menu List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = _currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item['selectedIcon'] : item['icon'],
                            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            item['title'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Role & Exit Actions Card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Role: Super Admin',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'System administration panel active.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () async {
                        await _authRepository.logoutUser();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.2)),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.square_arrow_right, size: 14),
                          SizedBox(width: 6),
                          Text('Log Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
