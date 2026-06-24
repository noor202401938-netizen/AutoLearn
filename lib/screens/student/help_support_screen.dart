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
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Help & Support', 
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.help_outline,
                  size: 80,
                  color: const Color(0xFF4231C0).withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF121C2A),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Contact Support
                Container(
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
                  child: ListTile(
                    leading: const Icon(Icons.email, color: Color(0xFF4231C0)),
                    title: const Text('Contact Support', style: TextStyle(color: Color(0xFF121C2A))),
                    subtitle: const Text('Email us at support@autolearn.com', style: TextStyle(color: Color(0xFF787586))),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF4231C0)),
                    onTap: _launchEmail,
                  ),
                ),
                const SizedBox(height: 12),
                
                // FAQ
                Container(
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
                  child: ExpansionTile(
                    leading: const Icon(Icons.help, color: Color(0xFF4231C0)),
                    title: const Text('Frequently Asked Questions', style: TextStyle(color: Color(0xFF121C2A))),
                    iconColor: const Color(0xFF4231C0),
                    collapsedIconColor: const Color(0xFF4231C0).withOpacity(0.5),
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
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip, color: Color(0xFF4231C0)),
                    title: const Text('Privacy Policy', style: TextStyle(color: Color(0xFF121C2A))),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF4231C0)),
                    onTap: () {
                      _launchURL('https://autolearn.com/privacy');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                
                // Terms of Service
                Container(
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
                  child: ListTile(
                    leading: const Icon(Icons.description, color: Color(0xFF4231C0)),
                    title: const Text('Terms of Service', style: TextStyle(color: Color(0xFF121C2A))),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF4231C0)),
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
                      color: const Color(0xFFC8C4D7),
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
              color: Color(0xFF121C2A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF787586),
            ),
          ),
        ],
      ),
    );
  }
}

