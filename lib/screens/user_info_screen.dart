import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedGrade = 'High School';
  String _selectedInterest = 'Technology';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedUserInfo', true);

      await prefs.setString('userName', _nameController.text.trim());
      await prefs.setString('userPhone', _phoneController.text.trim());
      await prefs.setString('userGrade', _selectedGrade);
      await prefs.setString('userInterest', _selectedInterest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Information saved! Please sign up to continue.', style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
            backgroundColor: colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pushReplacementNamed(context, '/signup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}', style: Theme.of(context).textTheme.bodyMedium),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        prefixIcon: Icon(prefixIcon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String value,
    required String labelText,
    required IconData prefixIcon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: colorScheme.surface,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(prefixIcon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
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
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Help us personalize your learning experience",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 28),

                            _buildTextField(
                              controller: _nameController,
                              labelText: "Full Name",
                              hintText: "Enter your full name",
                              prefixIcon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              labelText: "Phone Number (Optional)",
                              hintText: "Enter your phone number",
                              prefixIcon: Icons.phone_outlined,
                            ),
                            const SizedBox(height: 16),

                            _buildDropdown(
                              value: _selectedGrade,
                              labelText: "Education Level",
                              prefixIcon: Icons.school_outlined,
                              items: _grades,
                              onChanged: (value) {
                                setState(() => _selectedGrade = value!);
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildDropdown(
                              value: _selectedInterest,
                              labelText: "Primary Interest",
                              prefixIcon: Icons.interests_outlined,
                              items: _interests,
                              onChanged: (value) {
                                setState(() => _selectedInterest = value!);
                              },
                            ),
                            const SizedBox(height: 28),

                            _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(color: colorScheme.primary),
                                  )
                                : SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: _saveUserInfo,
                                      child: Text(
                                        "Continue",
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: colorScheme.onPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 12),

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
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: theme.textTheme.bodyMedium,
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
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
