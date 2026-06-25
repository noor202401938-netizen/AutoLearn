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
      final stats = await _analyticsManager.getUserLearningStats(uid);
      if (mounted) {
        setState(() {
          _userProfile = user;
          _stats = stats;
        });
      }
    }
  }

  Future<void> _loadFeaturedCourses() async {
    setState(() => _isLoadingCourses = true);
    final courses = await _courseManager.getPublishedCourses();
    if (mounted) {
      setState(() {
        _featuredCourses = courses.take(5).toList(); // Show top 5 courses
        _isLoadingCourses = false;
      });
    }
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
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: isMobile
          ? SafeArea(
              child: _getSelectedScreen(),
            )
          : Row(
              children: [
                _buildCustomSidebar(),
                Expanded(
                  child: SafeArea(
                    child: _selectedIndex == 0 
                        ? _buildDribbbleDashboard()
                        : _getSelectedScreen(),
                  ),
                ),
                if (_selectedIndex == 0) ...[
                  Container(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
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

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    final name = _userProfile?['displayName'] ?? 'Student';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $name 👋',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Let\'s continue learning',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
        ),
      ],
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
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          'Completed',
                          _stats['completedCourses'].toString(),
                          Icons.check_circle_rounded,
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          'Lessons',
                          _stats['totalLessonsWatched'].toString(),
                          Icons.play_circle_rounded,
                          Theme.of(context).colorScheme.onPrimary,
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedIndex = 1);
                      },
                      child: Text('See All', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
                        style: Theme.of(context).textTheme.bodyLarge,
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)),
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
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start learning to track your progress',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: colorScheme.surface,
              child: Text(
                (_userProfile?['displayName'] ?? _userProfile?['email'] ?? 'U')[0].toUpperCase(),
                style: theme.textTheme.displayMedium?.copyWith(color: colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _userProfile?['displayName'] ?? 'Student',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile?['email'] ?? '',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 40),

          _buildProfileOption(
            'Edit Profile',
            Icons.edit_outlined,
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
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: Text(
                'Logout',
                style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onErrorContainer),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DashboardCourseCard(
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
      ),
    );
  }

  Widget _buildDribbbleDashboard() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invest in your\neducation',
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: 32),
          FilterChips(),
          const SizedBox(height: 32),
          Text(
            'Most popular',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          _isLoadingCourses
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 1.2,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurface),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.onSurface.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    (_userProfile?['displayName'] ?? _userProfile?['email'] ?? 'U')[0].toUpperCase(),
                    style: theme.textTheme.headlineMedium?.copyWith(color: colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userProfile?['displayName'] ?? _userProfile?['email']?.split('@').first ?? 'Student',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Student',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.onSurface.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity',
                  style: theme.textTheme.titleLarge,
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
                style: theme.textTheme.titleLarge,
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
            color: Theme.of(context).colorScheme.outlineVariant,
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
                Icons.school_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 64),
            _buildSidebarItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', activeBgColor, activeTextColor, inactiveTextColor),
            const SizedBox(height: 24),
            _buildSidebarItem(1, Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Courses', activeBgColor, activeTextColor, inactiveTextColor),
            const SizedBox(height: 24),
            _buildSidebarItem(2, Icons.analytics_outlined, Icons.analytics_rounded, 'Progress', activeBgColor, activeTextColor, inactiveTextColor),
            const SizedBox(height: 24),
            _buildSidebarItem(3, Icons.person_outline, Icons.person_rounded, 'Profile', activeBgColor, activeTextColor, inactiveTextColor),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? activeTextColor : inactiveTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
