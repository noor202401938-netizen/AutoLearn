// lib/screens/student/student_home.dart
import 'package:flutter/material.dart';
import '../../repository/auth_repository.dart';
import '../../repository/user_repository.dart';
import 'ai_tutor_chat_screen.dart';
import 'certificates_list_screen.dart';
import '../../business_logic/recommendation_engine.dart';
import '../../model/course_model.dart';
import 'course_list_screen.dart';
import 'course_content_screen.dart';
import '../../repository/enrollment_repository.dart';
import '../../utils/preference_notifier.dart';
import '../../widgets/gradient_bottom_nav.dart';
import '../../widgets/student_home/stat_card.dart';
import '../../widgets/student_home/ai_tutor_banner.dart';
import '../../widgets/student_home/progress_course_card.dart';
import '../../widgets/student_home/recommended_course_card.dart';
import '../../widgets/student_home/ambient_background.dart';

import '../../widgets/student_home/profile_tab.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();
  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();
  int _selectedIndex = 0;
  Map<String, dynamic>? _userProfile;
  List<CourseModel> _recommendedCourses = [];
  List<Map<String, dynamic>> _enrolledCourses = [];
  bool _loadingEnrolled = false;

  // Cache the getCurrentUser future so it isn't recreated on every rebuild
  late final Future<Map<String, dynamic>?> _currentUserFuture;

  @override
  void initState() {
    super.initState();
    _currentUserFuture = _authRepository.getCurrentUser();
    _loadUserProfile();
    _loadEnrolledCourses();
    _loadRecommendations();
  }

  Future<void> _loadEnrolledCourses() async {
    setState(() => _loadingEnrolled = true);
    try {
      final user = await _currentUserFuture;
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
    try {
      final recommendations = await _recommendationEngine.getRecommendations();
      setState(() {
        _recommendedCourses = recommendations;
      });
    } catch (e) {
      // ignore — non-critical
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _currentUserFuture;
      final uid = user?['uid'] as String?;
      if (uid != null) {
        final profile = await _authRepository.getUserProfile(uid);
        if (mounted) {
          setState(() {
            _userProfile = profile;
          });
        }
      }
    } catch (e) {
      // ignore — profile will just show defaults
    }
  }

  /// Builds the user's display name using cached data — no extra API calls.
  Widget _buildGreetingName() {
    final theme = Theme.of(context);

    // Use the cached profile first, then fall back to stream updates
    String name = _userProfile?['displayName'] as String? ?? '';

    if (name.isEmpty) {
      // Try email split as fallback
      final email = _userProfile?['email'] as String?;
      if (email != null && email.contains('@')) {
        name = email.split('@')[0];
      }
    }

    if (name.isEmpty) name = 'Student';

    final uid = _userProfile?['uid'] as String? ?? _userProfile?['id'] as String?;
    if (uid == null) {
      return Text(
        name,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.primary,
          letterSpacing: -1.0,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Stream for real-time displayName updates (no new Future created here)
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _userRepository.streamUserProfile(uid),
      builder: (context, snapshot) {
        String displayName = name;
        if (snapshot.hasData && snapshot.data != null) {
          final streamed = snapshot.data!['displayName'] as String?;
          if (streamed != null && streamed.isNotEmpty) {
            displayName = streamed;
          }
        }
        return Text(
          displayName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
            letterSpacing: -1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildCoursesScreen();
      case 2:
        return _buildLearningPathsScreen();
      case 3:
        return const AITutorChatScreen(embedded: true);
      case 4:
        return const CertificatesListScreen(embedded: true);
      case 5:
        return _buildBookmarksScreen();
      case 6:
        return _buildAssignmentsScreen();
      case 7:
        return _buildCommunityScreen();
      case 8:
        return _buildProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildLearningPathsScreen() {
    return _buildPlaceholderScreen('Learning Paths', Icons.map_outlined);
  }

  Widget _buildBookmarksScreen() {
    return _buildPlaceholderScreen('Bookmarks', Icons.bookmark_border_rounded);
  }

  Widget _buildAssignmentsScreen() {
    return _buildPlaceholderScreen('Assignments', Icons.assignment_outlined);
  }

  Widget _buildCommunityScreen() {
    return _buildPlaceholderScreen('Community', Icons.people_outline_rounded);
  }

  Widget _buildPlaceholderScreen(String title, IconData icon) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This feature is coming soon to your AutoLearn study journey. Stay tuned!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: null, // Completely removed top AppBar to merge action controls into the dashboard welcome card
      bottomNavigationBar: isMobile
          ? GradientBottomNav(
              selectedIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
              onItemSelected: _onItemTapped,
              menuItems: [
                {
                  'title': 'Home',
                  'icon': Icons.home_outlined,
                  'selectedIcon': Icons.home,
                },
                {
                  'title': 'Courses',
                  'icon': Icons.school_outlined,
                  'selectedIcon': Icons.school,
                },
                {
                  'title': 'Progress',
                  'icon': Icons.show_chart_outlined,
                  'selectedIcon': Icons.show_chart,
                },
                {
                  'title': 'Profile',
                  'icon': Icons.person_outline,
                  'selectedIcon': Icons.person,
                },
              ],
            )
          : null,
      body: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Single AmbientBackground — only rendered once at the top level
            const AmbientBackground(),
            Row(
              children: [
                if (!isMobile) _buildSidebar(colorScheme, theme),
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

  Widget _buildSidebar(ColorScheme colorScheme, ThemeData theme) {
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_outlined, 'selectedIcon': Icons.dashboard},
      {'title': 'My Courses', 'icon': Icons.school_outlined, 'selectedIcon': Icons.school},
      {'title': 'Learning Paths', 'icon': Icons.map_outlined, 'selectedIcon': Icons.map},
      {'title': 'AI Assistant', 'icon': Icons.smart_toy_outlined, 'selectedIcon': Icons.smart_toy},
      {'title': 'Certificates', 'icon': Icons.workspace_premium_outlined, 'selectedIcon': Icons.workspace_premium},
      {'title': 'Bookmarks', 'icon': Icons.bookmark_border_rounded, 'selectedIcon': Icons.bookmark},
      {'title': 'Assignments', 'icon': Icons.assignment_outlined, 'selectedIcon': Icons.assignment},
      {'title': 'Community', 'icon': Icons.people_outline_rounded, 'selectedIcon': Icons.people},
      {'title': 'Settings', 'icon': Icons.settings_outlined, 'selectedIcon': Icons.settings},
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
                    child: Icon(Icons.school_rounded, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AutoLearn',
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
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
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

          // Upgrade to Pro Card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
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
                  Text(
                    'Upgrade to Pro',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Unlock unlimited access to all courses and premium features.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {
                        // Action placeholder
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Upgrade Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

  Widget _buildHomeScreen() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final int streak = (_userProfile?['learningStreak'] as num?)?.toInt() ?? 0;
    final int completedCoursesCount =
        (_userProfile?['completedCoursesCount'] as num?)?.toInt() ?? 0;
    final int certsCount =
        (_userProfile?['certificationsCount'] as num?)?.toInt() ?? 0;
    final int hoursLearned =
        (_userProfile?['hoursLearned'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with Merged Actions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Welcome back, ',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              Expanded(child: _buildGreetingName()),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (streak > 0)
                            Text(
                              'You\'re on a $streak-day learning streak! Keep it up.',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            )
                          else
                            Text(
                              'Start learning today and build your streak!',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                    
                    // Merged Profile and Theme Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            theme.brightness == Brightness.light
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                          ),
                          onPressed: () {
                            final newTheme = theme.brightness == Brightness.light
                                ? 'dark'
                                : 'light';
                            PreferenceNotifier.instance.updateTheme(newTheme);
                          },
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIndex = 8; // Switches to the Settings/Profile tab
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.primaryContainer,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.person, color: colorScheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Stat Cards
                GridView.count(
                  crossAxisCount:
                      MediaQuery.of(context).size.width < 600 ? 2 : 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    StatCard(
                      icon: Icons.school_outlined,
                      value:
                          '${_enrolledCourses.length + completedCoursesCount}',
                      label: 'Courses',
                    ),
                    StatCard(
                      icon: Icons.schedule_rounded,
                      value: hoursLearned > 0 ? '${hoursLearned}h' : '0h',
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
                setState(() {
                  _selectedIndex = 3;
                });
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
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.primary),
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No courses in progress',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () =>
                                      setState(() => _selectedIndex = 1),
                                  child: const Text('Browse Courses'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _enrolledCourses.length > 3
                                ? 3
                                : _enrolledCourses.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final enrollment = _enrolledCourses[index];
                              final course = enrollment['course'] ?? {};
                              final progress =
                                  enrollment['progressPercent'] ?? 0.0;
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
                      description:
                          'Master the subject with this interactive course.',
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
    // CourseListScreen is embedded — pass hideAppBar to avoid nested scaffold/appBar issues
    return const CourseListScreen(embedded: true);
  }

  Widget _buildProfileScreen() {
    // Use the already-cached future — no new API call on each tab switch
    return FutureBuilder<Map<String, dynamic>?>(
      future: _currentUserFuture,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        return ProfileTab(
          userProfile: _userProfile ?? user,
          onProfileUpdated: _loadUserProfile,
        );
      },
    );
  }
}
