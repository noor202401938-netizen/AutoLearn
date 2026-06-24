// lib/screens/student/edit_profile_screen.dart
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
          const SnackBar(content: Text('User not found'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final displayName = _nameController.text.trim();
      
      // Update profile via API
      await _userRepository.updateUserProfile(
        uid: uid,
        displayName: displayName,
        phone: _phoneController.text.trim(),
        grade: _gradeController.text.trim(),
        interest: _interestController.text.trim(),
      );

      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Edit Profile', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: const Color(0xFF4231C0),
          )
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: Color(0xFF4231C0)),
      ),
      body: Container(
        child: SafeArea(
          child: _isLoading && _userProfile == null
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4231C0)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Profile Picture Placeholder
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFFE6EEFF),
                          child: Text(
                            (_nameController.text.isNotEmpty
                                    ? _nameController.text
                                    : (_userProfile?['email'] ?? 'U'))[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4231C0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Display Name
                    _buildTextField(
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
                    
                    // Email (read-only)
                    _buildTextField(
                      controller: TextEditingController(text: _userProfile?['email'] ?? ''),
                      label: 'Email',
                      hint: '',
                      icon: Icons.email_outlined,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    // Grade Dropdown
                    _buildDropdown(
                      value: _gradeController.text.isEmpty ? null : _gradeController.text,
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
                    
                    // Interest Dropdown
                    _buildDropdown(
                      value: _interestController.text.isEmpty ? null : _interestController.text,
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
                    
                    // Save Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4231C0),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4231C0).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
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
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4231C0).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(color: readOnly ? const Color(0xFF121C2A).withOpacity(0.5) : const Color(0xFF121C2A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: const Color(0xFF787586)),
          hintText: hint,
          hintStyle: TextStyle(color: const Color(0xFFC8C4D7)),
          prefixIcon: Icon(icon, color: const Color(0xFF4231C0)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4231C0).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Colors.white,
        style: const TextStyle(color: Color(0xFF121C2A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: const Color(0xFF787586)),
          prefixIcon: Icon(icon, color: const Color(0xFF4231C0)),
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

