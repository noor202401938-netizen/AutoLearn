// lib/business_logic/recommendation_engine.dart
import '../model/course_model.dart';
import '../repository/course_repository.dart';
import '../repository/enrollment_repository.dart';
import '../repository/user_repository.dart';

class RecommendationEngine {
  final CourseRepository _courseRepository = CourseRepository();
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();
  final UserRepository _userRepository = UserRepository();

  // Get personalized course recommendations
  Future<List<CourseModel>> getRecommendations() async {
    try {
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user == null) {
        return await _getPopularCourses();
      }

      // Get user profile and interests
      final userProfile = await _userRepository.getUserProfile(user.uid);
      final userInterest = userProfile?['interest'] as String?;
      final userGrade = userProfile?['grade'] as String?;

      // Get enrolled courses
      final enrolledCourseIds = await _enrollmentRepository.getUserCourseIds(
        uid: user.uid,
      );

      // Get all published courses
      final allCourses = await _courseRepository.getAllPublishedCourses();

      // Filter out enrolled courses
      final availableCourses = allCourses
          .where((course) => !enrolledCourseIds.contains(course.courseId))
          .toList();

      // Score courses based on recommendations
      final scoredCourses = availableCourses.map((course) {
        int score = 0;

        // Match interest
        if (userInterest != null &&
            (course.category.toLowerCase() == userInterest.toLowerCase() ||
                course.tags.any((tag) => tag.toLowerCase() == userInterest.toLowerCase()))) {
          score += 10;
        }

        // Match level with grade
        if (userGrade != null) {
          if ((userGrade == 'high' && course.level == 'advanced') ||
              (userGrade == 'middle' && course.level == 'intermediate') ||
              (userGrade == 'elementary' && course.level == 'beginner')) {
            score += 5;
          }
        }

        // Boost popular courses
        if (course.enrollmentCount > 100) {
          score += 3;
        }

        // Boost highly rated courses
        if (course.rating >= 4.5) {
          score += 5;
        }

        return {'course': course, 'score': score};
      }).toList();

      // Sort by score and return top 10
      scoredCourses.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      return scoredCourses
          .take(10)
          .map((item) => item['course'] as CourseModel)
          .toList();
    } catch (e) {
      return await _getPopularCourses();
    }
  }

  // Get popular courses as fallback
  Future<List<CourseModel>> _getPopularCourses() async {
    try {
      final courses = await _courseRepository.getAllPublishedCourses();
      courses.sort((a, b) => b.enrollmentCount.compareTo(a.enrollmentCount));
      return courses.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  // Get courses based on completed courses
  Future<List<CourseModel>> getNextSteps() async {
    try {
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user == null) return [];

      // Get enrolled courses
      final enrolledCourseIds = await _enrollmentRepository.getUserCourseIds(
        uid: user.uid,
      );

      if (enrolledCourseIds.isEmpty) {
        return await _getPopularCourses();
      }

      // Get enrolled courses to find prerequisites
      final enrolledCourses = <CourseModel>[];
      for (final id in enrolledCourseIds) {
        final course = await _courseRepository.getCourseById(id);
        if (course != null) enrolledCourses.add(course);
      }

      // Find courses that match prerequisites
      final allCourses = await _courseRepository.getAllPublishedCourses();
      final recommended = <CourseModel>[];

      for (final course in allCourses) {
        if (enrolledCourseIds.contains(course.courseId)) continue;

        // Check if prerequisites match enrolled courses
        final hasMatchingPrereq = course.prerequisites.any(
          (prereq) => enrolledCourseIds.contains(prereq),
        );

        if (hasMatchingPrereq) {
          recommended.add(course);
        }
      }

      return recommended.take(10).toList();
    } catch (e) {
      return [];
    }
  }
}

