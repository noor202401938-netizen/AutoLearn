// lib/screens/role_based_wrapper.dart
import 'package:flutter/material.dart';
import '../backend/api_client.dart';
import '../repository/auth_repository.dart';
import 'admin/admin_home.dart';
import 'student/student_home.dart';

class RoleBasedWrapper extends StatefulWidget {
  const RoleBasedWrapper({super.key});

  @override
  State<RoleBasedWrapper> createState() => _RoleBasedWrapperState();
}

class _RoleBasedWrapperState extends State<RoleBasedWrapper> {
  final AuthRepository _authRepository = AuthRepository();
  String? _role;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await ApiClient.instance.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    final uid = await _authRepository.getCurrentUserUid();
    if (uid == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    final role = await _authRepository.getUserRole(uid);
    if (mounted) {
      setState(() {
        _role = role;
        _isAuthenticated = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (!_isAuthenticated) {
      // Redirect handled in initState, show loader while redirecting
      return const Scaffold(body: SizedBox.shrink());
    }

    if (_role == 'admin') {
      return const AdminHome();
    } else {
      return const StudentHome();
    }
  }
}