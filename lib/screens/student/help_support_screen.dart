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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Help & Support',
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.help_outline,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'How can we help you?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: Icon(Icons.email, color: theme.colorScheme.primary),
                  title: Text('Contact Support',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.onSurface)),
                  subtitle: Text('Email us at support@autolearn.com',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right,
                      color: theme.colorScheme.primary),
                  onTap: _launchEmail,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: ExpansionTile(
                  leading: Icon(Icons.help, color: theme.colorScheme.primary),
                  title: Text('Frequently Asked Questions',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.onSurface)),
                  iconColor: theme.colorScheme.primary,
                  collapsedIconColor: theme.colorScheme.primary,
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
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading:
                      Icon(Icons.privacy_tip, color: theme.colorScheme.primary),
                  title: Text('Privacy Policy',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.onSurface)),
                  trailing: Icon(Icons.chevron_right,
                      color: theme.colorScheme.primary),
                  onTap: () {
                    _launchURL('https://autolearn.com/privacy');
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading:
                      Icon(Icons.description, color: theme.colorScheme.primary),
                  title: Text('Terms of Service',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.onSurface)),
                  trailing: Icon(Icons.chevron_right,
                      color: theme.colorScheme.primary),
                  onTap: () {
                    _launchURL('https://autolearn.com/terms');
                  },
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'App Version 1.0.0',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
