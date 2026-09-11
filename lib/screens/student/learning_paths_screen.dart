import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/course_model.dart';
import '../../repository/course_repository.dart';
import '../../widgets/premium/premium_card.dart';
import '../../widgets/premium/rating_stars.dart';
import 'course_content_screen.dart';

class LearningPathModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String level;
  final int totalCourses;
  final int estimatedMonths;
  final double rating;
  final int studentsEnrolled;
  final List<String> skills;
  final List<String> milestoneTitles;
  final double completionProgress;

  const LearningPathModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.totalCourses,
    required this.estimatedMonths,
    required this.rating,
    required this.studentsEnrolled,
    required this.skills,
    required this.milestoneTitles,
    this.completionProgress = 0.0,
  });
}

class LearningPathsScreen extends StatefulWidget {
  final bool embedded;

  const LearningPathsScreen({super.key, this.embedded = false});

  @override
  State<LearningPathsScreen> createState() => _LearningPathsScreenState();
}

class _LearningPathsScreenState extends State<LearningPathsScreen> {
  final CourseRepository _courseRepository = CourseRepository();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<CourseModel> _allCourses = [];
  bool _isLoading = true;

  final List<LearningPathModel> _learningPaths = const [
    LearningPathModel(
      id: 'path-1',
      title: 'Applied Microeconomics & Market Dynamics',
      description: 'Master consumer choice theory, supply-demand equilibria, market structures, and game theory with real-world case simulations.',
      category: 'Microeconomics',
      level: 'Intermediate',
      totalCourses: 4,
      estimatedMonths: 3,
      rating: 4.9,
      studentsEnrolled: 1420,
      completionProgress: 0.65,
      skills: ['Elasticity', 'Game Theory', 'Monopoly Pricing', 'Welfare Economics'],
      milestoneTitles: [
        'Foundations of Consumer & Producer Theory',
        'Market Structures & Strategic Pricing',
        'Game Theory & Competitive Behavior',
        'Capstone: Antitrust & Market Design Project',
      ],
    ),
    LearningPathModel(
      id: 'path-2',
      title: 'Econometrics, Quantitative Data & Forecasting',
      description: 'Learn statistical modeling, OLS regression, causal inference, and time-series forecasting using empirical economic datasets.',
      category: 'Data & Quant',
      level: 'Advanced',
      totalCourses: 5,
      estimatedMonths: 4,
      rating: 4.8,
      studentsEnrolled: 2150,
      completionProgress: 0.25,
      skills: ['Regression Analysis', 'Time Series', 'Causal Inference', 'Python / R'],
      milestoneTitles: [
        'Probability & Statistical Foundations',
        'Multiple Regression & OLS Diagnostics',
        'Time Series & Macro Forecasting',
        'Panel Data & Instrumental Variables',
        'Capstone: Empirical Research Report',
      ],
    ),
    LearningPathModel(
      id: 'path-3',
      title: 'Macroeconomic Policy, Inflation & Central Banking',
      description: 'Understand fiscal policy, monetary policy transmission mechanisms, yield curve dynamics, and macroeconomic stabilization.',
      category: 'Macroeconomics',
      level: 'Intermediate',
      totalCourses: 3,
      estimatedMonths: 2,
      rating: 4.9,
      studentsEnrolled: 980,
      completionProgress: 0.0,
      skills: ['Monetary Policy', 'IS-LM Modeling', 'Inflation Targeting', 'FX Markets'],
      milestoneTitles: [
        'National Income & Aggregate Demand',
        'Central Banking & Monetary Operations',
        'Global Financial Flows & Exchange Rates',
      ],
    ),
    LearningPathModel(
      id: 'path-4',
      title: 'Behavioral Economics & Nudge Architecture',
      description: 'Explore cognitive biases, heuristics, prospect theory, and behavioral interventions for modern product and public policy design.',
      category: 'Behavioral',
      level: 'Beginner',
      totalCourses: 3,
      estimatedMonths: 2,
      rating: 4.7,
      studentsEnrolled: 1640,
      completionProgress: 0.0,
      skills: ['Prospect Theory', 'Heuristics', 'Choice Architecture', 'Nudge Design'],
      milestoneTitles: [
        'Psychological Foundations of Decision Making',
        'Heuristics & Systematic Biases',
        'Applied Choice Architecture & Case Studies',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _courseRepository.getAllCourses();
      setState(() {
        _allCourses = courses;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<LearningPathModel> get _filteredPaths {
    return _learningPaths.where((p) {
      final matchCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchQuery = _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.skills.any((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchCat && matchQuery;
    }).toList();
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
              // 1. Header Banner
              _buildHeader(isDark),
              const SizedBox(height: 28),

              // 2. Filter Pills
              _buildFilterChips(isDark),
              const SizedBox(height: 24),

              // 3. Learning Paths List
              if (_filteredPaths.isEmpty)
                _buildEmptyState(isDark)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final path = _filteredPaths[index];
                    return _buildPathCard(context, path, isDark);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF003833), const Color(0xFF071514)]
              : [const Color(0xFF004741), const Color(0xFF0D5E56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004741).withValues(alpha: 0.25),
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
                  'CAREER TRACKS & SPECIALIZATIONS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(CupertinoIcons.compass_fill, color: Color(0xFFC69234), size: 18),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Structured Pathways to Subject Mastery',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF0EDE4),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Follow curated, multi-course roadmaps designed by leading economists to take you from foundational concepts to advanced empirical modeling.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final categories = ['All', 'Microeconomics', 'Macroeconomics', 'Data & Quant', 'Behavioral'];
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

  Widget _buildPathCard(BuildContext context, LearningPathModel path, bool isDark) {
    return PremiumCard(
      onTap: () {
        _showPathDetailsModal(context, path, isDark);
      },
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF004741).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            path.category.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF004741),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF0EDE4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            path.level,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      path.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              RatingStars(rating: path.rating, ratingCount: path.studentsEnrolled, starSize: 14),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            path.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF4A5568),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar if started
          if (path.completionProgress > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Progress',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004741),
                  ),
                ),
                Text(
                  '${(path.completionProgress * 100).toInt()}% Completed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC69234),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: path.completionProgress,
                backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF004741)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Skills Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: path.skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF15302C) : const Color(0xFFF0EDE4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  skill,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF004741),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Footer Info + Action
          Row(
            children: [
              Icon(CupertinoIcons.book, size: 14, color: isDark ? Colors.white60 : const Color(0xFF718096)),
              const SizedBox(width: 6),
              Text(
                '${path.totalCourses} Courses',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF718096),
                ),
              ),
              const SizedBox(width: 16),
              Icon(CupertinoIcons.clock, size: 14, color: isDark ? Colors.white60 : const Color(0xFF718096)),
              const SizedBox(width: 6),
              Text(
                '~${path.estimatedMonths} Months at 5 hrs/week',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF718096),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showPathDetailsModal(context, path, isDark),
                icon: const Icon(CupertinoIcons.arrow_right_circle_fill, size: 16),
                label: Text(
                  path.completionProgress > 0 ? 'Continue Track' : 'View Track',
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
        ],
      ),
    );
  }

  void _showPathDetailsModal(BuildContext context, LearningPathModel path, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF071514) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        path.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        path.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Curriculum Milestones',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: path.milestoneTitles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (c, i) {
                          final title = path.milestoneTitles[i];
                          final isDone = i < (path.completionProgress * path.milestoneTitles.length).floor();
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0D2220) : const Color(0xFFF8F7F4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDone
                                    ? const Color(0xFF004741)
                                    : (isDark ? const Color(0xFF15302C) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDone ? const Color(0xFF004741) : Colors.transparent,
                                    border: Border.all(
                                      color: isDone ? const Color(0xFF004741) : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: isDone
                                      ? const Icon(Icons.check, size: 16, color: Color(0xFFF0EDE4))
                                      : Center(
                                          child: Text(
                                            '${i + 1}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF1A202C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            if (_allCourses.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CourseContentScreen(
                                    courseId: _allCourses.first.courseId,
                                    title: _allCourses.first.title,
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004741),
                            foregroundColor: const Color(0xFFF0EDE4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Start Specialization Track',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(CupertinoIcons.compass, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Learning Paths Found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
