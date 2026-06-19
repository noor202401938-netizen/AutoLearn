// lib/repository/certificate_repository.dart
import 'dart:convert';
import '../backend/api_client.dart';
import '../model/certificate_model.dart';

class CertificateRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<CertificateModel>> getUserCertificates(String userId) async {
    try {
      final response = await _apiClient.get('/user/certificates');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<CertificateModel>((json) => CertificateModel(
          certificateId: json['id'] ?? 'unknown',
          userId: json['userId'] ?? userId,
          userName: json['userName'] ?? 'Student',
          courseId: json['courseId'] ?? 'unknown_course',
          courseName: json['course'] != null ? json['course']['title'] : 'Course',
          lessonId: json['lessonId'] ?? 'unknown_lesson',
          lessonName: json['lessonName'] ?? 'Lesson',
          completionDate: json['issueDate'] != null ? DateTime.tryParse(json['issueDate']) ?? DateTime.now() : DateTime.now(),
          dayOfWeek: json['dayOfWeek'] ?? 'Monday',
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> certificateExists({required String userId, required String courseId, required String lessonId}) async {
    try {
      final response = await _apiClient.get('/user/certificates/check?courseId=$courseId&lessonId=$lessonId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<CertificateModel?> createCertificate({
    required String userId,
    required String userName,
    required String courseId,
    required String courseName,
    required String lessonId,
    required String lessonName,
  }) async {
    try {
      final response = await _apiClient.post('/user/certificates', {
        'userId': userId,
        'userName': userName,
        'courseId': courseId,
        'courseName': courseName,
        'lessonId': lessonId,
        'lessonName': lessonName,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return CertificateModel(
          certificateId: json['id'] ?? 'unknown',
          userId: json['userId'] ?? userId,
          userName: json['userName'] ?? userName,
          courseId: json['courseId'] ?? courseId,
          courseName: json['course'] != null ? json['course']['title'] : courseName,
          lessonId: json['lessonId'] ?? lessonId,
          lessonName: json['lessonName'] ?? lessonName,
          completionDate: json['issueDate'] != null ? DateTime.tryParse(json['issueDate']) ?? DateTime.now() : DateTime.now(),
          dayOfWeek: json['dayOfWeek'] ?? 'Monday',
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create certificate: $e');
    }
  }

  Future<CertificateModel?> generateCertificate({
    required String uid,
    required String courseId,
    required String courseName,
    required String studentName,
  }) async {
    return createCertificate(
      userId: uid,
      userName: studentName,
      courseId: courseId,
      courseName: courseName,
      lessonId: 'general',
      lessonName: 'Course Completion',
    );
  }
}
