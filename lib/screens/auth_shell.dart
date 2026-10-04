import 'package:flutter/material.dart';
import '../widgets/notebook/notebook.dart';

/// Shared layout for welcome / sign in / sign up: the notebook's cover on the
/// left (wide screens), the form on a sheet of paper on the right.
class AuthShell extends StatelessWidget {
  final Widget child;
  const AuthShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: NoteCard(padding: const EdgeInsets.all(28), child: child),
        ),
      ),
    );
    return Scaffold(
      body: Stack(children: [
        const GraphPaper(marginAt: 72),
        SafeArea(
          child: wide
              ? Row(children: [
                  const Expanded(child: NotebookCover()),
                  Expanded(child: form),
                ])
              : form,
        ),
      ]),
    );
  }
}

/// The app's "cover": the hand-drawn market diagram, the name, and three
/// margin notes on what's inside.
class NotebookCover extends StatelessWidget {
  final bool compact;
  const NotebookCover({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 0 : 104, 32, 32, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          NotebookMark(size: compact ? 150 : 200),
          const SizedBox(height: 24),
          Text('AutoLearn', style: theme.textTheme.displayLarge),
          const SizedBox(height: 4),
          const MarginNote('learn anything, in your own notes', size: 24),
          if (!compact) ...[
            const SizedBox(height: 36),
            for (final line in const [
              '→ courses in any subject, written to be understood',
              '→ quizzes, assignments and feedback that help you improve',
              '→ an AI tutor and a study group when you get stuck',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MarginNote(line, size: 21, tilt: 0, color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ],
      ),
    );
  }
}
