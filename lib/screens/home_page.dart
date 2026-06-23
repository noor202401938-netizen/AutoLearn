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
    final user = _authRepository.getCurrentUser();
    if (user != null) {
      final profile = await _authRepository.getUserProfile(user.uid);
      final stats = await _analyticsManager.getUserLearningStats(user.uid);
      setState(() {
        _userProfile = profile;
        _stats = stats;
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
        title: const Text(
          'AI Tutor',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                    Theme.of(context).colorScheme.background,
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
              child: SafeArea(
                child: _getSelectedScreen(),
              ),
            )
          : Row(
              children: [
                NavigationRail(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.secondary),
                  unselectedIconTheme: IconThemeData(color: Theme.of(context).iconTheme.color?.withOpacity(0.5) ?? Colors.grey),
                  selectedLabelTextStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  unselectedLabelTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5) ?? Colors.grey),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school),
                      label: Text('Courses'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.show_chart_outlined),
                      selectedIcon: Icon(Icons.show_chart),
                      label: Text('Progress'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                VerticalDivider(thickness: 1, width: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
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
                  VerticalDivider(thickness: 1, width: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
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
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userProfile?['displayName'] ??
                      _authRepository.getCurrentUser()?.email?.split('@')[0] ??
                      'Student',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickStat(
                          'Courses',
                          _stats['enrolledCourses'].toString(),
                          Icons.book,
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          'Completed',
                          _stats['completedCourses'].toString(),
                          Icons.check_circle,
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          'Lessons',
                          _stats['totalLessonsWatched'].toString(),
                          Icons.play_circle,
                          Colors.orangeAccent,
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
                    const Text(
                      'Featured Courses',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No courses available yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.5),
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
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
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No progress data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start learning to track your progress',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.5),
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
                (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
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
            user?.displayName ?? 'Student',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
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
    final user = _authRepository.getCurrentUser();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.notifications_outlined, color: textColor),
              Icon(Icons.settings_outlined, color: textColor),
            ],
          ),
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? user?.email?.split('@').first ?? 'Student',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 32),
          ActivityChart(stats: _stats),
          const SizedBox(height: 32),
          Row(
            children: [
              Text(
                'My courses',
                style: TextStyle(
                  fontSize: 16,
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
                    index: index + 2,
                    onTap: () {},
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

}