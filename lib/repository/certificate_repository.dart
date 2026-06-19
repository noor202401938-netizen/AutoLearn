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
          certificateId: json['id'],
          userId: json['userId'],
          courseId: json['courseId'],
          courseName: json['course'] != null ? json['course']['title'] : 'Course',
          completionDate: DateTime.parse(json['issueDate']),
          certificateURL: json['certificateUrl'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<CertificateModel?> generateCertificate({
    required String uid,
    required String courseId,
    required String courseName,
    required String studentName,
  }) async {
    // In production, backend should generate the certificate
    return null;
  }
  Future<bool> certificateExists({required String userId, required String courseId, required String lessonId}) async { return false; }
  Future<CertificateModel?> createCertificate({
    required String userId,
    required String userName,
    required String courseId,
    required String courseName,
    required String lessonId,
    required String lessonName,
  }) async { return null; }
}


