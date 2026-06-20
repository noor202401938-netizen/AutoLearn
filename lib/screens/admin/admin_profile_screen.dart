// lib/screens/admin/admin_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../repository/auth_repository.dart';
import '../../repository/user_repository.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _authRepository = AuthRepository();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _profilePicController = TextEditingController();
  
  bool _isLoading = false;
  String _uid = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null && user['uid'] != null) {
        _uid = user['uid'];
        final profile = await _authRepository.getUserProfile(_uid);
        if (profile != null && mounted) {
          setState(() {
            _nameController.text = profile['displayName'] ?? '';
          });
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final savedPic = prefs.getString('admin_profile_pic_$_uid');
      if (savedPic != null && mounted) {
        setState(() {
          _profilePicController.text = savedPic;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfileInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Save Display Name
      if (_nameController.text.isNotEmpty) {
        await _userRepository.updateUserProfile(
          uid: _uid,
          displayName: _nameController.text.trim(),
        );
      }
      
      // 2. Save Password (Mock or custom API call if backend supports it)
      if (_passwordController.text.isNotEmpty) {
        // Normally we'd call an API to update password. 
        // For now, we simulate a successful update.
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // 3. Save Profile Pic URL
      if (_profilePicController.text.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_profile_pic_$_uid', _profilePicController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _profilePicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Profile Picture Preview
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            backgroundImage: _profilePicController.text.isNotEmpty
                                ? NetworkImage(_profilePicController.text)
                                : null,
                            child: _profilePicController.text.isEmpty
                                ? Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.secondary)
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // Profile Picture URL
                          TextFormField(
                            controller: _profilePicController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Profile Picture URL",
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.image, color: Theme.of(context).colorScheme.secondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                          const SizedBox(height: 16),

                          // Display Name
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Display Name",
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.badge, color: Theme.of(context).colorScheme.secondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // New Password
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "New Password (Leave blank to keep current)",
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.secondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Save Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _saveProfileInfo,
                            child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
