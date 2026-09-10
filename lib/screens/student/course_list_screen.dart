// lib/screens/student/course_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../business_logic/course_manager.dart';
import '../../business_logic/search_filter_engine.dart';
import '../../business_logic/enrollment_manager.dart';
import '../../business_logic/payment_manager.dart';
import '../../model/course_model.dart';
import 'payment_screen.dart';
import 'course_content_screen.dart';
import '../../widgets/premium/course_catalog_card.dart';
import '../../widgets/premium/skill_badge.dart';
import '../../widgets/navigation/global_lms_header.dart';

class CourseListScreen extends StatefulWidget {
  final bool embedded;
  const CourseListScreen({super.key, this.embedded = false});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final CourseManager _courseManager = CourseManager();
  final SearchFilterEngine _searchFilterEngine = SearchFilterEngine();
  final EnrollmentManager _enrollmentManager = EnrollmentManager();
  final TextEditingController _searchController = TextEditingController();

  List<CourseModel> _allCourses = [];
  List<CourseModel> _filteredCourses = [];
  List<String> _categories = [];
  Set<String> _enrolledCourseIds = {};

  String? _selectedCategory;
  String? _selectedLevel;
  String? _selectedSortBy;
  double? _minRating;
  double? _maxPrice;
  bool _isLoading = true;
  bool _hasError = false;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final courses = await _courseManager.getPublishedCourses();
      final enrolled = <String>{};
      for (final c in courses) {
        final isEn = await _enrollmentManager.isEnrolled(c.courseId);
        if (isEn) enrolled.add(c.courseId);
      }

      setState(() {
        _allCourses = courses;
        _filteredCourses = courses;
        _enrolledCourseIds = enrolled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _searchFilterEngine.getCategories();
    setState(() => _categories = categories);
  }

  Future<void> _filterCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _searchFilterEngine.searchCourses(
        query: _searchController.text.isEmpty ? null : _searchController.text,
        category: _selectedCategory,
        level: _selectedLevel,
        minRating: _minRating,
        maxPrice: _maxPrice?.toInt(),
        sortBy: _selectedSortBy,
      );
      setState(() {
        _filteredCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onCourseTap(CourseModel course) async {
    final isEnrolled = _enrolledCourseIds.contains(course.courseId);

    if (isEnrolled) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseContentScreen(
            courseId: course.courseId,
            title: course.title,
          ),
        ),
      );
      return;
    }

    // Course is paid and not enrolled -> Go to payment
    if (course.price > 0) {
      final amountCents = (course.price * 100).toInt();
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            courseId: course.courseId,
            courseTitle: course.title,
            amountCents: amountCents,
            currency: course.currency,
          ),
        ),
      );
      if (success != true) return;
    }

    final err = await _enrollmentManager.enrollInCourse(course.courseId);
    if (!mounted) return;
    if (err == null) {
      setState(() => _enrolledCourseIds.add(course.courseId));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseContentScreen(
            courseId: course.courseId,
            title: course.title,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = RefreshIndicator(
      onRefresh: _loadCourses,
      color: const Color(0xFF004741),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Featured Hero Banner
                if (!widget.embedded) _buildHeroBanner(isDark),
                if (!widget.embedded) const SizedBox(height: 28),

                // 2. Filter Toolbar (Search + Category Pills)
                _buildFilterToolbar(isDark),
                const SizedBox(height: 24),

                // 3. Results Header & Count
                Row(
                  children: [
                    Text(
                      'All Courses',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF0A2421),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004741).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_filteredCourses.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF004741),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Sort Dropdown
                    _buildSortDropdown(isDark),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Course Grid
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: Color(0xFF004741)),
                    ),
                  )
                else if (_hasError)
                  _buildErrorState()
                else if (_filteredCourses.isEmpty)
                  _buildEmptyState()
                else
                  _buildCourseGrid(),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF071514) : const Color(0xFFF8F7F4),
      appBar: GlobalLmsHeader(
        onSearch: (q) {
          _searchController.text = q;
          _filterCourses();
        },
      ),
      body: content,
    );
  }

  Widget _buildHeroBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003833), Color(0xFF004D47), Color(0xFF0D5E56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004741).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC69234),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FEATURED SPECIALIZATION',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(CupertinoIcons.sparkles, color: Color(0xFFC69234), size: 16),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Master Applied Economics & Market Dynamics',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: const Color(0xFFF0EDE4),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Interactive video curriculums, real-world case simulations, and verifiable certification recognized globally.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (_allCourses.isNotEmpty) _onCourseTap(_allCourses.first);
            },
            icon: const Icon(CupertinoIcons.play_fill, size: 16),
            label: Text(
              'Explore Specialization',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0EDE4),
              foregroundColor: const Color(0xFF004741),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D2220) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
            ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 350), _filterCourses);
            },
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by topic, instructor, or skill...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              prefixIcon: Icon(
                CupertinoIcons.search,
                size: 18,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterCourses();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Category & Level Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SkillBadge(
                label: 'All Topics',
                isSelected: _selectedCategory == null,
                onTap: () {
                  setState(() => _selectedCategory = null);
                  _filterCourses();
                },
              ),
              const SizedBox(width: 8),
              ..._categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SkillBadge(
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () {
                        setState(() => _selectedCategory = _selectedCategory == cat ? null : cat);
                        _filterCourses();
                      },
                    ),
                  )),
              Container(
                height: 20,
                width: 1,
                color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              ...['beginner', 'intermediate', 'advanced'].map((lvl) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: SkillBadge(
                      label: lvl.toUpperCase(),
                      isSelected: _selectedLevel == lvl,
                      onTap: () {
                        setState(() => _selectedLevel = _selectedLevel == lvl ? null : lvl);
                        _filterCourses();
                      },
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortDropdown(bool isDark) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        setState(() => _selectedSortBy = val);
        _filterCourses();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF0D2220) : Colors.white,
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'popular', child: Text('Most Popular')),
        const PopupMenuItem(value: 'rating', child: Text('Highest Rated')),
        const PopupMenuItem(value: 'newest', child: Text('Newest')),
        const PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D2220) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF22433F) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.sort_down, size: 14),
            const SizedBox(width: 6),
            Text(
              _selectedSortBy ?? 'Sort By',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 1100) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 700) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.84,
          ),
          itemCount: _filteredCourses.length,
          itemBuilder: (context, index) {
            final course = _filteredCourses[index];
            final isEnrolled = _enrolledCourseIds.contains(course.courseId);

            return CourseCatalogCard(
              course: course,
              isEnrolled: isEnrolled,
              onTap: () => _onCourseTap(course),
              onEnrollTap: () => _onCourseTap(course),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(CupertinoIcons.search, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No courses found matching your criteria',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try clearing filters or searching for different keywords.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCategory = null;
                  _selectedLevel = null;
                  _selectedSortBy = null;
                });
                _filterCourses();
              },
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Failed to load courses',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCourses,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
