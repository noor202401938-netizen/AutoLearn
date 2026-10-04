import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_shell.dart';

/// First launch: the notebook cover and two ways in.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _go(BuildContext context, String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
    if (context.mounted) Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.of(context).size.width >= 900;
    return AuthShell(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!wide) const NotebookCover(compact: true),
        Text('Start a new notebook', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Learn micro- and macroeconomics the way you would with a good teacher: '
          'short readings, diagrams you can play with, practice questions, and someone to ask.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () => _go(context, '/signup'), child: const Text('Create an account')),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () => _go(context, '/login'), child: const Text('I already have one')),
      ]),
    );
  }
}
