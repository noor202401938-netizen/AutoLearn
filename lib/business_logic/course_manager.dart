// lib/business_logic/course_manager.dart
import '../repository/course_repository.dart';
import '../model/course_model.dart';

class CourseManager {
  final CourseRepository _courseRepository = CourseRepository();

  // Get all published courses
  Future<List<CourseModel>> getPublishedCourses() async {
    return await _courseRepository.getAllPublishedCourses();
  }

  // Get all courses (admin only)
  Future<List<CourseModel>> getAllCourses() async {
    return await _courseRepository.getAllCourses();
  }

  // Get course by ID
  Future<CourseModel?> getCourse(String courseId) async {
    return await _courseRepository.getCourseById(courseId);
  }

  // Create new course (admin only)
  Future<String?> createCourse(CourseModel course) async {
    try {
      if (course.title.isEmpty) return 'Course title is required';
      if (course.description.isEmpty) return 'Course description is required';
      if (course.instructor.isEmpty) return 'Instructor name is required';
      if (course.price < 0) return 'Price cannot be negative';

      final result = await _courseRepository.createCourse(course);
      return result != null ? null : 'Failed to create course';
    } catch (e) {
      return 'Failed to create course: ${e.toString()}';
    }
  }

  // Update course (admin only) — takes the full model and updates by courseId
  Future<String?> updateCourse(CourseModel course) async {
    try {
      if (course.title.isEmpty) return 'Course title is required';
      final result =
          await _courseRepository.updateCourse(course.courseId, course);
      return result != null ? null : 'Failed to update course';
    } catch (e) {
      return 'Failed to update course: ${e.toString()}';
    }
  }

  // Delete course (admin only)
  Future<String?> deleteCourse(String courseId) async {
    try {
      final success = await _courseRepository.deleteCourse(courseId);
      return success ? null : 'Failed to delete course';
    } catch (e) {
      return 'Failed to delete course: ${e.toString()}';
    }
  }

  // Search courses
  Future<List<CourseModel>> searchCourses(String query) async {
    if (query.isEmpty) return await getPublishedCourses();
    return await _courseRepository.searchCourses(query);
  }

  // Filter by category
  Future<List<CourseModel>> filterByCategory(String category) async {
    return await _courseRepository.getCoursesByCategory(category);
  }

  // Filter by level
  Future<List<CourseModel>> filterByLevel(String level) async {
    return await _courseRepository.getCoursesByLevel(level);
  }

  // Get available categories (derived client-side from course list)
  Future<List<String>> getCategories() async {
    final courses = await getPublishedCourses();
    final categories = courses.map((course) => course.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Enroll in course (delegates to backend via enroll endpoint)
  Future<String?> enrollInCourse(String courseId) async {
    try {
      await _courseRepository.incrementEnrollment(courseId);
      return null;
    } catch (e) {
      return 'Failed to enroll: ${e.toString()}';
    }
  }

  // Rate course
  Future<String?> rateCourse(String courseId, double rating) async {
    try {
      if (rating < 0 || rating > 5) return 'Rating must be between 0 and 5';
      await _courseRepository.updateCourseRating(courseId, rating);
      return null;
    } catch (e) {
      return 'Failed to rate course: ${e.toString()}';
    }
  }

  // Stream courses for real-time updates (polls every 30s)
  Stream<List<CourseModel>> watchPublishedCourses() {
    return _courseRepository.streamPublishedCourses();
  }

  // Get course statistics
  Future<Map<String, dynamic>> getCourseStats() async {
    final courses = await getPublishedCourses();
    final totalEnrollments =
        courses.fold(0, (sum, c) => sum + c.enrollmentCount);
    final averageRating = courses.isEmpty
        ? 0.0
        : courses.fold(0.0, (sum, c) => sum + c.rating) / courses.length;
    return {
      'totalCourses': courses.length,
      'totalEnrollments': totalEnrollments,
      'averageRating': averageRating,
    };
  }

  // Get course count
  Future<int> getCourseCount({bool publishedOnly = true}) async {
    return await _courseRepository.getCourseCount(publishedOnly: publishedOnly);
  }
}
