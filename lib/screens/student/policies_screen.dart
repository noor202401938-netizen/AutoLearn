import 'package:flutter/material.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Policies & Terms', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: const Color(0xFF4231C0),
          )
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: Color(0xFF4231C0)),
      ),
      body: Container(
        
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                'Terms of Service',
                style: textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF121C2A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome to AutoLearn. By using our application, you agree to these Terms of Service. Our services are designed to provide AI-assisted tutoring and educational content. You must not misuse our services or use them for any malicious purposes. AutoLearn reserves the right to suspend or terminate accounts that violate these terms. The content provided is for educational purposes only.',
                style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF787586)),
              ),
              const SizedBox(height: 32),
              Text(
                'Privacy Policy',
                style: textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF121C2A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your privacy is important to us. AutoLearn collects basic account information such as your email address to provide you with personalized learning experiences. We do not sell your personal data to third parties. We use secure encryption to protect your data, both in transit and at rest. If you wish to delete your account and associated data, please contact our support team.',
                style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF787586)),
              ),
              const SizedBox(height: 32),
              Text(
                'Frequently Asked Questions (FAQ)',
                style: textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF121C2A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                context,
                'How does the AI Tutor work?',
                'Our AI Tutor is powered by state-of-the-art language models tailored for educational contexts. It adapts to your learning pace and provides personalized feedback on your assignments and quizzes.',
              ),
              _buildFAQItem(
                context,
                'Is the content free?',
                'AutoLearn offers a mix of free and premium courses. You can browse the course catalog to see which ones require a subscription or one-time payment.',
              ),
              _buildFAQItem(
                context,
                'Can I use AutoLearn offline?',
                'Currently, an active internet connection is required to interact with the AI Tutor and stream video lessons.',
              ),
              _buildFAQItem(
                context,
                'How do I cancel my subscription?',
                'You can manage your billing and subscriptions directly from your Profile page or by contacting support at support@autolearn.com.',
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Last updated: June 2026',
                  style: textTheme.bodySmall?.copyWith(color: const Color(0xFFC8C4D7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4231C0).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              question,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF121C2A),
              ),
            ),
            iconColor: const Color(0xFF4231C0),
            collapsedIconColor: const Color(0xFF4231C0).withOpacity(0.5),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  answer,
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF787586)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
