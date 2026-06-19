// lib/repository/enrollment_repository.dart
import 'dart:async';
import 'dart:convert';
import '../backend/api_client.dart';

class EnrollmentRepository {
  final ApiClient _apiClient = ApiClient.instance;

  // Enroll the authenticated user in a course
  Future<void> enrollUser({required String uid, required String courseId}) async {
    final response = await _apiClient.post('/courses/$courseId/enroll', {});
    if (response.statusCode != 201 && response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to enroll');
    }
  }

  // Check if user is enrolled in a course via their enrollments endpoint
  Future<bool> isUserEnrolled({required String uid, required String courseId}) async {
    try {
      final response = await _apiClient.get('/user/enrollments');
      if (response.statusCode == 200) {
        final List<dynamic> enrollments = jsonDecode(response.body);
        return enrollments.any((e) => e['courseId'] == courseId);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<int> getEnrollmentCount(String courseId) async {
    try {
      final response = await _apiClient.get('/courses/$courseId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['enrollmentCount'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<String>> getUserEnrolledCourseIds(String uid) async {
    try {
      final response = await _apiClient.get('/user/enrollments');
      if (response.statusCode == 200) {
        final List<dynamic> enrollments = jsonDecode(response.body);
        return enrollments.map<String>((e) => e['courseId'].toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Polls enrollment status every 5s to power a Stream for UI
  Stream<bool> watchEnrollment({required String uid, required String courseId}) {
    return Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => isUserEnrolled(uid: uid, courseId: courseId))
        .distinct();
  }

  Future<List<String>> getUserCourseIds({required String uid}) async {
    return getUserEnrolledCourseIds(uid);
  }
}
