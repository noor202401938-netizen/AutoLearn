import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repository/user_repository.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _selectedTab = 'All';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userRepository.getAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter(String tab) {
    setState(() {
      _selectedTab = tab;
      if (tab == 'All') {
        _filteredUsers = List.from(_allUsers);
      } else if (tab == 'Instructor') {
        _filteredUsers = _allUsers.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'instructor').toList();
      } else if (tab == 'Premium') {
        // Mock premium filtering, since we don't have a premium flag yet
        _filteredUsers = _allUsers.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'premium').toList();
      } else if (tab == 'Inactive') {
        // Mock inactive filtering
        _filteredUsers = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      Expanded(flex: isDesktop ? 1 : 0, child: _buildStatCard(context, 'Active Now', '${_allUsers.length}', Icons.pause, const Color(0xFF00724e), const [Color(0xFF4edea3), Color(0xFF00724e)], 0.75)),
                      if (isDesktop) const SizedBox(width: 16),
                      if (!isDesktop) const SizedBox(height: 16),
                      Expanded(flex: isDesktop ? 1 : 0, child: _buildStatCard(context, 'Retention', '94.2%', Icons.trending_up, colorScheme.primary, [colorScheme.primary, colorScheme.tertiary], 0.94)),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),

              // Search
              Container(
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.3) : const Color(0xFFeff4ff),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        _applyFilter(_selectedTab);
                      } else {
                        _filteredUsers = _allUsers
                            .where((u) => (u['email'] ?? '').toString().toLowerCase().contains(value.toLowerCase()) || (u['displayName'] ?? '').toString().toLowerCase().contains(value.toLowerCase()))
                            .toList();
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    hintStyle: GoogleFonts.inter(color: colorScheme.outline),
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
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
                    _buildTab(context, 'All'),
                    _buildTab(context, 'Premium'),
                    _buildTab(context, 'Instructor'),
                    _buildTab(context, 'Inactive'),
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
                      color: colorScheme.outline,
                      letterSpacing: 0.05,
                    ),
                  ),
                  Text(
                    'Sort: Recent',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_filteredUsers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('No users found', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant)),
                  ),
                )
              else
                ..._filteredUsers.map((user) {
                  final role = (user['role'] ?? 'Free').toString();
                  final isInstructor = role.toLowerCase() == 'instructor';
                  final isPremium = role.toLowerCase() == 'premium';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildMemberItem(
                      context: context,
                      name: user['displayName'] ?? user['email'] ?? 'Unknown',
                      role: role.isEmpty ? 'Free' : role,
                      roleColor: isInstructor ? colorScheme.tertiary : (isPremium ? colorScheme.primary : colorScheme.onSurfaceVariant),
                      roleBg: isInstructor ? colorScheme.tertiary.withOpacity(0.1) : (isPremium ? colorScheme.primary.withOpacity(0.1) : (isDark ? colorScheme.surfaceContainer : const Color(0xFFd9e3f6))),
                      subtitle: user['email'] ?? 'No email',
                    ),
                  );
                }).toList(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color iconColor, List<Color> gradientColors, double progress) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
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
                  color: colorScheme.outline,
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
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHigh : Colors.grey[100],
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

  Widget _buildTab(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = _selectedTab == text;
    return GestureDetector(
      onTap: () => _applyFilter(text),
      child: Padding(
        padding: const EdgeInsets.only(right: 24.0),
        child: Column(
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.tertiary]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem({
    required BuildContext context,
    required String name,
    required String role,
    required Color roleColor,
    required Color roleBg,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainer : const Color(0xFFd9e3f6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person, color: colorScheme.onSurfaceVariant),
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
                        color: colorScheme.onSurface,
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
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: colorScheme.outline),
            onPressed: () {},
          )
        ],
      ),
    );
  }
}
