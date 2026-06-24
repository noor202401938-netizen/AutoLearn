// lib/screens/student/student_home.dart
import 'package:flutter/material.dart';
import '../../business_logic/auth_manager.dart';
import '../../business_logic/course_manager.dart';
import '../../repository/auth_repository.dart';
import '../../model/course_model.dart';
import '../../screens/student/course_list_screen.dart';
import '../../screens/student/course_content_screen.dart';
import '../../business_logic/analytics_monitoring_manager.dart';
import '../../widgets/gradient_menu.dart';
import '../../widgets/dashboard_components.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final AuthManager _authManager = AuthManager();
  final AuthRepository _authRepository = AuthRepository();
  final CourseManager _courseManager = CourseManager();
  final AnalyticsMonitoringManager _analyticsManager = AnalyticsMonitoringManager();

  int _selectedIndex = 0;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic> _stats = {
    'enrolledCourses': 0,
    'completedCourses': 0,
    'totalLessonsWatched': 0,
  };
  List<CourseModel> _featuredCourses = [];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadFeaturedCourses();
  }

  Future<void> _loadUserProfile() async {
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      final uid = user['uid'] as String;
      // The profile might already be fully fetched by getCurrentUser, but we can assign it
      final stats = await _analyticsManager.getUserLearningStats(uid);
      setState(() {
        _userProfile = user;
        _stats = stats;
      });
    }
  }
      });
    }
  }

  Future<void> _loadFeaturedCourses() async {
    setState(() => _isLoadingCourses = true);
    final courses = await _courseManager.getPublishedCourses();
    setState(() {
      _featuredCourses = courses.take(5).toList(); // Show top 5 courses
      _isLoadingCourses = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildCoursesScreen();
      case 2:
        return _buildProgressScreen();
      case 3:
        return _buildProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isMobile
          ? Container(
              
              child: SafeArea(
                child: _getSelectedScreen(),
              ),
            )
          : Row(
              children: [
                _buildCustomSidebar(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                    ),
                    child: SafeArea(
                      child: _selectedIndex == 0 
                          ? _buildDribbbleDashboard()
                          : _getSelectedScreen(),
                    ),
                  ),
                ),
                if (_selectedIndex == 0) ...[
                  Container(
                    width: 1,
                    color: Theme.of(context).dividerColor.withOpacity(0.05),
                  ),
                  SizedBox(
                    width: 320,
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: SafeArea(
                        child: _buildRightSidebar(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: isMobile
          ? GradientMenu(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemTapped,
            )
          : null,
    );
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickStat(
                          'Courses',
                          _stats['enrolledCourses'].toString(),
                          Icons.book_rounded,
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Theme.of(context).dividerColor,
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          'Completed',
                          _stats['completedCourses'].toString(),
                          Icons.check_circle_rounded,
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Theme.of(context).dividerColor,
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          'Lessons',
                          _stats['totalLessonsWatched'].toString(),
                          Icons.play_circle_rounded,
                          Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Continue Learning Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Courses',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedIndex = 1);
                      },
                      child: Text('See All', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoadingCourses
                    ? Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
                    : _featuredCourses.isEmpty
                    ? Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No courses available yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _featuredCourses.length,
                  itemBuilder: (context, index) {
                    return _buildCourseCard(_featuredCourses[index]);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesScreen() {
    return const CourseListScreen();
  }

  Widget _buildProgressScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No progress data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start learning to track your progress',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    final user = _authRepository.getCurrentUser();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Text(
                (_userProfile?['displayName'] ?? _userProfile?['email'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _userProfile?['displayName'] ?? 'Student',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile?['email'] ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          _buildProfileOption(
            'Edit Profile',
            Icons.edit,
                () { Navigator.pushNamed(context, '/edit_profile'); },
          ),
          _buildProfileOption(
            'Change Password',
            Icons.lock_outline,
                () { Navigator.pushNamed(context, '/change_password'); },
          ),
          _buildProfileOption(
            'Notifications',
            Icons.notifications_outlined,
                () { Navigator.pushNamed(context, '/notifications'); },
          ),
          _buildProfileOption(
            'Help & Support',
            Icons.help_outline,
                () { Navigator.pushNamed(context, '/help_support'); },
          ),
          _buildProfileOption(
            'About',
            Icons.info_outline,
                () { Navigator.pushNamed(context, '/about'); },
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                await _authManager.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return DashboardCourseCard(
      course: course,
      index: _featuredCourses.indexOf(course),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseContentScreen(
              courseId: course.courseId,
              title: course.title,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDribbbleDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invest in your\neducation',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          FilterChips(),
          const SizedBox(height: 32),
          Text(
            'Most popular',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _isLoadingCourses
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _featuredCourses.length,
                  itemBuilder: (context, index) {
                    return DashboardCourseCard(
                      course: _featuredCourses[index],
                      index: index,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseContentScreen(
                              courseId: _featuredCourses[index].courseId,
                              title: _featuredCourses[index].title,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardBg = isDark ? const Color(0xFF222E3C) : const Color(0xFFF9FAFC);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: textColor),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: textColor),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    (_userProfile?['displayName'] ?? _userProfile?['email'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userProfile?['displayName'] ?? _userProfile?['email']?.split('@').first ?? 'Student',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Student',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                ActivityChart(stats: _stats),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Text(
                'My courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_featuredCourses.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _featuredCourses.length > 2 ? 2 : _featuredCourses.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DashboardCourseCard(
                    course: _featuredCourses[index],
                    index: index + 2, // Different color indices
                    onTap: () {},
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomSidebar() {
    final bgColor = Theme.of(context).colorScheme.surface;
    final activeBgColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
    final activeTextColor = Theme.of(context).colorScheme.primary;
    final inactiveTextColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Logo / App Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 64),
            _buildSidebarItem(0, Icons.home_outlined, Icons.home, 'Home', activeBgColor, activeTextColor, inactiveTextColor),
            const SizedBox(height: 24),
            _buildSidebarItem(1, Icons.school_outlined, Icons.school, 'Courses', activeBgColor, activeTextColor, inactiveTextColor),
            const SizedBox(height: 24),
            _buildSidebarItem(2, Icons.show_chart_outlined, Icons.show_chart, 'Progress', activeBgColor, activeTextColor, inactiveTextColor),
            const SizedBox(height: 24),
            _buildSidebarItem(3, Icons.person_outline, Icons.person, 'Profile', activeBgColor, activeTextColor, inactiveTextColor),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.logout, color: inactiveTextColor),
              onPressed: () async {
                await _authManager.logout();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData outlineIcon, IconData filledIcon, String label, Color activeBgColor, Color activeTextColor, Color inactiveTextColor) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? activeTextColor : inactiveTextColor,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeTextColor : inactiveTextColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
