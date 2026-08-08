import 'package:flutter/material.dart';
import '../../repository/auth_repository.dart';
import '../../backend/api_client.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepository();
  final ApiClient _apiClient = ApiClient.instance;
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = await _authRepository.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not found. Please log in again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.post('/auth/change-password', {
        'currentPassword': _currentPasswordController.text.trim(),
        'newPassword': _newPasswordController.text.trim(),
      });

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password changed successfully'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Failed to change password. Check your current password.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Change Password',
            style: theme.textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            )),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Change Your Password',
                  style: theme.textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your current password and choose a new one',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  hint: 'Enter your current password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureCurrentPassword,
                  onToggleObscure: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hint: 'Enter your new password',
                  icon: Icons.lock,
                  obscureText: _obscureNewPassword,
                  onToggleObscure: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  hint: 'Re-enter your new password',
                  icon: Icons.lock,
                  obscureText: _obscureConfirmPassword,
                  onToggleObscure: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary),
                            ),
                          )
                        : Text(
                            'Change Password',
                            style: theme.textTheme.labelLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: theme.textTheme.bodyLarge!
            .copyWith(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyMedium!
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium!
              .copyWith(color: theme.colorScheme.outline),
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: validator,
      ),
    );
  }
}
