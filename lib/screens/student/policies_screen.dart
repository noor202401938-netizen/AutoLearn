import 'package:flutter/material.dart';
import '../../widgets/notebook/notebook.dart';

// Plain-language terms. Keep this in step with what the app actually does.
const _terms = '''
## Terms of use

AutoLearn is an educational service. Use it to learn, and don't use it to harm others, attack the service, or share content you don't have the right to share. We may suspend accounts that do.

Course material, quizzes and AI feedback are for learning. They are not professional advice.

## What we store

- **Your account:** email, name, and the optional details you give us (phone, level, interests). Passwords are stored only as a one-way hash.
- **Your learning:** enrolments, lesson progress, quiz answers and scores, assignment submissions and files you upload, bookmarks and notes, forum posts.
- **Payments:** handled by Stripe. We keep the amount and status, never your card details.

## The AI tutor

Questions you ask the tutor, quiz generation requests, and assignment answers sent for marking are processed by OpenAI to produce a response. Don't include personal information you wouldn't want shared with that service.

## Your choices

We don't sell your data. To get a copy of it or delete your account, write to support@autolearn.com.
''';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) => NotebookPage(
        title: 'Terms & privacy',
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(padding: const EdgeInsets.all(24), children: const [
              NoteText(_terms),
              MarginNote('last updated October 2026', size: 18, tilt: 0),
            ]),
          ),
        ),
      );
}
