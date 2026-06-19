// lib/business_logic/enrollment_manager.dart
import '../repository/enrollment_repository.dart';
import '../repository/auth_repository.dart';

class EnrollmentManager {
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();
  final AuthRepository _authRepository = AuthRepository();

  Future<String?> _getUid() async {
    return await _authRepository.getCurrentUserUid();
  }

  Future<String?> enrollInCourse(String courseId) async {
    final uid = await _getUid();
    if (uid == null) return 'Not authenticated';
    try {
      final already = await _enrollmentRepository.isUserEnrolled(
          uid: uid, courseId: courseId);
      if (already) return null; // Already enrolled — no-op
      await _enrollmentRepository.enrollUser(uid: uid, courseId: courseId);
      return null;
    } catch (e) {
      return 'Failed to enroll: ${e.toString()}';
    }
  }

  Future<bool> isEnrolled(String courseId) async {
    final uid = await _getUid();
    if (uid == null) return false;
    return _enrollmentRepository.isUserEnrolled(uid: uid, courseId: courseId);
  }

  Stream<bool> watchEnrollment(String courseId) async* {
    final uid = await _getUid();
    if (uid == null) {
      yield false;
      return;
    }
    yield* _enrollmentRepository.watchEnrollment(
        uid: uid, courseId: courseId);
  }
}
