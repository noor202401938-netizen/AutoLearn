import 'package:flutter/material.dart';
import '../../backend/api_client.dart';
import '../../widgets/notebook/notebook.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.instance.json('POST', '/auth/change-password', body: {
        'currentPassword': _current.text,
        'newPassword': _next.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NotebookPage(
      title: 'Password',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: NoteCard(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Change your password', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _current,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Current password'),
                    validator: (v) => (v ?? '').isEmpty ? 'Enter your current password' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _next,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(labelText: 'New password', helperText: 'At least 8 characters, letters and numbers'),
                    validator: (v) => RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(v ?? '')
                        ? null
                        : 'At least 8 characters, with letters and numbers',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _repeat,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Repeat new password'),
                    validator: (v) => v != _next.text ? "Passwords don't match" : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _saving ? null : _save, child: const Text('Change password')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
