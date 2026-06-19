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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
              Theme.of(context).colorScheme.background,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.help_outline,
                  size: 80,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Contact Support
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.email, color: Theme.of(context).colorScheme.secondary),
                    title: const Text('Contact Support', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Email us at support@autolearn.com', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
                    onTap: _launchEmail,
                  ),
                ),
                const SizedBox(height: 12),
                
                // FAQ
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ExpansionTile(
                    leading: Icon(Icons.help, color: Theme.of(context).colorScheme.secondary),
                    title: const Text('Frequently Asked Questions', style: TextStyle(color: Colors.white)),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white.withOpacity(0.5),
                    children: [
                      _buildFAQItem(
                        context,
                        'How do I enroll in a course?',
                        'Browse courses from the Courses tab, select a course, and click the Enroll button. For paid courses, you\'ll need to complete payment first.',
                      ),
                      _buildFAQItem(
                        context,
                        'Can I access courses offline?',
                        'Currently, courses require an internet connection. We\'re working on offline support for future updates.',
                      ),
                      _buildFAQItem(
                        context,
                        'How do I reset my password?',
                        'On the login screen, click "Forgot Password?" and enter your email address. You\'ll receive a password reset link.',
                      ),
                      _buildFAQItem(
                        context,
                        'How do I change my profile information?',
                        'Go to Profile > Edit Profile to update your name, phone, grade, and interests.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Privacy Policy
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.privacy_tip, color: Theme.of(context).colorScheme.secondary),
                    title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
                    trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
                    onTap: () {
                      _launchURL('https://autolearn.com/privacy');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                
                // Terms of Service
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.description, color: Theme.of(context).colorScheme.secondary),
                    title: const Text('Terms of Service', style: TextStyle(color: Colors.white)),
                    trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
                    onTap: () {
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
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

