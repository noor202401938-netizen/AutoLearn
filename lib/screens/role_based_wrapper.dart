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

class _RoleBasedWrapperState extends State<RoleBasedWrapper> with SingleTickerProviderStateMixin {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _buildContent(context, colorScheme, isDark),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme, bool isDark) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        key: const ValueKey('loading'),
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
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
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isAuthenticated) {
      // Redirect handled in initState, show blank placeholder while redirecting
      return Scaffold(
        key: const ValueKey('unauthenticated'),
        backgroundColor: colorScheme.surface,
        body: const SizedBox.shrink(),
      );
    }

    if (_role == 'admin') {
      return const AdminHome(key: ValueKey('admin_home'));
    } else {
      return const StudentHome(key: ValueKey('student_home'));
    }
  }
}
