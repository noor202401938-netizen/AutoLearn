import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/notebook/notebook.dart';
import 'policies_screen.dart';

const _faq = [
  ('How do I enrol in a course?',
      'Open a course from Courses and press Enrol. Free courses start straight away; paid ones ask for payment first.'),
  ('How do I finish a course?',
      "Tick off every lesson — read it, watch it, pass its quiz or hand in its assignment — or pass the course's final test. Your certificate appears under Certificates."),
  ('Who marks my assignments?',
      "The AI tutor reads your answer against the brief and gives a score with feedback. You can revise and resubmit as often as you like."),
  ('How do I reset my password?', 'On the sign-in page choose "Forgot password?" and we\'ll email you a link.'),
  ('Can I use AutoLearn offline?', 'Not yet — lessons, the tutor and your progress all need a connection.'),
];

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NotebookPage(
      title: 'Help',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Text('How can we help?', style: theme.textTheme.displaySmall),
            const SizedBox(height: 20),
            NoteCard(
              onTap: () => launchUrl(Uri(scheme: 'mailto', path: 'support@autolearn.com', query: 'subject=AutoLearn help')),
              child: Row(children: [
                const Icon(Icons.mail_outline),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Write to us', style: theme.textTheme.titleMedium),
                    Text('support@autolearn.com', style: theme.textTheme.bodyMedium),
                  ]),
                ),
                const Icon(Icons.arrow_forward),
              ]),
            ),
            const SizedBox(height: 28),
            const NoteHeading('Common questions'),
            const SizedBox(height: 8),
            for (final (q, a) in _faq)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                title: Text(q, style: theme.textTheme.titleMedium),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                expandedAlignment: Alignment.topLeft,
                children: [Text(a, style: theme.textTheme.bodyLarge)],
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoliciesScreen())),
              child: const Text('Terms & privacy policy'),
            ),
          ]),
        ),
      ),
    );
  }
}
