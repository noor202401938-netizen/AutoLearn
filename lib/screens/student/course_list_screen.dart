// lib/screens/student/course_list_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../business_logic/course_manager.dart';
import '../../business_logic/search_filter_engine.dart';
import '../../model/course_model.dart';
import '../../business_logic/enrollment_manager.dart';
import '../../business_logic/payment_manager.dart';
import '../../backend/api_client.dart';
import 'payment_screen.dart';
import 'course_content_screen.dart';
import '../../widgets/student_home/ambient_background.dart';

class CourseListScreen extends StatefulWidget {
  /// When [embedded] is true the widget is hosted inside another Scaffold
  /// (e.g. StudentHome). We suppress our own Scaffold/AppBar to avoid the
  /// nested-Scaffold bug and the double-AppBar UX issue.
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

  List<CourseModel> _filteredCourses = [];
  List<String> _categories = [];

  String? _selectedCategory;
  String? _selectedLevel;
  String? _selectedSortBy;
  double? _minRating;
  double? _maxPrice;
  bool _isLoading = true;
  bool _hasError = false;

  // Debounce timer for search
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
      setState(() {
        _filteredCourses = courses;
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

  /// Generic option-picker bottom sheet — replaces ~200 lines of duplicated
  /// per-filter bottom-sheet boilerplate.
  void _showOptionPicker({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: selectedValue == null,
                      onSelected: (_) {
                        onSelected(null);
                        _filterCourses();
                        Navigator.pop(ctx);
                      },
                    ),
                    ...options.map((opt) => ChoiceChip(
                          label: Text(opt),
                          selected: selectedValue == opt,
                          onSelected: (_) {
                            onSelected(opt);
                            _filterCourses();
                            Navigator.pop(ctx);
                          },
                        )),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // When embedded inside StudentHome, skip the Scaffold + AppBar to avoid
    // nested-Scaffold issues and a double AppBar on the Courses tab.
    // The AmbientBackground is also already rendered by StudentHome.
    final body = _buildBody(theme);
    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Browse Courses',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
      ),
      body: body,
    );
  }

  Widget _buildBody(ThemeData theme) {
    return Stack(
      children: [
          const AmbientBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: RefreshIndicator(
                  onRefresh: _loadCourses,
                  child: Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme
                                .surfaceContainerHighest, // surface-container-low
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Search courses...',
                              hintStyle: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.outline),
                            prefixIcon: Icon(
                                Icons.search,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear,
                                          color: theme.colorScheme.onSurfaceVariant),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterCourses();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                            onChanged: (value) {
                              // Debounce: wait 400 ms after last keystroke
                              _searchDebounce?.cancel();
                              _searchDebounce = Timer(
                                const Duration(milliseconds: 400),
                                _filterCourses,
                              );
                            },
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
                                label: Text(
                                    _selectedCategory ?? 'All Categories',
                                    style: theme.textTheme.labelLarge),
                                selected: _selectedCategory != null,
                                onSelected: (_) {
                                  _showOptionPicker(
                                    title: 'Select Category',
                                    options: _categories,
                                    selectedValue: _selectedCategory,
                                    onSelected: (v) =>
                                        setState(() => _selectedCategory = v),
                                  );
                                },
                                selectedColor:
                                    theme.colorScheme.primaryContainer,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                side: BorderSide(
                                    color: _selectedCategory != null
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline),
                                labelStyle: TextStyle(
                                  color: _selectedCategory != null
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Level Filter
                            ChoiceChip(
                              label: Text(_selectedLevel ?? 'All Levels',
                                  style: theme.textTheme.labelLarge),
                              selected: _selectedLevel != null,
                              onSelected: (_) {
                                _showOptionPicker(
                                  title: 'Select Level',
                                  options: const [
                                    'beginner',
                                    'intermediate',
                                    'advanced'
                                  ],
                                  selectedValue: _selectedLevel,
                                  onSelected: (v) =>
                                      setState(() => _selectedLevel = v),
                                );
                              },
                              selectedColor: theme.colorScheme.primaryContainer,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              side: BorderSide(
                                  color: _selectedLevel != null
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline),
                              labelStyle: TextStyle(
                                color: _selectedLevel != null
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Sort Filter
                            ChoiceChip(
                              label: Text(_selectedSortBy ?? 'Sort',
                                  style: theme.textTheme.labelLarge),
                              selected: _selectedSortBy != null,
                              onSelected: (_) {
                                _showOptionPicker(
                                  title: 'Sort By',
                                  options: const [
                                    'rating',
                                    'price',
                                    'newest',
                                    'popular'
                                  ],
                                  selectedValue: _selectedSortBy,
                                  onSelected: (v) =>
                                      setState(() => _selectedSortBy = v),
                                );
                              },
                              selectedColor: theme.colorScheme.primaryContainer,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              side: BorderSide(
                                  color: _selectedSortBy != null
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline),
                              labelStyle: TextStyle(
                                color: _selectedSortBy != null
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                             const SizedBox(width: 8),

                            // Advanced Filters
                            Flexible(
                              child: ActionChip(
                                label: Text('More Filters',
                                    style: theme.textTheme.labelLarge),
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                side:
                                    BorderSide(color: theme.colorScheme.outlineVariant),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) =>
                                        _buildAdvancedFiltersSheet(),
                                  );
                                },
                                avatar: Icon(Icons.tune,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Clear Filters
                            if (_selectedCategory != null ||
                                _selectedLevel != null ||
                                _selectedSortBy != null ||
                                _minRating != null ||
                                _maxPrice != null ||
                                _searchController.text.isNotEmpty)
                              Flexible(
                                child: ActionChip(
                                  label: Text('Clear',
                                      style: theme.textTheme.labelLarge),
                                  backgroundColor:
                                      theme.colorScheme.errorContainer,
                                  side: BorderSide(
                                      color: theme.colorScheme.errorContainer),
                                  onPressed: _clearFilters,
                                  avatar: Icon(Icons.clear,
                                      size: 18,
                                      color: theme.colorScheme.error),
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
                              style: theme.textTheme.bodyMedium,
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
                            : _hasError
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.wifi_off_rounded,
                                            size: 64,
                                            color: theme.colorScheme.outline),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Failed to load courses',
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: _loadCourses,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  )
                                : _filteredCourses.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 80,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No courses found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Try adjusting your filters',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        top: 8,
                                        bottom: 100),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: MediaQuery.of(context)
                                                  .size
                                                  .width >
                                              1200
                                          ? 4
                                          : MediaQuery.of(context).size.width >
                                                  800
                                              ? 3
                                              : MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? 2
                                                  : 1,
                                      childAspectRatio: 0.65,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: _filteredCourses.length,
                                    itemBuilder: (context, index) {
                                      return _buildCourseCard(
                                          _filteredCourses[index]);
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildCourseCard(CourseModel course) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                final isEnrolled =
                    await _enrollmentManager.isEnrolled(course.courseId);
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
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    ),
                    child: course.thumbnailURL.isNotEmpty
                        ? Image.network(
                            course.thumbnailURL,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.school,
                                  size: 60,
                                  color: theme.colorScheme.primaryContainer,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.school,
                              size: 60,
                              color: theme.colorScheme.primaryContainer,
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
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.category,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.level.toUpperCase(),
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: theme.colorScheme.tertiary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        course.title,
                        style: theme.textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Instructor
                      Text(
                        'by ${course.instructor}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),

                      // Footer: Rating, Duration, Price
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.rating.toStringAsFixed(1),
                            style: theme.textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' (${course.ratingCount})',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${course.duration}h',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const Spacer(),
                          Text(
                            course.price == 0
                                ? 'FREE'
                                : '\$${course.price.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: course.price == 0
                                  ? Colors.green.shade700
                                  : theme.colorScheme.primary,
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
    final theme = Theme.of(context);
    return FutureBuilder<String?>(
      future: ApiClient.instance.getToken(),
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.hasData && snapshot.data != null;
        if (!isLoggedIn) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Login to Enroll', style: theme.textTheme.labelLarge),
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
                          final hasPaid = await paymentManager
                              .hasUserPaidForCourse(course.courseId);
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

                        final err = await _enrollmentManager
                            .enrollInCourse(course.courseId);
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
                            SnackBar(
                                content: Text(err),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: enrolled
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.primary,
                  foregroundColor: enrolled
                      ? theme.colorScheme.onSurfaceVariant
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: enrolled ? 0 : 4,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(enrolled ? 'Open' : 'Enroll',
                    style: theme.textTheme.labelLarge),
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
              const Text('Minimum Rating',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _minRating ?? 0.0,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: _minRating != null
                          ? _minRating!.toStringAsFixed(1)
                          : 'Any',
                      onChanged: (value) {
                        setModalState(() {
                          _minRating = value > 0 ? value : null;
                        });
                      },
                    ),
                  ),
                  Text(_minRating != null
                      ? _minRating!.toStringAsFixed(1)
                      : 'Any'),
                ],
              ),

              const SizedBox(height: 24),

              // Price Filter
              const Text('Maximum Price',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _maxPrice ?? 1000.0,
                      min: 0.0,
                      max: 1000.0,
                      divisions: 20,
                      label:
                          _maxPrice != null ? '\$${_maxPrice!.toInt()}' : 'Any',
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
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
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
