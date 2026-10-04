import 'package:flutter/material.dart';
import '../business_logic/auth_manager.dart';
import '../widgets/notebook/notebook.dart';
import 'auth_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthManager();
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _rememberMe = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _auth.login(_email.text.trim(), _password.text, rememberMe: _rememberMe);
    if (!mounted) return;
    if (error == null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  Future<void> _forgotPassword() async {
    final email = TextEditingController(text: _email.text.trim());
    final sent = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset your password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("We'll email you a link to choose a new one."),
          const SizedBox(height: 16),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async => Navigator.pop(c, await _auth.sendPasswordResetEmail(email.text.trim()) ?? 'ok'),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    email.dispose();
    if (sent == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sent == 'ok' ? 'If that email has an account, a reset link is on its way.' : sent),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthShell(
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Welcome back', style: theme.textTheme.headlineMedium),
            const MarginNote('pick up where you left off', tilt: 0),
            const SizedBox(height: 24),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => (v ?? '').contains('@') ? null : 'Enter your email address',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _hidePassword,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _signIn(),
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
            ),
            const SizedBox(height: 6),
            Row(children: [
              Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v ?? false)),
              const Text('Remember me'),
              const Spacer(),
              TextButton(onPressed: _forgotPassword, child: const Text('Forgot password?')),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _signIn,
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
              child: const Text("New here? Create an account"),
            ),
          ]),
        ),
      ),
    );
  }
}
