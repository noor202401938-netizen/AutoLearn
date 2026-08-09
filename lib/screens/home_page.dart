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
        _featuredCourses = courses.take(5).toList();
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
    final colorScheme = theme.colorScheme;
    final name = _userProfile?['displayName'] ?? 'Student';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $name',
                style: theme.textTheme.headlineSmall,
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
            color: colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurface),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _buildTopBar(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Courses',
                    _stats['enrolledCourses'].toString(),
                    Icons.book_rounded,
                    colorScheme.primaryContainer,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    _stats['completedCourses'].toString(),
                    Icons.check_circle_rounded,
                    colorScheme.secondaryContainer,
                    colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Lessons',
                    _stats['totalLessonsWatched'].toString(),
                    Icons.play_circle_rounded,
                    colorScheme.tertiaryContainer,
                    colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Courses',
                  style: theme.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedIndex = 1);
                  },
                  child: Text('See All', style: TextStyle(color: colorScheme.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _isLoadingCourses
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  ),
                )
              : _featuredCourses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.auto_stories_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No courses available yet',
                              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _featuredCourses.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCourseCard(_featuredCourses[index]),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor, Color iconColor) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesScreen() {
    return const CourseListScreen();
  }

  Widget _buildProgressScreen() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Track your learning journey',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildProgressStat('Courses', _stats['enrolledCourses'].toString(), Icons.book_rounded, colorScheme.primary),
                    _buildProgressStat('Completed', _stats['completedCourses'].toString(), Icons.check_circle_rounded, colorScheme.secondary),
                    _buildProgressStat('Lessons', _stats['totalLessonsWatched'].toString(), Icons.play_circle_rounded, colorScheme.tertiary),
                  ],
                ),
                const SizedBox(height: 32),
                ActivityChart(stats: _stats),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 24, color: color)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildProfileScreen() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: colorScheme.surface,
              child: Text(
                (_userProfile?['displayName'] ?? _userProfile?['email'] ?? 'U')[0].toUpperCase(),
                style: theme.textTheme.headlineLarge?.copyWith(color: colorScheme.primary, fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _userProfile?['displayName'] ?? 'Student',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _userProfile?['email'] ?? '',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

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
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout, size: 20),
              label: Text(
                'Logout',
                style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.error),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
      isHorizontal: true,
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
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
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
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurface, size: 20),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface, size: 20),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    (_userProfile?['displayName'] ?? _userProfile?['email'] ?? 'U')[0].toUpperCase(),
                    style: theme.textTheme.headlineMedium?.copyWith(color: colorScheme.primary, fontSize: 28),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userProfile?['displayName'] ?? _userProfile?['email']?.split('@').first ?? 'Student',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Student',
                    style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.secondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                ActivityChart(stats: _stats),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'My courses',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_featuredCourses.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _featuredCourses.length > 2 ? 2 : _featuredCourses.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
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

  Widget _buildCustomSidebar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.school_rounded,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 48),
            _buildSidebarItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', colorScheme),
            const SizedBox(height: 20),
            _buildSidebarItem(1, Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Courses', colorScheme),
            const SizedBox(height: 20),
            _buildSidebarItem(2, Icons.analytics_outlined, Icons.analytics_rounded, 'Progress', colorScheme),
            const SizedBox(height: 20),
            _buildSidebarItem(3, Icons.person_outline, Icons.person_rounded, 'Profile', colorScheme),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: Icon(Icons.logout, color: colorScheme.error, size: 22),
                onPressed: () async {
                  await _authManager.logout();
                  if (mounted) Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData outlineIcon, IconData filledIcon, String label, ColorScheme colorScheme) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
