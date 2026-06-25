
// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';

import '../../repository/user_repository.dart';
import '../../repository/auth_repository.dart';

import '../../business_logic/course_manager.dart';

import '../../business_logic/analytics_monitoring_manager.dart';

import '../../model/course_model.dart';
import '../../backend/api_client.dart';

import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../notifications_panel.dart';

import '../theme_accessibility_screen.dart';

import 'admin_profile_screen.dart';

import 'admin_course_management.dart';
import 'admin_payment_management.dart';
import 'admin_notification_management.dart';
import '../../widgets/admin_dashboard_components.dart';
import '../../widgets/gradient_bottom_nav.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _authRepository = AuthRepository();
  final CourseManager _courseManager = CourseManager();
  final AnalyticsMonitoringManager _analyticsManager = AnalyticsMonitoringManager();

  int _selectedIndex = 0;
  Map<String, dynamic> _analyticsData = {};
  bool _isLoadingAnalytics = false;
  List<CourseModel> _analyticsCourses = [];
  List<dynamic> _analyticsPayments = [];
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      final uid = user['uid'] as String?;
      if (uid != null) {
        final profile = await _authRepository.getUserProfile(uid);
        if (mounted) {
          setState(() {
            _adminName = profile?['displayName'] ?? profile?['email']?.split('@')[0] ?? 'Admin';
          });
        }
      }
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoadingAnalytics = true);
    try {
      final response = await ApiClient.instance.get('/admin/analytics');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _analyticsData = {
              'totalCourses': data['totalCourses'] ?? 0,
              'publishedCourses': data['publishedCourses'] ?? 0,
              'totalUsers': data['totalUsers'] ?? 0,
              'totalEnrollments': data['totalEnrollments'] ?? 0,
              'totalRevenue': (data['totalRevenue'] ?? 0).toDouble(),
            };
            
            // Map course data to a format compatible with our UI
            if (data['courses'] != null) {
              _analyticsCourses = (data['courses'] as List).map((c) => CourseModel(
                courseId: c['id'] ?? '',
                title: c['title'] ?? '',
                description: '',
                instructor: '',
                category: '',
                level: '',
                duration: 0,
                thumbnailURL: '',
                price: 0,
                enrollmentCount: c['enrollmentCount'] ?? 0,
                createdAt: DateTime.now(),
                createdBy: '',
              )).toList();
            }
            _isLoadingAnalytics = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingAnalytics = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAnalytics = false);
      }
    }
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewScreen();
      case 1:
        return _buildUsersScreen();
      case 2:
        return _buildCoursesScreen();
      case 3:
        return const AdminNotificationManagement();
      case 4:
        return const AdminPaymentManagement();
      case 5:
        return _buildAnalyticsScreen();
      default:
        return _buildOverviewScreen();
    }
  }

  String _analyticsSortBy = 'popular'; // 'popular', 'unpopular', 'highest_rated', 'lowest_rated'

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background for the main area
      bottomNavigationBar: isMobile
          ? GradientBottomNav(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemTapped,
              menuItems: [
                {
                  'title': 'Dash',
                  'icon': Icons.dashboard_outlined,
                  'selectedIcon': Icons.dashboard,
                  'colors': [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
                },
                {
                  'title': 'Users',
                  'icon': Icons.people_outline,
                  'selectedIcon': Icons.people,
                  'colors': [const Color(0xFFa955ff), const Color(0xFFea51ff)],
                },
                {
                  'title': 'Courses',
                  'icon': Icons.school_outlined,
                  'selectedIcon': Icons.school,
                  'colors': [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
                },
                {
                  'title': 'Notifs',
                  'icon': Icons.campaign_outlined,
                  'selectedIcon': Icons.campaign,
                  'colors': [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
                },
                {
                  'title': 'Pay',
                  'icon': Icons.payment_outlined,
                  'selectedIcon': Icons.payment,
                  'colors': [const Color(0xFF80FF72), const Color(0xFF7EE8FA)],
                },
                {
                  'title': 'Stats',
                  'icon': Icons.analytics_outlined,
                  'selectedIcon': Icons.analytics,
                  'colors': [const Color(0xFFF7971E), const Color(0xFFFFD200)],
                },
              ],
            )
          : null,
      body: Row(
        children: [
          // FULL HEIGHT SIDEBAR (DARK THEME)
          if (!isMobile)
            Container(
            color: const Color(0xFF222E3C), // Dark blue/black sidebar
            child: NavigationRail(
              backgroundColor: Colors.transparent,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              selectedIconTheme: const IconThemeData(color: Colors.blueAccent),
              unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.5)),
              selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 8),
                    if (MediaQuery.of(context).size.width > 800)
                      const Text(
                        'AdminKit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton(
                          color: Colors.white,
                          offset: const Offset(50, 0),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: Colors.black54),
                                  SizedBox(width: 8),
                                  Text('Profile', style: TextStyle(color: Colors.black87)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Logout', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'profile') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminProfileScreen(),
                                ),
                              );
                            } else if (value == 'logout') {
                              await _authRepository.logoutUser();
                              if (mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            }
                          },
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (MediaQuery.of(context).size.width > 800)
                          Text(
                            _adminName,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.school_outlined),
                  selectedIcon: Icon(Icons.school),
                  label: Text('Courses'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.campaign_outlined),
                  selectedIcon: Icon(Icons.campaign),
                  label: Text('Notifications'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.payment_outlined),
                  selectedIcon: Icon(Icons.payment),
                  label: Text('Payments'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: Text('Analytics'),
                ),
              ],
            ),
          ),
          // MAIN CONTENT AREA (LIGHT THEME)
          Expanded(
            child: Column(
              children: [
                // TOP BAR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Welcome back, $_adminName 👋',
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const Spacer(),
                      // Search bar
                      Container(
                        width: 250,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: Colors.black38, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Notification Icon
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none, color: Colors.black54),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsPanel(),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Profile Menu
                      PopupMenuButton(
                        icon: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blueAccent,
                          child: Text('A', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                        color: Colors.white,
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Colors.black87),
                                SizedBox(width: 8),
                                Text('Profile', style: TextStyle(color: Colors.black87)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Logout', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminProfileScreen(),
                              ),
                            );
                          } else if (value == 'logout') {
                            await _authRepository.logoutUser();
                            if (mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                
                // WORKSPACE
                Expanded(
                  child: _getSelectedScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Overview Screen with AdminKit Data
  Widget _buildOverviewScreen() {
    if (_isLoadingAnalytics) {
      return const Center(child: CircularProgressIndicator());
    }

    int totalUsers = _analyticsData['totalUsers'] ?? 0;
    int activeCourses = _analyticsData['publishedCourses'] ?? 0;
    double totalRevenue = _analyticsData['totalRevenue'] ?? 0.0;
    int totalEnrollments = _analyticsData['totalEnrollments'] ?? 0;

    // Pass real analytics orders/payments here when connected to backend
    final List<Map<String, dynamic>> realOrders = [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 2 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                children: [
                  MetricCard(
                    title: 'Total Revenue',
                    value: '\$${totalRevenue.toStringAsFixed(0)}',
                    percentage: '12.5%',
                    isPositive: true,
                    icon: Icons.attach_money,
                    iconBgColor: Colors.blue.withOpacity(0.1),
                    iconColor: Colors.blue,
                  ),
                  MetricCard(
                    title: 'Total Enrollments',
                    value: totalEnrollments.toString(),
                    percentage: '8.2%',
                    isPositive: true,
                    icon: Icons.school,
                    iconBgColor: Colors.green.withOpacity(0.1),
                    iconColor: Colors.green,
                  ),
                  MetricCard(
                    title: 'Total Users',
                    value: totalUsers.toString(),
                    percentage: '5.1%',
                    isPositive: true,
                    icon: Icons.people,
                    iconBgColor: Colors.purple.withOpacity(0.1),
                    iconColor: Colors.purple,
                  ),
                  MetricCard(
                    title: 'Active Courses',
                    value: activeCourses.toString(),
                    percentage: '3.4%',
                    isPositive: false,
                    icon: Icons.book,
                    iconBgColor: Colors.orange.withOpacity(0.1),
                    iconColor: Colors.orange,
                  ),
                ],
              );
            }
          ),
          const SizedBox(height: 24),
          
          // Charts Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1000;
              return isWide 
                ? Row(
                    children: [
                      const Expanded(flex: 3, child: RevenueLineChart()),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: CategoryBarChart(courses: _analyticsCourses)),
                    ],
                  )
                : Column(
                    children: [
                      const RevenueLineChart(),
                      const SizedBox(height: 24),
                      CategoryBarChart(courses: _analyticsCourses),
                    ],
                  );
            }
          ),
          const SizedBox(height: 24),

          // Recent Orders Table
          RecentOrdersTable(orders: realOrders),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
      String title,
      String subtitle,
      String time,
      IconData icon,
      Color color,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Users Management Screen with Real-time Data
  Widget _buildUsersScreen() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userRepository.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Error loading users', style: TextStyle(fontSize: 18, color: Colors.red.shade400)),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header with count
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'User Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
                    ),
                    child: Text(
                      '${users.length} users',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // User List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return _buildUserCard(users[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData) {
    final role = userData['role'] ?? 'student';
    final isActive = userData['isActive'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    (userData['displayName'] ?? userData['email'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['displayName'] ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData['email'] ?? 'No Email',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: role == 'admin'
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: role == 'admin'
                          ? Colors.orange.withOpacity(0.5)
                          : Colors.blue.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: role == 'admin' ? Colors.orange : Colors.lightBlueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? Colors.green.withOpacity(0.5)
                          : Colors.red.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: Colors.lightBlueAccent,
                  onPressed: () => _showEditUserDialog(userData),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  color: Colors.redAccent,
                  onPressed: () => _showDeleteConfirmation(userData),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> userData) {
    String selectedRole = userData['role'] ?? 'student';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userData['email'] ?? 'No Email',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Select Role:'),
            const SizedBox(height: 10),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Student'),
                    value: 'student',
                    groupValue: selectedRole,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) {
                      setState(() => selectedRole = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Admin'),
                    value: 'admin',
                    groupValue: selectedRole,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) {
                      setState(() => selectedRole = value!);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              await _userRepository.updateUserRole(
                userData['id'] ?? userData['uid'],
                selectedRole,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User role updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${userData['email']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await _userRepository.deleteUserProfile(userData['id'] ?? userData['uid']);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Courses Screen - AdminCourseManagement
  Widget _buildCoursesScreen() {
    return const AdminCourseManagement();
  }

  // Analytics Screen
  Widget _buildAnalyticsScreen() {
    if (_isLoadingAnalytics) {
      return const Center(child: CircularProgressIndicator());
    }

    List<CourseModel> sortedCourses = List<CourseModel>.from(_analyticsCourses);
    switch (_analyticsSortBy) {
      case 'popular':
        sortedCourses.sort((a, b) => b.enrollmentCount.compareTo(a.enrollmentCount));
        break;
      case 'unpopular':
        sortedCourses.sort((a, b) => a.enrollmentCount.compareTo(b.enrollmentCount));
        break;
      case 'highest_rated':
        sortedCourses.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest_rated':
        sortedCourses.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }
    
    final limitedCourses = sortedCourses.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Analytics Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _analyticsSortBy,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.sort, color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'popular', child: Text('Most Popular')),
                      DropdownMenuItem(value: 'unpopular', child: Text('Least Popular')),
                      DropdownMenuItem(value: 'highest_rated', child: Text('Highest Rated')),
                      DropdownMenuItem(value: 'lowest_rated', child: Text('Lowest Rated')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _analyticsSortBy = value;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Courses',
                  '${_analyticsData['totalCourses'] ?? 0}',
                  Icons.school,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Published',
                  '${_analyticsData['publishedCourses'] ?? 0}',
                  Icons.public,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  '${_analyticsData['totalUsers'] ?? 0}',
                  Icons.people,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Enrollments',
                  '${_analyticsData['totalEnrollments'] ?? 0}',
                  Icons.how_to_reg,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Enrollments Chart
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enrollments by Course',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (limitedCourses.isEmpty)
                    Text(
                      'Not enough data yet. Create and publish courses to see performance.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    )
                  else
                    SizedBox(
                      height: 240,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (limitedCourses
                                      .map((c) => c.enrollmentCount)
                                      .fold<int>(0,
                                          (prev, e) => e > prev ? e : prev)
                                      .toDouble() *
                                  1.2)
                              .clamp(5.0, double.infinity),
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= limitedCourses.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final title =
                                      limitedCourses[index].title;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      title,
                                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.white.withOpacity(0.1),
                              strokeWidth: 1,
                            ),
                          ),
                          barGroups: List.generate(limitedCourses.length,
                              (index) {
                            final course = limitedCourses[index];
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: course.enrollmentCount.toDouble(),
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Ratings Chart
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Average Ratings by Course',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (limitedCourses.isEmpty)
                    Text(
                      'Not enough data yet.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    )
                  else
                    SizedBox(
                      height: 240,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 5.0, // Max rating is 5
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= limitedCourses.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final title =
                                      limitedCourses[index].title;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      title,
                                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  if (value % 1 != 0) return const SizedBox.shrink();
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
                                  );
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.white.withOpacity(0.1),
                              strokeWidth: 1,
                            ),
                          ),
                          barGroups: List.generate(limitedCourses.length,
                              (index) {
                            final course = limitedCourses[index];
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: course.rating,
                                  color: Colors.orangeAccent,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // Payments Chart
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Payments Received (Succeeded)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_analyticsPayments.isEmpty)
                    Text(
                      'No payment data available.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    )
                  else
                    SizedBox(
                      height: 240,
                      child: Builder(
                        builder: (context) {
                          // Group payments by date (last 7 days)
                          final Map<String, double> revenueByDate = {};
                          final now = DateTime.now();
                          for (int i = 6; i >= 0; i--) {
                            final date = now.subtract(Duration(days: i));
                            final dateStr = DateFormat('MM/dd').format(date);
                            revenueByDate[dateStr] = 0;
                          }
                          
                          for (var p in _analyticsPayments) {
                            if (p['status'] == 'succeeded' && p['createdAt'] != null) {
                              final date = DateTime.parse(p['createdAt']).toLocal();
                              final diff = now.difference(date).inDays;
                              if (diff <= 6 && diff >= 0) {
                                final dateStr = DateFormat('MM/dd').format(date);
                                revenueByDate[dateStr] = (revenueByDate[dateStr] ?? 0) + (p['amount'] as num).toDouble();
                              }
                            }
                          }
                          
                          final dates = revenueByDate.keys.toList();
                          final maxRevenue = revenueByDate.values.isEmpty ? 10.0 : revenueByDate.values.reduce((a, b) => a > b ? a : b);
                          
                          return BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (maxRevenue * 1.2).clamp(10.0, double.infinity),
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          dates[index],
                                          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 36,
                                    getTitlesWidget: (value, meta) {
                                      if (value % (maxRevenue / 4).ceil() != 0) return const SizedBox.shrink();
                                      return Text(
                                        '\$${value.toInt()}',
                                        style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white.withOpacity(0.1),
                                  strokeWidth: 1,
                                ),
                              ),
                              barGroups: List.generate(dates.length, (index) {
                                final revenue = revenueByDate[dates[index]] ?? 0;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: revenue,
                                      color: Colors.greenAccent,
                                      width: 18,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          );
                        }
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

