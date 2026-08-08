import 'package:flutter/material.dart';
import '../../repository/user_repository.dart';
import '../../repository/auth_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _authRepository = AuthRepository();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;

  final List<String> _grades = [
    'Elementary School',
    'Middle School',
    'High School',
    'Undergraduate',
    'Graduate',
    'Professional',
  ];

  final List<String> _interests = [
    'Technology',
    'Science',
    'Mathematics',
    'Arts',
    'Business',
    'Languages',
    'Engineering',
    'Medicine',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _gradeController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      final uid = user['uid'] as String?;
      if (uid != null) {
        final profile = await _authRepository.getUserProfile(uid);
        if (profile != null) {
          setState(() {
            _userProfile = profile;
            _nameController.text = profile['displayName'] ?? '';
            _phoneController.text = profile['phone'] ?? '';
            _gradeController.text = profile['grade'] ?? '';
            _interestController.text = profile['interest'] ?? '';
          });
        }
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = await _authRepository.getCurrentUser();
    final uid = user?['uid'] as String?;
    if (uid == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('User not found'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
      return;
    }

    try {
      final displayName = _nameController.text.trim();

      await _userRepository.updateUserProfile(
        uid: uid,
        displayName: displayName,
        phone: _phoneController.text.trim(),
        grade: _gradeController.text.trim(),
        interest: _interestController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: theme.colorScheme.primaryContainer,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
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
        title: Text('Edit Profile',
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: SafeArea(
        child: _isLoading && _userProfile == null
            ? Center(
                child:
                    CircularProgressIndicator(color: theme.colorScheme.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: theme.colorScheme.secondary
                                    .withValues(alpha: 0.5),
                                width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            child: Text(
                              (_nameController.text.isNotEmpty
                                      ? _nameController.text
                                      : (_userProfile?['email'] ?? 'U'))[0]
                                  .toUpperCase(),
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildTextField(
                        theme: theme,
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        theme: theme,
                        controller: TextEditingController(
                            text: _userProfile?['email'] ?? ''),
                        label: 'Email',
                        hint: '',
                        icon: Icons.email_outlined,
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        theme: theme,
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        theme: theme,
                        value: _gradeController.text.isEmpty
                            ? null
                            : _gradeController.text,
                        label: 'Grade/Level',
                        icon: Icons.school_outlined,
                        items: _grades,
                        onChanged: (value) {
                          setState(() {
                            _gradeController.text = value ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        theme: theme,
                        value: _interestController.text.isEmpty
                            ? null
                            : _interestController.text,
                        label: 'Interest',
                        icon: Icons.favorite_outline,
                        items: _interests,
                        onChanged: (value) {
                          setState(() {
                            _interestController.text = value ?? '';
                          });
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
                          onPressed: _isLoading ? null : _saveProfile,
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
                                  'Save Changes',
                                  style: theme.textTheme.labelLarge?.copyWith(
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
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: readOnly
              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
              : theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.outline),
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdown({
    required ThemeData theme,
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: theme.colorScheme.surface,
        style: theme.textTheme.bodyLarge
            ?.copyWith(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
