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

class _RoleBasedWrapperState extends State<RoleBasedWrapper>
    with SingleTickerProviderStateMixin {
  final AuthRepository _authRepository = AuthRepository();
  // _role is null while loading, then set to 'admin' or 'student'
  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await ApiClient.instance.getToken();
    if (token == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final uid = await _authRepository.getCurrentUserUid();
    if (uid == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final role = await _authRepository.getUserRole(uid);
    if (mounted) {
      setState(() {
        _role = role;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _buildContent(colorScheme, isDark),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, bool isDark) {
    if (_isLoading) {
      return Scaffold(
        key: const ValueKey('loading'),
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Authenticating...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Auth succeeded — route by role
    if (_role == 'admin') {
      return const AdminHome(key: ValueKey('admin_home'));
    }
    return const StudentHome(key: ValueKey('student_home'));
  }
}
