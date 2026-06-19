import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  Future<void> updateUserRole(String uid, String role) async {}
  Future<void> deleteUserProfile(String uid) async {}
  Stream<DocumentSnapshot<Object?>> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }
  Future<void> updateUserProfile({required String uid, String? displayName, String? phone, String? grade, String? interest}) async {}
}


