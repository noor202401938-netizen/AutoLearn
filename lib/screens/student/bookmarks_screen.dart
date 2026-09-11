import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/course_model.dart';
import '../../repository/course_repository.dart';
import '../../widgets/premium/premium_card.dart';
import 'course_content_screen.dart';

enum BookmarkType { all, courses, lessons, notes }

class BookmarkItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String courseId;
  final CourseModel? course;
  final String durationText;
  final DateTime savedAt;
  final BookmarkType type;

  const BookmarkItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.courseId,
    this.course,
    required this.durationText,
    required this.savedAt,
    required this.type,
  });
}

class BookmarksScreen extends StatefulWidget {
  final bool embedded;

  const BookmarksScreen({super.key, this.embedded = false});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final CourseRepository _courseRepository = CourseRepository();
  BookmarkType _activeTab = BookmarkType.all;
  List<CourseModel> _allCourses = [];
  bool _isLoading = true;

  List<BookmarkItem> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _courseRepository.getAllCourses();
      _allCourses = courses;

      // Seed bookmarks from courses
      _bookmarks = [
        if (courses.isNotEmpty)
          BookmarkItem(
            id: 'b-1',
            title: courses[0].title,
            subtitle: 'Course by ${courses[0].instructor}',
            category: courses[0].category,
            courseId: courses[0].courseId,
            course: courses[0],
            durationText: '${courses[0].duration} mins',
            savedAt: DateTime.now().subtract(const Duration(days: 2)),
            type: BookmarkType.courses,
          ),
        if (courses.length > 1)
          BookmarkItem(
            id: 'b-2',
            title: 'Price Elasticity & Revenue Maximization',
            subtitle: 'Lesson 3 in ${courses[1].title}',
            category: courses[1].category,
            courseId: courses[1].courseId,
            course: courses[1],
            durationText: '14 mins',
            savedAt: DateTime.now().subtract(const Duration(days: 4)),
            type: BookmarkType.lessons,
          ),
        BookmarkItem(
          id: 'b-3',
          title: 'Summary Formula Sheet: IS-LM & AD-AS Shocks',
          subtitle: 'Resource Note attachment',
          category: 'Macroeconomics',
          courseId: courses.isNotEmpty ? courses[0].courseId : 'c-1',
          course: courses.isNotEmpty ? courses[0] : null,
          durationText: 'PDF (2.4 MB)',
          savedAt: DateTime.now().subtract(const Duration(days: 6)),
          type: BookmarkType.notes,
        ),
      ];

      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<BookmarkItem> get _filteredBookmarks {
    if (_activeTab == BookmarkType.all) return _bookmarks;
    return _bookmarks.where((b) => b.type == _activeTab).toList();
  }

  void _removeBookmark(String id) {
    setState(() {
      _bookmarks.removeWhere((b) => b.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bookmark removed'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFC69234),
          onPressed: _loadData,
        ),
      ),
    );
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved Library & Bookmarks',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quick access to your saved courses, video timestamps, and downloadable materials.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : const Color(0xFF4A5568),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004741).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_bookmarks.length} Saved Items',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF004741),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filter Tabs
              _buildFilterTabs(isDark),
              const SizedBox(height: 24),

              // Bookmarks List
              if (_filteredBookmarks.isEmpty)
                _buildEmptyState(isDark)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredBookmarks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = _filteredBookmarks[index];
                    return _buildBookmarkCard(context, item, isDark);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2220) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton('All Items', BookmarkType.all, isDark),
          _buildTabButton('Courses', BookmarkType.courses, isDark),
          _buildTabButton('Lessons', BookmarkType.lessons, isDark),
          _buildTabButton('Notes & Files', BookmarkType.notes, isDark),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, BookmarkType type, bool isDark) {
    final isSelected = _activeTab == type;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF004741) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFFF0EDE4)
                : (isDark ? Colors.white70 : const Color(0xFF4A5568)),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkCard(BuildContext context, BookmarkItem item, bool isDark) {
    IconData icon;
    Color iconColor;

    switch (item.type) {
      case BookmarkType.courses:
        icon = CupertinoIcons.book_fill;
        iconColor = const Color(0xFF004741);
        break;
      case BookmarkType.lessons:
        icon = CupertinoIcons.play_circle_fill;
        iconColor = const Color(0xFFC69234);
        break;
      case BookmarkType.notes:
        icon = CupertinoIcons.doc_text_fill;
        iconColor = const Color(0xFF0D5E56);
        break;
      default:
        icon = CupertinoIcons.bookmark_fill;
        iconColor = const Color(0xFF004741);
    }

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF0EDE4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF004741),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.durationText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () => _removeBookmark(item.id),
            icon: const Icon(CupertinoIcons.bookmark_fill, size: 20),
            color: const Color(0xFFC69234),
            tooltip: 'Remove bookmark',
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              if (item.course != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseContentScreen(
                      courseId: item.course!.courseId,
                      title: item.course!.title,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(CupertinoIcons.play_fill, size: 14),
            label: Text(
              'Resume',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004741),
              foregroundColor: const Color(0xFFF0EDE4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(CupertinoIcons.bookmark, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Saved Bookmarks Yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookmark lessons, problem sets, and key resources to review them anytime.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
