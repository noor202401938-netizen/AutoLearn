// lib/screens/student/help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@autolearn.com',
      query: 'subject=Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // Fallback: show email address
      // In a real app, you might want to copy to clipboard
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.help_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // Contact Support
            Card(
              child: ListTile(
                leading: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
                title: const Text('Contact Support'),
                subtitle: const Text('Email us at support@autolearn.com'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _launchEmail,
              ),
            ),
            const SizedBox(height: 12),
            
            // FAQ
            Card(
              child: ExpansionTile(
                leading: Icon(Icons.help, color: Theme.of(context).colorScheme.primary),
                title: const Text('Frequently Asked Questions'),
                children: [
                  _buildFAQItem(
                    'How do I enroll in a course?',
                    'Browse courses from the Courses tab, select a course, and click the Enroll button. For paid courses, you\'ll need to complete payment first.',
                  ),
                  _buildFAQItem(
                    'Can I access courses offline?',
                    'Currently, courses require an internet connection. We\'re working on offline support for future updates.',
                  ),
                  _buildFAQItem(
                    'How do I reset my password?',
                    'On the login screen, click "Forgot Password?" and enter your email address. You\'ll receive a password reset link.',
                  ),
                  _buildFAQItem(
                    'How do I change my profile information?',
                    'Go to Profile > Edit Profile to update your name, phone, grade, and interests.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Privacy Policy
            Card(
              child: ListTile(
                leading: Icon(Icons.privacy_tip, color: Theme.of(context).colorScheme.primary),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to privacy policy or open URL
                  _launchURL('https://autolearn.com/privacy');
                },
              ),
            ),
            const SizedBox(height: 12),
            
            // Terms of Service
            Card(
              child: ListTile(
                leading: Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to terms or open URL
                  _launchURL('https://autolearn.com/terms');
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // App Version
            Center(
              child: Text(
                'App Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

