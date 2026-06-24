
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
  List<CourseModel> _enrolledCourses = [];
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
      final ids = await _enrollmentRepository.getUserCourseIds(uid: uid);
      final List<CourseModel> result = [];
      for (final id in ids) {
        final course = await _courseRepository.getCourseById(id);
        if (course != null) result.add(course);
      }
      setState(() {
        _enrolledCourses = result;
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
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authRepository.getCurrentUser(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final uid = user?['uid'] as String?;

        if (uid == null) {
          return Text(
            'Student',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        return StreamBuilder<Map<String, dynamic>?>(
          stream: _userRepository.streamUserProfile(uid),
          builder: (context, snapshot) {
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
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
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
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text(
          'AutoLearn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
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
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Row(
          children: [
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
            Expanded(
              child: _getSelectedScreen(),
            ),
          ],
        ),
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                _buildGreetingName(),
                const SizedBox(height: 24),
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
                          '0',
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
                          '0',
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
                          'Hours',
                          '0',
                          Icons.access_time_rounded,
                          Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // AI Tutor Chat Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AITutorChatScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withBlue(255),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Tutor',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get instant help with your questions',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recommended Courses Section
          if (_recommendedCourses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommended for You',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedIndex = 1);
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _recommendedCourses.length,
                itemBuilder: (context, index) {
                  final course = _recommendedCourses[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    child: Card(
                      child: InkWell(
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                        ),
                                        child: course.thumbnailURL.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                                child: Image.network(
                                                  course.thumbnailURL,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Icon(
                                                Icons.school_rounded,
                                                size: 48,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course.title,
                                            style: Theme.of(context).textTheme.titleMedium,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text(
                                                course.rating.toStringAsFixed(1),
                                                style: Theme.of(context).textTheme.labelLarge,
                                              ),
                                              const Spacer(),
                                              Text(
                                                course.price == 0 ? 'FREE' : '\$${course.price.toStringAsFixed(0)}',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: course.price == 0 ? Colors.green : Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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
            const SizedBox(height: 16),
          ],

          // Continue Learning Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue Learning',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Show enrolled courses if available
                _loadingEnrolled
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF4169E1)))
                    : _enrolledCourses.isEmpty
                        ? Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.auto_stories_outlined,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No courses in progress',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start learning by enrolling in a course',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() => _selectedIndex = 1);
                                      },
                                      child: const Text('Browse Courses'),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const MyCoursesScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text('My Courses'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _enrolledCourses.length,
                              itemBuilder: (context, index) {
                                final course = _enrolledCourses[index];
                                return Container(
                                  width: 300,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: Card(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CourseContentScreen(
                                              courseId: course.courseId,
                                              title: course.title,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(20),
                                                ),
                                              ),
                                              child: course.thumbnailURL.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                                      child: Image.network(
                                                        course.thumbnailURL,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.school_rounded,
                                                      size: 48,
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  course.title,
                                                  style: Theme.of(context).textTheme.titleMedium,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      course.rating.toStringAsFixed(1),
                                                      style: Theme.of(context).textTheme.labelLarge,
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      course.price == 0 ? 'FREE' : '\$${course.price.toStringAsFixed(0)}',
                                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        color: course.price == 0 ? Colors.green : Theme.of(context).colorScheme.primary,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
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
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No progress data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start learning to track your progress',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authRepository.getCurrentUser(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final uid = user?['uid'] as String?;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              StreamBuilder<Map<String, dynamic>?>(
                stream: uid != null ? _userRepository.streamUserProfile(uid) : const Stream.empty(),
                builder: (context, snapshot) {
                  String displayName = 'Student';
                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!;
                    if ((data['displayName'] as String?)?.isNotEmpty == true) {
                      displayName = data['displayName'];
                    }
                  } else if (_userProfile != null &&
                      (_userProfile!['displayName'] as String?)?.isNotEmpty == true) {
                    displayName = _userProfile!['displayName'];
                  } else if (user?['displayName']?.isNotEmpty == true) {
                    displayName = user!['displayName'];
                  } else if (user?['email']?.isNotEmpty == true) {
                    displayName = (user!['email'] as String).split('@')[0];
                  }

                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          (displayName.isNotEmpty ? displayName : user?['email'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                user?['email'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
          const SizedBox(height: 32),
          _buildProfileOption(
            'Edit Profile',
            Icons.edit,
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
              if (result == true) {
                // Profile was updated, reload it
                _loadUserProfile();
              }
            },
          ),
          _buildProfileOption(
            'Change Password',
            Icons.lock_outline,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          _buildProfileOption(
            'Notifications',
            Icons.notifications_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPanel(),
                ),
              );
            },
          ),
          _buildProfileOption(
            'Certificates',
            Icons.workspace_premium,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CertificatesListScreen(),
                ),
              );
            },
          ),

          _buildProfileOption(
            'Help & Support',
            Icons.help_outline,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          _buildProfileOption(
            'About',
            Icons.info_outline,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
          _buildProfileOption(
            'Policies & Terms',
            Icons.policy_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PoliciesScreen(),
                ),
              );
            },
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
  });
}

  Widget _buildProfileOption(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

