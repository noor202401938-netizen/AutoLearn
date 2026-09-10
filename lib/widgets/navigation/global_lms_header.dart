import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../repository/auth_repository.dart';
import '../premium/streak_indicator.dart';

class GlobalLmsHeader extends StatefulWidget implements PreferredSizeWidget {
  final ValueChanged<String>? onSearch;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMyLearningTap;
  final VoidCallback? onExploreTap;
  final VoidCallback? onProfileTap;

  const GlobalLmsHeader({
    super.key,
    this.onSearch,
    this.onNotificationTap,
    this.onMyLearningTap,
    this.onExploreTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72.0);

  @override
  State<GlobalLmsHeader> createState() => _GlobalLmsHeaderState();
}

class _GlobalLmsHeaderState extends State<GlobalLmsHeader> {
  final TextEditingController _searchController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authRepository.getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF071514) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF15302C) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Brand Logo
          InkWell(
            onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF004741), Color(0xFF0D5E56)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF004741).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(CupertinoIcons.book_fill, color: Color(0xFFF0EDE4), size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AutoLearn',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC69234).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRO',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFC69234),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Premier Economics Hub',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isWide) ...[
            const SizedBox(width: 24),
            // Explore Mega-Menu Button
            OutlinedButton.icon(
              onPressed: widget.onExploreTap,
              icon: const Icon(CupertinoIcons.square_grid_2x2, size: 16),
              label: Text(
                'Explore',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741),
                side: BorderSide(
                  color: isDark ? const Color(0xFF22433F) : const Color(0xFFCDC6B5),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 16),

            // Omni-Search Bar
            Expanded(
              child: Container(
                height: 42,
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D2220) : const Color(0xFFF8F7F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: widget.onSearch,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF0A2421),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search economics, econometric tools, certifications...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      size: 16,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF152E2B) : const Color(0xFFE5E0D3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⌘K',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Streak Indicator
            const StreakIndicator(),
            const SizedBox(width: 16),

            // My Learning Navigation Link
            TextButton.icon(
              onPressed: widget.onMyLearningTap,
              icon: const Icon(CupertinoIcons.play_circle, size: 18),
              label: Text(
                'My Learning',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741),
                ),
              ),
            ),
          ] else ...[
            const Spacer(),
          ],

          const SizedBox(width: 8),

          // Notification Bell
          IconButton(
            onPressed: widget.onNotificationTap,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  CupertinoIcons.bell,
                  size: 20,
                  color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // User Profile Avatar
          InkWell(
            onTap: widget.onProfileTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF004741).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF004741),
                child: Text(
                  (_currentUser?['displayName'] != null &&
                          _currentUser!['displayName'].toString().isNotEmpty)
                      ? _currentUser!['displayName'].toString()[0].toUpperCase()
                      : 'U',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF0EDE4),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
