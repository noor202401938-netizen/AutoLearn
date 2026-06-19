// lib/business_logic/auth_manager.dart
import '../repository/auth_repository.dart';

class AuthManager {
  final AuthRepository _authRepository = AuthRepository();

  Future<String?> register(String email, String password) async {
    if (!_isPasswordValid(password)) {
      return "Password must be at least 8 characters long and alphanumeric.";
    }

    try {
      final user = await _authRepository.registerUser(email, password);
      return user != null ? null : "Failed to register user.";
    } catch (e) {
      return "Registration failed: ${e.toString()}";
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final user = await _authRepository.loginUser(email, password);
      return user != null ? null : "Invalid email or password.";
    } catch (e) {
      return "Login failed: ${e.toString()}";
    }
  }

  Future<void> logout() async {
    await _authRepository.logoutUser();
  }

  bool _isPasswordValid(String password) {
    final alphanumeric = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
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