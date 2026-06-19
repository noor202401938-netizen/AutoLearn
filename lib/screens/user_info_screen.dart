// lib/screens/user_info_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedGrade = 'High School';
  String _selectedInterest = 'Technology';
  bool _isLoading = false;

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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Just save the preferences, don't need Firebase user yet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedUserInfo', true);

      // Store user info for later use
      await prefs.setString('userName', _nameController.text.trim());
      await prefs.setString('userPhone', _phoneController.text.trim());
      await prefs.setString('userGrade', _selectedGrade);
      await prefs.setString('userInterest', _selectedInterest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Information saved! Please sign up to continue.'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to signup page
        Navigator.pushReplacementNamed(context, '/signup');
      }
    } catch (e) {
      print('Error saving user info: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // White Card Container
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 40,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Tell Us About Yourself",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Help us personalize your learning experience",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: "Full Name",
                              hintText: "Enter your full name",
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone Number (Optional)
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: "Phone Number (Optional)",
                              hintText: "Enter your phone number",
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Education Level Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGrade,
                            decoration: InputDecoration(
                              labelText: "Education Level",
                              prefixIcon: Icon(
                                Icons.school_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            items: _grades.map((grade) {
                              return DropdownMenuItem(
                                value: grade,
                                child: Text(grade),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedGrade = value!);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Interest Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedInterest,
                            decoration: InputDecoration(
                              labelText: "Primary Interest",
                              prefixIcon: Icon(
                                Icons.interests_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            items: _interests.map((interest) {
                              return DropdownMenuItem(
                                value: interest,
                                child: Text(interest),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedInterest = value!);
                            },
                          ),
                          const SizedBox(height: 28),

                          // Continue Button
                          _isLoading
                              ? Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                              : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            onPressed: _saveUserInfo,
                            child: const Text(
                              "Continue",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Skip Button
                          TextButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('hasCompletedUserInfo', true);
                              if (mounted) {
                                Navigator.pushReplacementNamed(context, '/signup');
                              }
                            },
                            child: Text(
                              "Skip for now",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Already have account link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 15,
                                  ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setBool('hasCompletedUserInfo', true);
                                  if (mounted) {
                                    Navigator.pushReplacementNamed(context, '/login');
                                  }
                                },
                                child: Text(
                                  "Login",
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}