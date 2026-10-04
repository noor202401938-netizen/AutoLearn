import 'package:flutter/material.dart';
import '../../widgets/notebook/notebook.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NotebookPage(
      title: 'About',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(padding: const EdgeInsets.all(32), children: [
            const Center(child: NotebookMark(size: 140)),
            const SizedBox(height: 16),
            Center(child: Text('AutoLearn', style: theme.textTheme.displayMedium)),
            const Center(child: MarginNote('version 1.0.0', tilt: 0)),
            const SizedBox(height: 28),
            const NoteText(
              'AutoLearn is a learning platform for any subject, built to teach the way a good teacher would: '
              'lessons that explain the idea, practice questions with worked explanations, marked assignments, '
              'and a tutor you can ask when you\'re stuck.\n\n'
              'Everything you learn goes into your own notebook — progress, bookmarks, notes pinned to '
              'moments in a lecture, and the certificates you earn.',
            ),
          ]),
        ),
      ),
    );
  }
}
