import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 600;
                  return Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    children: [
                      Expanded(flex: isDesktop ? 1 : 0, child: _buildStatCard('Active Now', '1,284', Icons.pause, const Color(0xFF00724e), const [Color(0xFF4edea3), Color(0xFF00724e)], 0.75)),
                      if (isDesktop) const SizedBox(width: 16),
                      if (!isDesktop) const SizedBox(height: 16),
                      Expanded(flex: isDesktop ? 1 : 0, child: _buildStatCard('Retention', '94.2%', Icons.trending_up, const Color(0xFF4231c0), const [Color(0xFF4231c0), Color(0xFF6b38d4)], 0.94)),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),

              // Search
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFeff4ff),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFFc8c4d7)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF787586)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab('All', true),
                    _buildTab('Premium', false),
                    _buildTab('Instructor', false),
                    _buildTab('Inactive', false),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Member List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Platform Members',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF787586),
                      letterSpacing: 0.05,
                    ),
                  ),
                  Text(
                    'Sort: Recent',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4231c0),
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Member List Items
              _buildMemberItem(
                name: 'Elena Rodriguez',
                role: 'Premium',
                roleColor: const Color(0xFF4231c0),
                roleBg: const Color(0xFF4231c0).withOpacity(0.1),
                subtitle: 'Active 2m ago • Python Mastery',
              ),
              const SizedBox(height: 12),
              _buildMemberItem(
                name: 'Marcus Thorne',
                role: 'Instructor',
                roleColor: const Color(0xFF6b38d4),
                roleBg: const Color(0xFF6b38d4).withOpacity(0.1),
                subtitle: 'Active 15m ago • UI Design Pro',
              ),
              const SizedBox(height: 12),
              _buildMemberItem(
                name: 'Liam Chen',
                role: 'Free',
                roleColor: const Color(0xFF474554),
                roleBg: const Color(0xFFd9e3f6),
                subtitle: 'Active 1h ago • Data Structures',
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: 0.6,
                child: _buildMemberItem(
                  name: 'Sarah Jenkins',
                  role: 'Inactive',
                  roleColor: const Color(0xFFba1a1a),
                  roleBg: const Color(0xFFffdad6).withOpacity(0.5),
                  subtitle: 'Last seen 2w ago • DevOps Basics',
                ),
              ),
              const SizedBox(height: 12),
              _buildMemberItem(
                name: 'David Okoro',
                role: 'Premium',
                roleColor: const Color(0xFF4231c0),
                roleBg: const Color(0xFF4231c0).withOpacity(0.1),
                subtitle: 'Active Now • Full-Stack Dev',
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, List<Color> gradientColors, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF787586),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.geist(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121c2a),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(colors: gradientColors),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 24.0),
      child: Column(
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF4231c0) : const Color(0xFF474554),
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4231c0), Color(0xFF6b38d4)]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
          ]
        ],
      ),
    );
  }

  Widget _buildMemberItem({
    required String name,
    required String role,
    required Color roleColor,
    required Color roleBg,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFd9e3f6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: Color(0xFF474554)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF121c2a),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF474554),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF787586)),
            onPressed: () {},
          )
        ],
      ),
    );
  }
}
