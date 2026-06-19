// lib/business_logic/certificate_manager.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../repository/certificate_repository.dart';
import '../repository/user_repository.dart';
import '../model/certificate_model.dart';

class CertificateManager {
  final CertificateRepository _certificateRepository = CertificateRepository();
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate and save certificate for lesson completion
  Future<CertificateModel?> generateCertificate({
    required String courseId,
    required String courseName,
    required String lessonId,
    required String lessonName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if certificate already exists
      final exists = await _certificateRepository.certificateExists(
        userId: user.uid,
        courseId: courseId,
        lessonId: lessonId,
      );

      if (exists) {
        // Return existing certificate
        final certificates = await _certificateRepository.getUserCertificates(user.uid);
        return certificates.firstWhere(
          (cert) => cert.courseId == courseId && cert.lessonId == lessonId,
          orElse: () => throw Exception('Certificate not found'),
        );
      }

      // Get user name
      final userProfile = await _userRepository.getUserProfile(user.uid);
      final userName = userProfile?['displayName'] as String? ??
          user.displayName ??
          user.email?.split('@')[0] ??
          'Student';

      // Create new certificate
      final certificate = await _certificateRepository.createCertificate(
        userId: user.uid,
        userName: userName,
        courseId: courseId,
        courseName: courseName,
        lessonId: lessonId,
        lessonName: lessonName,
      );

      return certificate;
    } catch (e) {
      print('Error generating certificate: $e');
      return null;
    }
  }

  // Get all certificates for current user
  Future<List<CertificateModel>> getUserCertificates() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      return await _certificateRepository.getUserCertificates(user.uid);
    } catch (e) {
      print('Error getting user certificates: $e');
      return [];
    }
  }
}
