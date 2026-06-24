import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/user_stats_model.dart';
import '../../business_logic/auth_manager.dart';
import '../../screens/student/edit_profile_screen.dart';
import '../../screens/student/change_password_screen.dart';
import '../../screens/notifications_panel.dart';
import '../../screens/student/certificates_list_screen.dart';

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback onProfileUpdated;

  const ProfileTab({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthManager _authManager = AuthManager();

  // Variables to hold the models
  late UserStatsModel _userStats;
  late List<AchievementModel> _achievements;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    // In a real app, these would be fetched from a backend repository.
    // For now, we populate the variables with data representing the user.
    _userStats = UserStatsModel(
      points: 12450,
      certificates: 3,
      globalRank: 'Top 5%',
      level: 12,
      pointsToNextLevel: 2550,
      streakDays: 7,
    );

    _achievements = [
      AchievementModel(
        title: '7 Day Streak',
        description: 'Consistency Master',
        icon: 'local_fire_department',
        colorTheme: 'tertiary',
      ),
      AchievementModel(
        title: 'Fast Learner',
        description: 'Quiz Ace',
        icon: 'psychology',
        colorTheme: 'secondary',
      ),
      AchievementModel(
        title: 'Top Scorer',
        description: 'Course Leader',
        icon: 'military_tech',
        colorTheme: 'primary',
      ),
    ];
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'psychology':
        return Icons.psychology;
      case 'military_tech':
        return Icons.military_tech;
      default:
        return Icons.star;
    }
  }

  Color _getThemeColor(String theme, ColorScheme colorScheme) {
    switch (theme) {
      case 'tertiary':
        return const Color(0xFF00573a);
      case 'secondary':
        return const Color(0xFF6b38d4);
      case 'primary':
        return const Color(0xFF4231c0);
      default:
        return colorScheme.primary;
    }
  }

  Color _getThemeBgColor(String theme) {
    switch (theme) {
      case 'tertiary':
        return const Color(0xFF6ffbbe); // tertiary-fixed
      case 'secondary':
        return const Color(0xFFe9ddff); // secondary-fixed
      case 'primary':
        return const Color(0xFFe3dfff); // primary-fixed
      default:
        return const Color(0xFFe3dfff);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = widget.userProfile?['displayName'] ?? 'Student';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _buildProfileHeader(displayName),
              const SizedBox(height: 64),
              _buildStatsGrid(),
              const SizedBox(height: 64),
              _buildAchievementsSection(),
              const SizedBox(height: 64),
              _buildSettingsList(context),
              const SizedBox(height: 40),
              _buildSignOutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String displayName) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFe6eeff), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(64),
                child: Container(
                  color: const Color(0xFFe3dfff),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4231c0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5b4ed9), Color(0xFF6b38d4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Color(0xFFe2deff), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Premium',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05,
                        color: const Color(0xFFe2deff),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          displayName,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: const Color(0xFF121c2a),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Premium Learner • Level ${_userStats.level}',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF474554),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        // Points Earned full width card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFffffff),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFc8c4d7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5b4ed9).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'POINTS EARNED',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.05,
                      color: const Color(0xFF474554),
                    ),
                  ),
                  const Icon(Icons.stars, color: Color(0xFF6b38d4)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${_userStats.points}',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4231c0),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFd9e3f6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * 0.75, // 75% hardcoded for layout, can be calculated
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4edea3), Color(0xFF00724e)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_userStats.pointsToNextLevel} pts until next level',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF474554),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Two columns for Certificates and Global Rank
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFffffff),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFc8c4d7)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5b4ed9).withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.school, color: Color(0xFF00573a)),
                    const SizedBox(height: 8),
                    Text(
                      '${_userStats.certificates}',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Certificates',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF474554),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFffffff),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFc8c4d7)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5b4ed9).withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.leaderboard, color: Color(0xFFba1a1a)),
                    const SizedBox(height: 8),
                    Text(
                      _userStats.globalRank,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Global Rank',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF474554),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Achievements',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4231c0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _achievements.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final achievement = _achievements[index];
              return Container(
                width: 160,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFffffff),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFc8c4d7)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5b4ed9).withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _getThemeBgColor(achievement.colorTheme),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconData(achievement.icon),
                        color: _getThemeColor(achievement.colorTheme, Theme.of(context).colorScheme),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      achievement.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF121c2a),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF474554),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 24),
          child: Text(
            'Settings',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFffffff),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFc8c4d7)),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.security,
                title: 'Security',
                subtitle: 'Password, 2FA, Devices',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
                showBorder: true,
              ),
              _buildSettingsItem(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Email, Push, Activity',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPanel(),
                    ),
                  );
                },
                showBorder: true,
              ),
              _buildSettingsItem(
                icon: Icons.payments,
                title: 'Billing',
                subtitle: 'Subscription, Invoices',
                onTap: () {
                  // Can be wired up later
                },
                showBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showBorder,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: showBorder ? const Border(bottom: BorderSide(color: Color(0xFFc8c4d7))) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFd9e3f6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF4231c0)),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF121c2a),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF474554),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF787586)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        await _authManager.logout();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFba1a1a),
        side: BorderSide(color: const Color(0xFFba1a1a).withOpacity(0.2)),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout),
          const SizedBox(width: 8),
          Text(
            'Sign Out',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
