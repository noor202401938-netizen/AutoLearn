// lib/model/certificate_model.dart

class CertificateModel {
  final String certificateId;
  final String userId;
  final String userName;
  final String courseId;
  final String courseName;
  final String lessonId;
  final String lessonName;
  final DateTime completionDate;
  final String dayOfWeek; // e.g., "Monday", "Tuesday", etc.

  CertificateModel({
    required this.certificateId,
    required this.userId,
    required this.userName,
    required this.courseId,
    required this.courseName,
    required this.lessonId,
    required this.lessonName,
    required this.completionDate,
    required this.dayOfWeek,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'certificateId': certificateId,
      'userId': userId,
      'userName': userName,
      'courseId': courseId,
      'courseName': courseName,
      'lessonId': lessonId,
      'lessonName': lessonName,
      'completionDate': completionDate.toIso8601String(),
      'dayOfWeek': dayOfWeek,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore document
  factory CertificateModel.fromMap(Map<String, dynamic> map) {
    return CertificateModel(
      certificateId: map['certificateId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      lessonId: map['lessonId'] ?? '',
      lessonName: map['lessonName'] ?? '',
      completionDate: (map['completionDate'] as Timestamp).toDate(),
      dayOfWeek: map['dayOfWeek'] ?? '',
    );
  }

  // Helper to get day of week from date
  static String getDayOfWeek(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }
}

