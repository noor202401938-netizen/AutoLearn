// lib/repository/course_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../backend/api_client.dart';
import '../model/course_model.dart';

class CourseRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<CourseModel>> getAllCourses() async {
    try {
      final response = await _apiClient.get('/courses');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CourseModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching all courses: $e');
      return [];
    }
  }

  Future<List<CourseModel>> getAllPublishedCourses() async {
    try {
      final response = await _apiClient.get('/courses?isPublished=true');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CourseModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching published courses: $e');
      return [];
    }
  }

  Future<CourseModel?> getCourseById(String id) async {
    try {
      final response = await _apiClient.get('/courses/$id');
      if (response.statusCode == 200) {
        return CourseModel.fromMap(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching course by id: $e');
      return null;
    }
  }

  Future<CourseModel?> createCourse(CourseModel course) async {
    try {
      final response = await _apiClient.post('/courses', course.toMap());
      if (response.statusCode == 201) {
        return CourseModel.fromMap(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error creating course: $e');
      return null;
    }
  }

  Future<CourseModel?> updateCourse(String id, CourseModel course) async {
    try {
      final response = await _apiClient.put('/courses/$id', course.toMap());
      if (response.statusCode == 200) {
        return CourseModel.fromMap(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error updating course: $e');
      return null;
    }
  }

  Future<bool> deleteCourse(String id) async {
    try {
      final response = await _apiClient.delete('/courses/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting course: $e');
      return false;
    }
  }

  Future<List<CourseModel>> searchCourses(String query) async {
    try {
      final response =
          await _apiClient.get('/courses?search=${Uri.encodeComponent(query)}&isPublished=true');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CourseModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching courses: $e');
      return [];
    }
  }

  Future<List<CourseModel>> getCoursesByCategory(String category) async {
    try {
      final response = await _apiClient.get(
          '/courses?category=${Uri.encodeComponent(category)}&isPublished=true');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CourseModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching courses by category: $e');
      return [];
    }
  }

  Future<List<CourseModel>> getCoursesByLevel(String level) async {
    try {
      final response = await _apiClient
          .get('/courses?level=${Uri.encodeComponent(level)}&isPublished=true');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CourseModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching courses by level: $e');
      return [];
    }
  }

  Future<int> getCourseCount({bool publishedOnly = true}) async {
    try {
      final query = publishedOnly ? '?isPublished=true' : '';
      final response = await _apiClient.get('/courses$query');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.length;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting course count: $e');
      return 0;
    }
  }

  Future<void> incrementEnrollment(String courseId) async {
    // This is now handled server-side in the enroll endpoint
    // No-op on client side
  }

  Future<void> updateCourseRating(String courseId, double rating) async {
    try {
      await _apiClient.post('/courses/$courseId/rate', {'rating': rating});
    } catch (e) {
      debugPrint('Error updating course rating: $e');
    }
  }

  /// Returns a broadcast stream that polls published courses every 30 seconds
  Stream<List<CourseModel>> streamPublishedCourses() {
    return Stream.periodic(const Duration(seconds: 30))
        .asyncMap((_) => getAllPublishedCourses())
        .distinct();
  }
}
