import 'package:cloud_firestore/cloud_firestore.dart';
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
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user == null) {
        setState(() {
          _enrolledCourses = [];
          _loadingEnrolled = false;
        });
        return;
      }
      final ids = await _enrollmentRepository.getUserCourseIds(uid: user.uid);
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
    final user = _authRepository.getCurrentUser();
    if (user != null) {
      final profile = await _authRepository.getUserProfile(user.uid);
      setState(() {
        _userProfile = profile;
      });
    }
  }

  Widget _buildGreetingName() {
    final user = null /* was FirebaseAuth.instance.currentUser */;
    if (user == null) {
      return const Text(
        'Student',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _userRepository.streamUserProfile(user.uid),
      builder: (context, snapshot) {
        String name = _userProfile?['displayName'] ??
            user.displayName ??
            user.email?.split('@')[0] ??
            'Student';
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          if (data != null &&
              (data['displayName'] as String?) != null &&
              (data['displayName'] as String).isNotEmpty) {
            name = data['displayName'];
          }
        }
        return Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
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
      appBar: AppBar(
        title: const Text(
          'AutoLearn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                _buildGreetingName(),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickStat(
                          'Courses',
                          '0',
                          Icons.book,
                          Colors.blue,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          'Completed',
                          '0',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          'Hours',
                          '0',
                          Icons.access_time,
                          Colors.orange,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AITutorChatScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Tutor',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get instant help with your questions',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
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
                                  color: Colors.blue[50],
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: course.thumbnailURL.isNotEmpty
                                    ? Image.network(
                                        course.thumbnailURL,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.school,
                                        size: 40,
                                        color: Color(0xFF4169E1),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          size: 14, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          course.rating.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Spacer(),
                                      Flexible(
                                        child: Text(
                                          course.price == 0
                                              ? 'FREE'
                                              : '\$${course.price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: course.price == 0
                                                ? Colors.green
                                                : const Color(0xFF4169E1),
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF4169E1),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() => _selectedIndex = 1);
                                      },
                                      child: const Text('Browse Courses'),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 2),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MyCoursesScreen(),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                              ),
                                              child: course
                                                      .thumbnailURL.isNotEmpty
                                                  ? Image.network(
                                                      course.thumbnailURL,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : const Icon(
                                                      Icons.school,
                                                      size: 40,
                                                      color: Color(0xFF4169E1),
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  course.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star,
                                                        size: 14,
                                                        color: Colors.amber),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        course.rating
                                                            .toStringAsFixed(1),
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Flexible(
                                                      child: Text(
                                                        course.price == 0
                                                            ? 'FREE'
                                                            : '\$${course.price.toStringAsFixed(0)}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: course.price ==
                                                                  0
                                                              ? Colors.green
                                                              : const Color(
                                                                  0xFF4169E1),
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
    final user = null /* was FirebaseAuth.instance.currentUser */;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          StreamBuilder<Map<String, dynamic>?>(
            stream: _userRepository.streamUserProfile(user?.uid ?? ''),
            builder: (context, snapshot) {
              String displayName = user?.displayName ?? 'Student';
              if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          if (data != null &&
                    (data['displayName'] as String?) != null &&
                    (data['displayName'] as String).isNotEmpty) {
                  displayName = data['displayName'];
                }
              } else if (_userProfile != null &&
                  (_userProfile!['displayName'] as String?) != null &&
                  (_userProfile!['displayName'] as String).isNotEmpty) {
                displayName = _userProfile!['displayName'];
              }

              return Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      (displayName.isNotEmpty
                              ? displayName
                              : user?.email ?? 'U')[0]
                          .toUpperCase(),
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
            user?.email ?? '',
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
            'Theme & Accessibility',
            Icons.palette,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeAccessibilityScreen(),
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

