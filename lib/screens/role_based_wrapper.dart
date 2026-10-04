// lib/screens/role_based_wrapper.dart
import 'package:flutter/material.dart';
import '../backend/api_client.dart';
import '../repository/auth_repository.dart';
import '../widgets/notebook/notebook.dart';
import 'admin/admin_home.dart';
import 'student/student_home.dart';

/// Checks the saved session with the server, then opens the student or
/// admin notebook. An expired or revoked session goes back to sign-in.
class RoleBasedWrapper extends StatefulWidget {
  const RoleBasedWrapper({super.key});

  @override
  State<RoleBasedWrapper> createState() => _RoleBasedWrapperState();
}

class _RoleBasedWrapperState extends State<RoleBasedWrapper> {
  String? _role;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _error = null);
    if (await ApiClient.instance.getToken() == null) return _toLogin();
    try {
      // The server is the source of truth for both the session and the role.
      final me = await ApiClient.instance.json('GET', '/auth/me');
      if (mounted) setState(() => _role = me['role'] as String? ?? 'student');
    } on ApiException catch (e) {
      if (e.status == 401 || e.status == 403 || e.status == 404) {
        await AuthRepository().logoutUser();
        return _toLogin();
      }
      if (mounted) setState(() => _error = e.message); // offline etc. — let them retry
    }
  }

  void _toLogin() {
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_role == 'admin') return const AdminHome(key: ValueKey('admin_home'));
    if (_role != null) return const StudentHome(key: ValueKey('student_home'));
    return Scaffold(
      body: Stack(children: [
        const GraphPaper(),
        _error != null
            ? NotebookError(message: _error!, onRetry: _check)
            : const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}
