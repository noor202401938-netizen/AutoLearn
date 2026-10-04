import 'package:flutter/material.dart';
import '../../backend/api_client.dart';
import '../../utils/profile_options.dart';
import '../../widgets/notebook/notebook.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _level;
  String? _interest;
  String _email = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await ApiClient.instance.json('GET', '/user/profile') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _name.text = p['displayName'] as String? ?? '';
        _phone.text = p['phone'] as String? ?? '';
        _email = p['email'] as String? ?? '';
        // Older accounts may hold values from the previous option lists.
        _level = learnerLevels.contains(p['grade']) ? p['grade'] as String : null;
        _interest = learnerInterests.contains(p['interest']) ? p['interest'] as String : null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.instance.json('PUT', '/user/profile', body: {
        'displayName': _name.text.trim(),
        'phone': _phone.text.trim(),
        'grade': _level,
        'interest': _interest,
      });
      if (mounted) Navigator.pop(context, true);
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
      title: 'Edit profile',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  NoteCard(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _form,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if (_email.isNotEmpty) MarginNote(_email, tilt: 0, size: 19),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone (optional)'),
                        ),
                        const SizedBox(height: 20),
                        Text('Where are you starting from?', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final l in learnerLevels)
                            ChoiceChip(label: Text(l), selected: _level == l, onSelected: (_) => setState(() => _level = l)),
                        ]),
                        const SizedBox(height: 16),
                        Text('What do you most want to understand?', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final i in learnerInterests)
                            ChoiceChip(label: Text(i), selected: _interest == i, onSelected: (_) => setState(() => _interest = i)),
                        ]),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(onPressed: _saving ? null : _save, child: const Text('Save')),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }
}

