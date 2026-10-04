import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../business_logic/auth_manager.dart';
import '../repository/auth_repository.dart';
import '../repository/user_repository.dart';
import '../utils/profile_options.dart';
import '../widgets/notebook/notebook.dart';
import 'auth_shell.dart';
import 'student/policies_screen.dart';

const _levels = learnerLevels;
const _interests = learnerInterests;

/// Sign up and onboarding in one page: who you are, where you're starting
/// from, and what you want to learn — all saved to your profile.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _auth = AuthManager();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _level = _levels.first;
  String _interest = _interests.first;
  bool _agreed = false;
  bool _hidePassword = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    if (!_agreed) {
      setState(() => _error = 'Please accept the terms to continue');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _auth.register(_email.text.trim(), _password.text, displayName: _name.text.trim());
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    // Account exists now; store the onboarding answers on the profile.
    try {
      final uid = await AuthRepository().getCurrentUserUid();
      if (uid != null) {
        await UserRepository().saveOnboardingData(uid: uid, displayName: _name.text.trim(), grade: _level, interest: _interest);
      }
    } on Exception {
      // Not fatal: they can fill this in later under Edit profile.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthShell(
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Start your notebook', style: theme.textTheme.headlineMedium),
            const MarginNote('takes a minute', tilt: 0),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              autofillHints: const [AutofillHints.name],
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'What should we call you?' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => RegExp(r'^\S+@\S+\.\S+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email address',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _hidePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 8 characters, letters and numbers',
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              validator: (v) => RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(v ?? '')
                  ? null
                  : 'At least 8 characters, with letters and numbers',
            ),
            const SizedBox(height: 20),
            Text('Where are you starting from?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final l in _levels) ChoiceChip(label: Text(l), selected: _level == l, onSelected: (_) => setState(() => _level = l)),
            ]),
            const SizedBox(height: 16),
            Text('What do you most want to learn?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final i in _interests)
                ChoiceChip(label: Text(i), selected: _interest == i, onSelected: (_) => setState(() => _interest = i)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(value: _agreed, onChanged: (v) => setState(() => _agreed = v ?? false)),
              const Text('I accept the '),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoliciesScreen())),
                child: Text('terms & privacy policy', style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline)),
              ),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _create,
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create account'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Already have an account? Sign in'),
            ),
          ]),
        ),
      ),
    );
  }
}
