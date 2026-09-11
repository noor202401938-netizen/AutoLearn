import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/premium/premium_card.dart';

class ForumPost {
  final String id;
  final String authorName;
  final String authorRole;
  final String authorInitials;
  final String category;
  final String title;
  final String content;
  final String timeAgo;
  int upvotes;
  bool isUpvoted;
  final int replyCount;
  final bool hasInstructorReply;
  final List<String> tags;

  ForumPost({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.authorInitials,
    required this.category,
    required this.title,
    required this.content,
    required this.timeAgo,
    required this.upvotes,
    this.isUpvoted = false,
    required this.replyCount,
    this.hasInstructorReply = false,
    required this.tags,
  });
}

class CommunityForumScreen extends StatefulWidget {
  final bool embedded;

  const CommunityForumScreen({super.key, this.embedded = false});

  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen> {
  String _selectedCategory = 'All Topics';
  String _searchQuery = '';

  final List<ForumPost> _posts = [
    ForumPost(
      id: 'p-1',
      authorName: 'Alex Morgan',
      authorRole: 'Student',
      authorInitials: 'AM',
      category: 'Microeconomics',
      title: 'How does price discrimination impact deadweight loss in second-degree vs third-degree?',
      content:
          'In module 3 we looked at monopoly surplus extraction. Is deadweight loss strictly minimized under first-degree perfect discrimination, and what are the empirical challenges to achieving that in real digital markets?',
      timeAgo: '2 hours ago',
      upvotes: 24,
      isUpvoted: true,
      replyCount: 7,
      hasInstructorReply: true,
      tags: ['Price Discrimination', 'Monopoly', 'Welfare'],
    ),
    ForumPost(
      id: 'p-2',
      authorName: 'Dr. Evelyn Vance',
      authorRole: 'Instructor',
      authorInitials: 'EV',
      category: 'Macro Policy',
      title: 'Weekly Discussion: Evaluating the neutral interest rate (r*) in post-inflation economies',
      content:
          'Given recent central bank policy reviews, share your thoughts on whether demographic shifts and fiscal deficits are permanently shifting r* upwards. Post your arguments using the IS-MP model framework.',
      timeAgo: '5 hours ago',
      upvotes: 48,
      replyCount: 19,
      hasInstructorReply: true,
      tags: ['Interest Rates', 'Central Banking', 'IS-MP Model'],
    ),
    ForumPost(
      id: 'p-3',
      authorName: 'Tariq Hassan',
      authorRole: 'Student',
      authorInitials: 'TH',
      category: 'Econometrics',
      title: 'Instrumental variable relevance vs exogeneity testing in Python statsmodels',
      content:
          'When running 2SLS, what diagnostics do you guys recommend for testing weak instruments beyond the standard First-Stage F-statistic > 10 threshold? Is the Montiel-Pflueger effective F test available in Python?',
      timeAgo: '1 day ago',
      upvotes: 15,
      replyCount: 4,
      hasInstructorReply: false,
      tags: ['Econometrics', '2SLS', 'Instruments', 'Python'],
    ),
    ForumPost(
      id: 'p-4',
      authorName: 'Sarah Jenkins',
      authorRole: 'Student',
      authorInitials: 'SJ',
      category: 'Behavioral',
      title: 'Default options in pension plans: Real-world nudge success stories',
      content:
          'Following Thaler and Benartzi’s Save More Tomorrow model, has anyone analyzed the long-term saving rates of automatic enrollment in Asian economies?',
      timeAgo: '2 days ago',
      upvotes: 31,
      replyCount: 11,
      hasInstructorReply: true,
      tags: ['Nudge', 'Pensions', 'Behavioral'],
    ),
  ];

  List<ForumPost> get _filteredPosts {
    return _posts.where((p) {
      final matchCat = _selectedCategory == 'All Topics' || p.category == _selectedCategory;
      final matchQuery = _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchCat && matchQuery;
    }).toList();
  }

  void _toggleUpvote(ForumPost post) {
    setState(() {
      if (post.isUpvoted) {
        post.upvotes--;
        post.isUpvoted = false;
      } else {
        post.upvotes++;
        post.isUpvoted = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community & Discussion Forums',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect with fellow students, discuss case studies, and get answers from instructors.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : const Color(0xFF4A5568),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showNewThreadDialog(context, isDark),
                    icon: const Icon(CupertinoIcons.plus_bubble_fill, size: 16),
                    label: Text(
                      'New Discussion',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004741),
                      foregroundColor: const Color(0xFFF0EDE4),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filter Category Chips
              _buildCategoryPills(isDark),
              const SizedBox(height: 20),

              // Post List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredPosts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final post = _filteredPosts[index];
                  return _buildPostCard(context, post, isDark);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPills(bool isDark) {
    final categories = ['All Topics', 'Microeconomics', 'Macro Policy', 'Econometrics', 'Behavioral'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(
                cat,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFFF0EDE4)
                      : (isDark ? Colors.white70 : const Color(0xFF2D3748)),
                ),
              ),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _selectedCategory = cat);
              },
              backgroundColor: isDark ? const Color(0xFF0D2220) : Colors.white,
              selectedColor: const Color(0xFF004741),
              checkmarkColor: const Color(0xFFC69234),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF004741)
                      : (isDark ? const Color(0xFF15302C) : const Color(0xFFE2E8F0)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, ForumPost post, bool isDark) {
    return PremiumCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: post.authorRole == 'Instructor'
                    ? const Color(0xFFC69234)
                    : const Color(0xFF004741),
                child: Text(
                  post.authorInitials,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.authorName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (post.authorRole == 'Instructor') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC69234),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'INSTRUCTOR',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${post.category} • ${post.timeAgo}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF718096),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (post.hasInstructorReply)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004741).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF004741)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.checkmark_seal_fill, size: 12, color: Color(0xFF004741)),
                      const SizedBox(width: 4),
                      Text(
                        'Instructor Verified',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF004741),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            post.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),

          // Body
          Text(
            post.content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: post.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D2220) : const Color(0xFFF0EDE4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$tag',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004741),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              InkWell(
                onTap: () => _toggleUpvote(post),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: post.isUpvoted
                        ? const Color(0xFFC69234).withValues(alpha: 0.15)
                        : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        post.isUpvoted ? CupertinoIcons.hand_thumbsup_fill : CupertinoIcons.hand_thumbsup,
                        size: 14,
                        color: post.isUpvoted ? const Color(0xFFC69234) : (isDark ? Colors.white70 : const Color(0xFF4A5568)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.upvotes} Upvotes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: post.isUpvoted ? const Color(0xFFC69234) : (isDark ? Colors.white70 : const Color(0xFF4A5568)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Row(
                children: [
                  Icon(CupertinoIcons.chat_bubble_2, size: 16, color: isDark ? Colors.white60 : const Color(0xFF718096)),
                  const SizedBox(width: 6),
                  Text(
                    '${post.replyCount} Replies',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF718096),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  _showReplyDialog(context, post, isDark);
                },
                icon: const Icon(CupertinoIcons.reply, size: 14),
                label: Text(
                  'Join Discussion',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF004741),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNewThreadDialog(BuildContext context, bool isDark) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF071514) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Start a Discussion Thread',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Question or Topic Title',
                    hintText: 'e.g. How does quantitative easing affect the yield curve?',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bodyController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Details & Context',
                    hintText: 'Provide background, formulas, or specific course references...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _posts.insert(
                      0,
                      ForumPost(
                        id: 'p-${DateTime.now().millisecondsSinceEpoch}',
                        authorName: 'You',
                        authorRole: 'Student',
                        authorInitials: 'ME',
                        category: _selectedCategory == 'All Topics' ? 'General' : _selectedCategory,
                        title: titleController.text,
                        content: bodyController.text,
                        timeAgo: 'Just now',
                        upvotes: 1,
                        isUpvoted: true,
                        replyCount: 0,
                        tags: ['Discussion'],
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004741),
                foregroundColor: const Color(0xFFF0EDE4),
              ),
              child: const Text('Post Thread'),
            ),
          ],
        );
      },
    );
  }

  void _showReplyDialog(BuildContext context, ForumPost post, bool isDark) {
    final replyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF071514) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Discussion Thread (${post.replyCount} responses)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF004741),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D2220) : const Color(0xFFF8F7F4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Dr. Evelyn Vance (Instructor)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFC69234),
                                ),
                              ),
                              const Spacer(),
                              Text('1 hr ago', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Great question! Notice how first-degree discrimination converts the entire consumer surplus into producer surplus, eliminating deadweight loss in theory, but requires perfect information which rarely holds in physical markets.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyController,
                      decoration: InputDecoration(
                        hintText: 'Add to the discussion...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {
                      if (replyController.text.isNotEmpty) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Response posted!')),
                        );
                      }
                    },
                    icon: const Icon(CupertinoIcons.paperplane_fill),
                    color: const Color(0xFF004741),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
