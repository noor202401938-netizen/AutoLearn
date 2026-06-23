// lib/business_logic/certificate_manager.dart
import 'package:flutter/foundation.dart';
import '../repository/auth_repository.dart';
import '../repository/certificate_repository.dart';
import '../repository/user_repository.dart';
import '../model/certificate_model.dart';

class CertificateManager {
  final CertificateRepository _certificateRepository = CertificateRepository();
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _authRepository = AuthRepository();

  // Generate and save certificate for lesson completion
  Future<CertificateModel?> generateCertificate({
    required String courseId,
    required String courseName,
    required String lessonId,
    required String lessonName,
  }) async {
    try {
      final uid = await _authRepository.getCurrentUserUid();
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Check if certificate already exists
      final exists = await _certificateRepository.certificateExists(
        userId: uid,
        courseId: courseId,
        lessonId: lessonId,
      );

      if (exists) {
        // Return existing certificate
        final certificates = await _certificateRepository.getUserCertificates(uid);
        return certificates.firstWhere(
          (cert) => cert.courseId == courseId && cert.lessonId == lessonId,
          orElse: () => throw Exception('Certificate not found'),
        );
      }

      // Get user name
      final userProfile = await _userRepository.getUserProfile(uid);
      final userName = userProfile?['displayName'] as String? ??
          userProfile?['email']?.toString().split('@')[0] ??
          'Student';

      // Create new certificate
      final certificate = await _certificateRepository.createCertificate(
        userId: uid,
        userName: userName,
        courseId: courseId,
        courseName: courseName,
        lessonId: lessonId,
        lessonName: lessonName,
      );

      return certificate;
    } catch (e) {
      debugPrint('Error generating certificate: $e');
      return null;
    }
  }

  // Get all certificates for current user
  Future<List<CertificateModel>> getUserCertificates() async {
    try {
      final uid = await _authRepository.getCurrentUserUid();
      if (uid == null) {
        return [];
      }

      return await _certificateRepository.getUserCertificates(uid);
    } catch (e) {
      debugPrint('Error getting user certificates: $e');
      return [];
    }
  }
}
