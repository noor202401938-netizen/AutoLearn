import 'package:flutter/material.dart';
import '../../business_logic/auth_manager.dart';
import '../../screens/notifications_panel.dart';
import '../../screens/student/about_screen.dart';
import '../../screens/student/change_password_screen.dart';
import '../../screens/student/edit_profile_screen.dart';
import '../../screens/student/help_support_screen.dart';
import '../../screens/student/policies_screen.dart';
import '../../screens/theme_accessibility_screen.dart';
import '../notebook/notebook.dart';

/// Profile page: who you are, and the settings pages. Numbers live on the
/// Today page, which reads them from the server — nothing here is made up.
class ProfileTab extends StatelessWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback onProfileUpdated;

  const ProfileTab({super.key, required this.userProfile, required this.onProfileUpdated});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final p = userProfile ?? const {};
    final email = p['email'] as String? ?? '';
    final name = (p['displayName'] as String?)?.trim().isNotEmpty == true
        ? p['displayName'] as String
        : email.split('@').first;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final details = [
      if ((p['grade'] as String?)?.isNotEmpty == true) p['grade'] as String,
      if ((p['interest'] as String?)?.isNotEmpty == true) 'interested in ${p['interest']}',
    ];

    Future<void> open(Widget page) async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      onProfileUpdated();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      children: [
        Row(children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nb.sheet,
              border: Border.all(color: theme.colorScheme.onSurface, width: 1.5),
            ),
            child: Text(initial, style: nb.hand(size: 40, color: theme.colorScheme.onSurface)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isEmpty ? 'Your profile' : name, style: theme.textTheme.headlineMedium),
              if (email.isNotEmpty) Text(email, style: theme.textTheme.bodyMedium),
              if (details.isNotEmpty) MarginNote(details.join(' · '), size: 18),
            ]),
          ),
        ]),
        const SizedBox(height: 32),
        const NoteHeading('Account'),
        const SizedBox(height: 12),
        NoteCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _item(context, Icons.edit_outlined, 'Edit profile', 'Name, phone, level, interests',
                () => open(const EditProfileScreen())),
            _item(context, Icons.lock_outline, 'Password', 'Change your password',
                () => open(const ChangePasswordScreen())),
            _item(context, Icons.notifications_none, 'Notifications', 'Announcements and course updates',
                () => open(const NotificationsPanel()), last: true),
          ]),
        ),
        const SizedBox(height: 28),
        const NoteHeading('Preferences & help'),
        const SizedBox(height: 12),
        NoteCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _item(context, Icons.text_fields, 'Theme & accessibility', 'Paper or blackboard, text size, motion',
                () => open(const ThemeAccessibilityScreen())),
            _item(context, Icons.help_outline, 'Help & support', 'FAQs and contact',
                () => open(const HelpSupportScreen())),
            _item(context, Icons.policy_outlined, 'Policies', 'Terms and privacy',
                () => open(const PoliciesScreen())),
            _item(context, Icons.info_outline, 'About AutoLearn', 'Version and credits',
                () => open(const AboutScreen()), last: true),
          ]),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () async {
            await AuthManager().logout();
            if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
            minimumSize: const Size.fromHeight(52),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap,
      {bool last = false}) {
    final theme = Theme.of(context);
    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: theme.colorScheme.onSurface),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
      if (!last) const Divider(indent: 20, endIndent: 20),
    ]);
  }
}
