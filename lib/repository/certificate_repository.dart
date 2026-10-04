import '../backend/api_client.dart';
import '../model/certificate_model.dart';

class CertificateRepository {
  final ApiClient _api = ApiClient.instance;

  Future<List<CertificateModel>> list() async {
    final data = await _api.json('GET', '/user/certificates') as List;
    return data.map((j) => CertificateModel.fromMap(j as Map<String, dynamic>)).toList();
  }

  /// Asks the server for the course certificate. The server only issues it
  /// once every lesson is done or the final quiz ([lessonId]) is passed, so
  /// this returns null when it hasn't been earned yet.
  Future<CertificateModel?> issueIfEarned({required String courseId, String? lessonId}) async {
    try {
      final data = await _api.json('POST', '/user/certificates', body: {'courseId': courseId, 'lessonId': lessonId});
      return CertificateModel.fromMap(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.status == 403) return null;
      rethrow;
    }
  }
}
