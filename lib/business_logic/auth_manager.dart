// lib/business_logic/auth_manager.dart
import '../repository/auth_repository.dart';

class AuthManager {
  final AuthRepository _authRepository = AuthRepository();

  Future<String?> register(String email, String password, {String? displayName}) async {
    if (!_isPasswordValid(password)) {
      return 'Use at least 8 characters, with both letters and numbers.';
    }

    try {
      final user = await _authRepository.registerUser(email, password, displayName: displayName);
      return user != null ? null : 'Could not create your account. Please try again.';
    } on Exception catch (e) {
      return _clean(e);
    }
  }

  /// "Exception: Exception: User already exists" -> "User already exists".
  String _clean(Exception e) => e.toString().replaceAll(RegExp(r'^(Exception: )+|(Login error|Registration error): (Exception: )*'), '');

  Future<String?> login(String email, String password,
      {bool rememberMe = false}) async {
    try {
      final user =
          await _authRepository.loginUser(email, password, rememberMe: rememberMe);
      return user != null ? null : 'Invalid email or password.';
    } on Exception catch (e) {
      return _clean(e);
    }
  }

  Future<void> logout() async {
    await _authRepository.logoutUser();
  }

  bool _isPasswordValid(String password) {
    // Letters and digits required; symbols allowed.
    final alphanumeric = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');
    return alphanumeric.hasMatch(password);
  }

  Future<bool> isLoggedIn() async {
    return await _authRepository.isLoggedIn();
  }

  Future<String?> getCurrentUserUid() async {
    return await _authRepository.getCurrentUserUid();
  }

  // Get user role
  Future<String> getUserRole(String uid) async {
    return await _authRepository.getUserRole(uid);
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    return await _authRepository.getUserProfile(uid);
  }

  // Send password reset email
  Future<String?> sendPasswordResetEmail(String email) async {
    return await _authRepository.sendPasswordResetEmail(email);
  }
}
