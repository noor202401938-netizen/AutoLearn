// lib/repository/certificate_repository.dart
import 'dart:convert';
import '../backend/api_client.dart';
import '../model/certificate_model.dart';

class CertificateRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<CertificateModel>> getUserCertificates(String uid) async {
    try {
      final response = await _apiClient.get('/user/certificates');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CertificateModel(
          certificateId: json['id'],
          userId: json['userId'],
          courseId: json['courseId'],
          courseName: json['course'] != null ? json['course']['title'] : 'Course',
          issueDate: DateTime.parse(json['issueDate']),
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
  Future<bool> certificateExists({required String uid, required String courseId}) async { return false; }
  Future<void> createCertificate(dynamic certificate) async {}
}

