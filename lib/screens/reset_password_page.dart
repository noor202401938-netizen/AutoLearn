import 'package:flutter/material.dart';
import '../repository/auth_repository.dart';
import '../widgets/notebook/notebook.dart';

/// Opened from the emailed link: /reset-password?token=…
class ResetPasswordPage extends StatefulWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await AuthRepository().confirmPasswordReset(widget.token, _password.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
      _done = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(children: [
        const GraphPaper(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: NoteCard(
                padding: const EdgeInsets.all(28),
                child: _done
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('Password updated', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        const MarginNote('you can sign in with it now', tilt: 0),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text('Go to sign in'),
                        ),
                      ])
                    : Form(
                        key: _form,
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text('Choose a new password', style: theme.textTheme.headlineMedium),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'New password'),
                            validator: (v) => (v ?? '').length < 6 ? 'At least 6 characters' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirm,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Repeat it'),
                            validator: (v) => v != _password.text ? "Passwords don't match" : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton(onPressed: _saving ? null : _save, child: const Text('Save password')),
                        ]),
                      ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
