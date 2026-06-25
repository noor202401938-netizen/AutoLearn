
// lib/screens/student/student_home.dart
import 'package:flutter/material.dart';
import '../../business_logic/auth_manager.dart';
import '../../repository/auth_repository.dart';
import '../../repository/user_repository.dart';
import 'my_courses_screen.dart';
import 'ai_tutor_chat_screen.dart';
import '../notifications_panel.dart';
import 'certificates_list_screen.dart';
import '../theme_accessibility_screen.dart';
import '../../business_logic/recommendation_engine.dart';
import '../../model/course_model.dart';
import 'course_list_screen.dart';
import 'course_content_screen.dart';
import '../../repository/enrollment_repository.dart';
import '../../repository/course_repository.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'policies_screen.dart';
import '../../utils/preference_notifier.dart';
import '../../widgets/gradient_bottom_nav.dart';
import '../../widgets/student_home/stat_card.dart';
import '../../widgets/student_home/ai_tutor_banner.dart';
import '../../widgets/student_home/progress_course_card.dart';
import '../../widgets/student_home/recommended_course_card.dart';

import '../../widgets/student_home/profile_tab.dart';
import '../../widgets/student_home/analytics_tab.dart';
class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final AuthManager _authManager = AuthManager();
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();
  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();
  final CourseRepository _courseRepository = CourseRepository();
  int _selectedIndex = 0;
  Map<String, dynamic>? _userProfile;
  List<CourseModel> _recommendedCourses = [];
  List<Map<String, dynamic>> _enrolledCourses = [];
  bool _loadingEnrolled = false;
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadEnrolledCourses();
    _loadRecommendations();
  }

  Future<void> _loadEnrolledCourses() async {
    setState(() => _loadingEnrolled = true);
    try {
      final user = await _authRepository.getCurrentUser();
      final uid = user?['uid'] as String?;
      if (uid == null) {
        setState(() {
          _enrolledCourses = [];
          _loadingEnrolled = false;
        });
        return;
      }
      final enrollments = await _enrollmentRepository.getUserEnrollments(uid);
      setState(() {
        _enrolledCourses = enrollments;
        _loadingEnrolled = false;
      });
    } catch (e) {
      setState(() => _loadingEnrolled = false);
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    try {
      final recommendations = await _recommendationEngine.getRecommendations();
      setState(() {
        _recommendedCourses = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() => _isLoadingRecommendations = false);
    }
  }

  Future<void> _loadUserProfile() async {
    final user = await _authRepository.getCurrentUser();
    final uid = user?['uid'] as String?;
    if (uid != null) {
      final profile = await _authRepository.getUserProfile(uid);
      setState(() {
        _userProfile = profile;
      });
    }
  }

  Widget _buildGreetingName() {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authRepository.getCurrentUser(),
      builder: (context, userSnapshot) {
      final theme = Theme.of(context);
        final user = userSnapshot.data;
        final uid = user?['uid'] as String?;

        if (uid == null) {
          return Text(
            'Student',
            style: theme.textTheme.titleMedium.colorScheme.primary,
            ),
          );
        }

        return StreamBuilder<Map<String, dynamic>?>(
          stream: _userRepository.streamUserProfile(uid),
          builder: (context, snapshot) {
      final theme = Theme.of(context);
            String name = _userProfile?['displayName'] ??
                user?['displayName'] ??
                (user?['email'] as String?)?.split('@')[0] ??
                'Student';
            if (snapshot.hasData && snapshot.data != null) {
              final data = snapshot.data!;
              if (data['displayName'] != null &&
                  (data['displayName'] as String).isNotEmpty) {
                name = data['displayName'];
              }
            }
            return Text(
              name,
              style: theme.textTheme.titleMedium.colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedScreen() {
    final theme = Theme.of(context);
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
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      extendBodyBehindAppBar: false,
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'AutoLearn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: () {
              final newTheme = Theme.of(context).brightness == Brightness.light
                  ? 'dark'
                  : 'light';
              PreferenceNotifier.instance.updateTheme(newTheme);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPanel(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: isMobile 
          ? GradientBottomNav(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemTapped,
              menuItems: [
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
              ],
            )
          : null,
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            if (!isMobile) ...[
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
                unselectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                selectedLabelTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                unselectedLabelTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                extended: MediaQuery.of(context).size.width >= 800,
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
              VerticalDivider(thickness: 1, width: 1, color: Theme.of(context).dividerColor),
            ],
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _getSelectedScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    final theme = Theme.of(context);
    int streak = _userProfile?['learningStreak'] ?? 12;
    int completedCoursesCount = _userProfile?['completedCoursesCount'] ?? 8;
    int certsCount = _userProfile?['certificationsCount'] ?? 3;
    int hoursLearned = _userProfile?['hoursLearned'] ?? 45;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Welcome back, ',
                      style: theme.textTheme.titleMedium.colorScheme.onSurface,
                      ),
                    ),
                    Expanded(child: _buildGreetingName()),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'re on a $streak-day learning streak! Keep it up.',
                  style: theme.textTheme.bodyMedium.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                // Signature Stats Section
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    StatCard(
                      icon: Icons.school_outlined,
                      value: '${_enrolledCourses.length + completedCoursesCount}',
                      label: 'Courses',
                    ),
                    StatCard(
                      icon: Icons.schedule_rounded,
                      value: '${hoursLearned}h',
                      label: 'Learning',
                    ),
                    StatCard(
                      icon: Icons.task_alt_rounded,
                      value: '$completedCoursesCount',
                      label: 'Completed',
                    ),
                    StatCard(
                      icon: Icons.verified_outlined,
                      value: '$certsCount',
                      label: 'Certs',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // AI Tutor Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: AITutorBanner(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AITutorChatScreen(),
                  ),
                );
              },
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
                      'Continue Learning',
                      style: theme.textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedIndex = 1);
                      },
                      child: Text(
                        'View All',
                        style: theme.textTheme.bodyMedium.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _loadingEnrolled
                    ? const Center(child: CircularProgressIndicator())
                    : _enrolledCourses.isEmpty
                        ? Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.auto_stories_outlined,
                                  size: 80,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No courses in progress',
                                  style: theme.textTheme.bodyMedium.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => setState(() => _selectedIndex = 1),
                                  child: const Text('Browse Courses'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _enrolledCourses.length > 3 ? 3 : _enrolledCourses.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final enrollment = _enrolledCourses[index];
                              final course = enrollment['course'] ?? {};
                              final progress = enrollment['progressPercent'] ?? 0.0;
                              return ProgressCourseCard(
                                title: course['title'] ?? 'Course',
                                moduleName: 'Continue learning',
                                thumbnailUrl: course['thumbnailURL'],
                                progressPercent: progress.toDouble(),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CourseContentScreen(
                                        courseId: course['courseId'] ?? '',
                                        title: course['title'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ],
            ),
          ),

          // Recommended Courses Section
          if (_recommendedCourses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'For You',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _recommendedCourses.length,
                itemBuilder: (context, index) {
                  final course = _recommendedCourses[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: RecommendedCourseCard(
                      title: course.title,
                      description: 'Master the subject with this interactive course.',
                      thumbnailUrl: course.thumbnailURL,
                      tag: 'RECOMMENDED',
                      rating: course.rating,
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
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildCoursesScreen() {
    final theme = Theme.of(context);
    return const CourseListScreen();
  }


  Widget _buildProgressScreen() {
    final theme = Theme.of(context);
    return const AnalyticsTab();
  }

  Widget _buildProfileScreen() {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authRepository.getCurrentUser(),
      builder: (context, userSnapshot) {
      final theme = Theme.of(context);
        final user = userSnapshot.data;
        
        return ProfileTab(
          userProfile: _userProfile ?? user,
          onProfileUpdated: _loadUserProfile,
        );
      },
    );
  }
}

