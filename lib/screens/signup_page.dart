import 'package:flutter/material.dart';
import '../business_logic/auth_manager.dart';
import '../repository/user_repository.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final AuthManager _authManager = AuthManager();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showErrorSnackBar("Please agree to Terms & Conditions");
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final result = await _authManager.register(email, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result == null || result == "success") {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showErrorSnackBar(result);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Registration failed: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          final formContent = FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 60 : 24, vertical: 40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: EdgeInsets.all(isDesktop ? 40 : 28),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.school_rounded,
                                size: 32, color: colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          "Create Account",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start your learning journey today",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            hintText: "Enter your full name",
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter your name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email address",
                            hintText: "Enter your email",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter your email';
                            if (!value.contains('@'))
                              return 'Please enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            hintText: "Create a password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter a password';
                            if (value.length < 8)
                              return 'Password must be at least 8 characters';
                            if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)')
                                .hasMatch(value)) {
                              return 'Password must be alphanumeric';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            hintText: "Re-enter your password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please confirm your password';
                            if (value != _passwordController.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _agreeToTerms,
                                onChanged: (v) =>
                                    setState(() => _agreeToTerms = v ?? false),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                activeColor: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _agreeToTerms = !_agreeToTerms),
                                child: RichText(
                                  text: TextSpan(
                                    style: theme.textTheme.bodySmall,
                                    children: [
                                      const TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _registerUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    "Sign Up",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have an account? ",
                                style: theme.textTheme.bodyMedium),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                  context, '/login'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                              ),
                              child: Text("Sign in",
                                  style: theme.textTheme.labelLarge
                                      ?.copyWith(color: colorScheme.primary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          if (isDesktop) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    color: colorScheme.surface,
                    child: formContent,
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    color: colorScheme.surface,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                )
                              ],
                            ),
                            child: Icon(Icons.school_rounded,
                                size: 48, color: colorScheme.onPrimary),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            "AutoLearn",
                            style: theme.textTheme.displayMedium
                                ?.copyWith(color: colorScheme.primary),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              "Create an account and start\nunlocking your potential today.",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return formContent;
        },
      ),
    );
  }
}
