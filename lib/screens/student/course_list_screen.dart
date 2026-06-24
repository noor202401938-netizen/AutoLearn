// lib/screens/student/course_list_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../business_logic/course_manager.dart';
import '../../business_logic/search_filter_engine.dart';
import '../../model/course_model.dart';
import '../../business_logic/enrollment_manager.dart';
import '../../business_logic/payment_manager.dart';
import '../../backend/api_client.dart';
import 'payment_screen.dart';
import 'course_content_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

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

  String? _selectedCategory;
  String? _selectedLevel;
  String? _selectedSortBy;
  double? _minRating;
  double? _maxPrice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final courses = await _courseManager.getPublishedCourses();
    setState(() {
      _allCourses = courses;
      _filteredCourses = courses;
      _isLoading = false;
    });
  }

  Future<void> _loadCategories() async {
    final categories = await _searchFilterEngine.getCategories();
    setState(() {
      _categories = categories;
    });
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedLevel = null;
      _selectedSortBy = null;
      _minRating = null;
      _maxPrice = null;
    });
    _filterCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9ff),
      appBar: AppBar(
        title: Text('Browse Courses', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF121c2a))),
        backgroundColor: const Color(0xFFf8f9ff),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF121c2a)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: RefreshIndicator(
          onRefresh: _loadCourses,
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFeff4ff), // surface-container-low
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(color: const Color(0xFF121c2a)),
                    decoration: InputDecoration(
                      hintText: 'Search courses...',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFFc8c4d7)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF787586)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Color(0xFF474554)),
                              onPressed: () {
                                _searchController.clear();
                                _filterCourses();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onChanged: (value) => _filterCourses(),
                  ),
                ),
              ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Filter
                  if (_categories.isNotEmpty) ...[
                      ChoiceChip(
                        label: Text(_selectedCategory ?? 'All Categories', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        selected: _selectedCategory != null,
                        onSelected: (selected) {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Category',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF121c2a),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ChoiceChip(
                                        label: const Text('All'),
                                        selected: _selectedCategory == null,
                                        onSelected: (selected) {
                                          setState(() => _selectedCategory = null);
                                          _filterCourses();
                                          Navigator.pop(context);
                                        },
                                      ),
                                      ..._categories.map((category) {
                                        return ChoiceChip(
                                          label: Text(category),
                                          selected: _selectedCategory == category,
                                          onSelected: (selected) {
                                            setState(() => _selectedCategory = category);
                                            _filterCourses();
                                            Navigator.pop(context);
                                          },
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        selectedColor: const Color(0xFFe9ddff),
                        backgroundColor: const Color(0xFFeff4ff),
                        side: BorderSide(color: _selectedCategory != null ? const Color(0xFF5516be) : const Color(0xFFc8c4d7)),
                        labelStyle: TextStyle(
                          color: _selectedCategory != null ? const Color(0xFF5516be) : const Color(0xFF474554),
                        ),
                      ),
                      const SizedBox(width: 8),
                  ],

                  // Level Filter
                  ChoiceChip(
                    label: Text(_selectedLevel ?? 'All Levels', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    selected: _selectedLevel != null,
                    onSelected: (selected) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Level',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF121c2a),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('All'),
                                    selected: _selectedLevel == null,
                                    onSelected: (selected) {
                                      setState(() => _selectedLevel = null);
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Beginner'),
                                    selected: _selectedLevel == 'beginner',
                                    onSelected: (selected) {
                                      setState(() => _selectedLevel = 'beginner');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Intermediate'),
                                    selected: _selectedLevel == 'intermediate',
                                    onSelected: (selected) {
                                      setState(() => _selectedLevel = 'intermediate');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Advanced'),
                                    selected: _selectedLevel == 'advanced',
                                    onSelected: (selected) {
                                      setState(() => _selectedLevel = 'advanced');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    selectedColor: const Color(0xFFe9ddff),
                    backgroundColor: const Color(0xFFeff4ff),
                    side: BorderSide(color: _selectedLevel != null ? const Color(0xFF5516be) : const Color(0xFFc8c4d7)),
                    labelStyle: TextStyle(
                      color: _selectedLevel != null ? const Color(0xFF5516be) : const Color(0xFF474554),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Sort Filter
                  ChoiceChip(
                    label: Text(_selectedSortBy ?? 'Sort', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    selected: _selectedSortBy != null,
                    onSelected: (selected) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sort By',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF121c2a),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Default'),
                                    selected: _selectedSortBy == null,
                                    onSelected: (selected) {
                                      setState(() => _selectedSortBy = null);
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Rating'),
                                    selected: _selectedSortBy == 'rating',
                                    onSelected: (selected) {
                                      setState(() => _selectedSortBy = 'rating');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Price'),
                                    selected: _selectedSortBy == 'price',
                                    onSelected: (selected) {
                                      setState(() => _selectedSortBy = 'price');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Newest'),
                                    selected: _selectedSortBy == 'newest',
                                    onSelected: (selected) {
                                      setState(() => _selectedSortBy = 'newest');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Popular'),
                                    selected: _selectedSortBy == 'popular',
                                    onSelected: (selected) {
                                      setState(() => _selectedSortBy = 'popular');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    selectedColor: const Color(0xFFe9ddff),
                    backgroundColor: const Color(0xFFeff4ff),
                    side: BorderSide(color: _selectedSortBy != null ? const Color(0xFF5516be) : const Color(0xFFc8c4d7)),
                    labelStyle: TextStyle(
                      color: _selectedSortBy != null ? const Color(0xFF5516be) : const Color(0xFF474554),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Advanced Filters
                  Flexible(
                    child: ActionChip(
                      label: Text('More Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF474554))),
                      backgroundColor: const Color(0xFFeff4ff),
                      side: const BorderSide(color: Color(0xFFc8c4d7)),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => _buildAdvancedFiltersSheet(),
                        );
                      },
                      avatar: const Icon(Icons.tune, size: 18, color: Color(0xFF474554)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Clear Filters
                  if (_selectedCategory != null || _selectedLevel != null || _selectedSortBy != null || _minRating != null || _maxPrice != null || _searchController.text.isNotEmpty)
                    Flexible(
                      child: ActionChip(
                        label: Text('Clear', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFba1a1a))),
                        backgroundColor: const Color(0xFFffdad6),
                        side: const BorderSide(color: Color(0xFFffdad6)),
                        onPressed: _clearFilters,
                        avatar: const Icon(Icons.clear, size: 18, color: Color(0xFFba1a1a)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${_filteredCourses.length} course${_filteredCourses.length != 1 ? 's' : ''} found',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF474554),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Course List
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
                  : _filteredCourses.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 80,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No courses found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your filters',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : MediaQuery.of(context).size.width > 800 ? 3 : MediaQuery.of(context).size.width > 600 ? 2 : 1,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredCourses.length,
                itemBuilder: (context, index) {
                  return _buildCourseCard(_filteredCourses[index]);
                },
              ),
            ),
          ],
        ),
      ),
      ),
      ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFc8c4d7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5b4ed9).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // Check enrollment and navigate
              final token = await ApiClient.instance.getToken();
              if (token != null && mounted) {
                final isEnrolled = await _enrollmentManager.isEnrolled(course.courseId);
                if (isEnrolled && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseContentScreen(
                        courseId: course.courseId,
                        title: course.title,
                      ),
                    ),
                  );
                }
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Thumbnail
                Expanded(
                  child: Container(
                    width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFe6eeff),
                  ),
                  child: course.thumbnailURL.isNotEmpty
                      ? Image.network(
                          course.thumbnailURL,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.school,
                                size: 60,
                                color: Color(0xFFc5c0ff),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.school,
                            size: 60,
                            color: Color(0xFFc5c0ff),
                          ),
                        ),
                  ),
                ),

                // Course Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Level
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFe9ddff),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.category,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF6b38d4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00724e).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.level.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF00573a),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        course.title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF121c2a),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Instructor
                      Text(
                        'by ${course.instructor}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF474554),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Footer: Rating, Duration, Price
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF121c2a),
                            ),
                          ),
                          Text(
                            ' (${course.ratingCount})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF787586),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFF787586),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${course.duration}h',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF787586),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            course.price == 0
                                ? 'FREE'
                                : '\$${course.price.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: course.price == 0
                                  ? const Color(0xFF00573a)
                                  : const Color(0xFF4231c0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildEnrollButton(course),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollButton(CourseModel course) {
    return FutureBuilder<String?>(
      future: ApiClient.instance.getToken(),
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.hasData && snapshot.data != null;
        if (!isLoggedIn) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4231c0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Login to Enroll', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          );
        }

        return StreamBuilder<bool>(
          stream: _enrollmentManager.watchEnrollment(course.courseId),
          builder: (context, snapshot) {
            final enrolled = snapshot.data == true;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enrolled
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseContentScreen(
                              courseId: course.courseId,
                              title: course.title,
                            ),
                          ),
                        );
                      }
                    : () async {
                        // Check if course is free or user has already paid
                        final isFree = course.price == 0;
                        final paymentManager = PaymentManager();
                        
                        if (!isFree) {
                          final hasPaid = await paymentManager.hasUserPaidForCourse(course.courseId);
                          if (!hasPaid) {
                            // Convert price (double) to cents (int) for payment
                            final amountCents = (course.price * 100).round();
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
                            if (success != true) return; // user backed out
                          }
                        }

                        final err = await _enrollmentManager.enrollInCourse(course.courseId);
                        if (!mounted) return;
                        if (err == null) {
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
                            SnackBar(content: Text(err), backgroundColor: Theme.of(context).colorScheme.error),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: enrolled ? const Color(0xFFe6eeff) : const Color(0xFF4231c0),
                  foregroundColor: enrolled ? const Color(0xFF474554) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(enrolled ? 'Open' : 'Enroll', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdvancedFiltersSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Advanced Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Rating Filter
              const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _minRating ?? 0.0,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: _minRating != null ? _minRating!.toStringAsFixed(1) : 'Any',
                      onChanged: (value) {
                        setModalState(() {
                          _minRating = value > 0 ? value : null;
                        });
                      },
                    ),
                  ),
                  Text(_minRating != null ? _minRating!.toStringAsFixed(1) : 'Any'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Price Filter
              const Text('Maximum Price', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _maxPrice ?? 1000.0,
                      min: 0.0,
                      max: 1000.0,
                      divisions: 20,
                      label: _maxPrice != null ? '\$${_maxPrice!.toInt()}' : 'Any',
                      onChanged: (value) {
                        setModalState(() {
                          _maxPrice = value < 1000 ? value : null;
                        });
                      },
                    ),
                  ),
                  Text(_maxPrice != null ? '\$${_maxPrice!.toInt()}' : 'Any'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          _minRating = null;
                          _maxPrice = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _filterCourses();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: const Text('Apply Filters'),
                    ),
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
