import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/course_model.dart';
import '../../repository/course_repository.dart';
import '../../widgets/premium/premium_card.dart';
import 'assignment_screen.dart';

enum AssignmentStatus { pending, submitted, graded }

class AssignmentItem {
  final String id;
  final String title;
  final String courseTitle;
  final String courseId;
  final String moduleId;
  final String moduleTitle;
  final String lessonId;
  final String lessonTitle;
  final String dueDate;
  final int maxPoints;
  final int? score;
  final AssignmentStatus status;
  final String aiFeedbackSnippet;

  const AssignmentItem({
    required this.id,
    required this.title,
    required this.courseTitle,
    required this.courseId,
    required this.moduleId,
    required this.moduleTitle,
    required this.lessonId,
    required this.lessonTitle,
    required this.dueDate,
    required this.maxPoints,
    this.score,
    required this.status,
    this.aiFeedbackSnippet = '',
  });
}

class AssignmentsHubScreen extends StatefulWidget {
  final bool embedded;

  const AssignmentsHubScreen({super.key, this.embedded = false});

  @override
  State<AssignmentsHubScreen> createState() => _AssignmentsHubScreenState();
}

class _AssignmentsHubScreenState extends State<AssignmentsHubScreen> {
  final CourseRepository _courseRepository = CourseRepository();
  AssignmentStatus _activeTab = AssignmentStatus.pending;
  List<CourseModel> _allCourses = [];
  bool _isLoading = true;

  List<AssignmentItem> _assignments = [];

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

      final firstCourse = courses.isNotEmpty ? courses[0] : null;
      final secondCourse = courses.length > 1 ? courses[1] : firstCourse;

      _assignments = [
        AssignmentItem(
          id: 'asg-1',
          title: 'Case Study: Monopolistic Competition & Pricing Power',
          courseTitle: firstCourse?.title ?? 'Economics of Market Failure',
          courseId: firstCourse?.courseId ?? 'c-1',
          moduleId: 'm-1',
          moduleTitle: 'Market Structures',
          lessonId: 'l-1',
          lessonTitle: 'Strategic Pricing',
          dueDate: 'Tomorrow, 11:59 PM',
          maxPoints: 100,
          status: AssignmentStatus.pending,
        ),
        AssignmentItem(
          id: 'asg-2',
          title: 'Empirical Problem Set: OLS Regression Diagnostics',
          courseTitle: secondCourse?.title ?? 'Applied Econometrics Track',
          courseId: secondCourse?.courseId ?? 'c-2',
          moduleId: 'm-2',
          moduleTitle: 'Regression Analysis',
          lessonId: 'l-2',
          lessonTitle: 'Heteroskedasticity Tests',
          dueDate: 'In 4 days',
          maxPoints: 50,
          status: AssignmentStatus.pending,
        ),
        AssignmentItem(
          id: 'asg-3',
          title: 'Essay: Central Bank Rate Hikes & Inflationary Expectations',
          courseTitle: 'Macroeconomic Policy & Money',
          courseId: 'c-3',
          moduleId: 'm-1',
          moduleTitle: 'Monetary Transmission',
          lessonId: 'l-3',
          lessonTitle: 'Policy Rate Impact',
          dueDate: 'Submitted 3 days ago',
          maxPoints: 100,
          score: 96,
          status: AssignmentStatus.graded,
          aiFeedbackSnippet: 'Outstanding quantitative synthesis of the Taylor Rule and real-world Phillips curve trade-offs.',
        ),
        AssignmentItem(
          id: 'asg-4',
          title: 'Problem Set 1: Consumer Surplus & Deadweight Loss',
          courseTitle: firstCourse?.title ?? 'Economics of Market Failure',
          courseId: firstCourse?.courseId ?? 'c-1',
          moduleId: 'm-1',
          moduleTitle: 'Welfare Analysis',
          lessonId: 'l-4',
          lessonTitle: 'Tax Incidence Calculations',
          dueDate: 'Submitted 1 week ago',
          maxPoints: 100,
          score: 92,
          status: AssignmentStatus.graded,
          aiFeedbackSnippet: 'Accurate welfare triangles and deadweight loss calculations. Minor clarity improvement in question 3b.',
        ),
      ];

      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<AssignmentItem> get _filteredAssignments {
    return _assignments.where((a) => a.status == _activeTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pendingCount = _assignments.where((a) => a.status == AssignmentStatus.pending).length;
    final gradedCount = _assignments.where((a) => a.status == AssignmentStatus.graded).length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Stat Cards
              Text(
                'Assignments & Assessments Hub',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track deadlines, submit case studies, and review automated AI rubrics & feedback.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : const Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 20),

              // Stat Row
              Row(
                children: [
                  _buildStatCard('Pending Work', '$pendingCount Due', CupertinoIcons.clock_fill, const Color(0xFFC69234), isDark),
                  const SizedBox(width: 16),
                  _buildStatCard('Graded & Reviewed', '$gradedCount Completed', CupertinoIcons.check_mark_circled_solid, const Color(0xFF004741), isDark),
                  const SizedBox(width: 16),
                  _buildStatCard('Average Score', '94.0%', CupertinoIcons.rosette, const Color(0xFF0D5E56), isDark),
                ],
              ),
              const SizedBox(height: 28),

              // Tabs
              _buildTabs(isDark, pendingCount, gradedCount),
              const SizedBox(height: 20),

              // Assignment Cards
              if (_filteredAssignments.isEmpty)
                _buildEmptyState(isDark)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredAssignments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = _filteredAssignments[index];
                    return _buildAssignmentCard(context, item, isDark);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : const Color(0xFF718096),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDark, int pending, int graded) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2220) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton('Pending Submissions ($pending)', AssignmentStatus.pending, isDark),
          _buildTabButton('Graded & Feedback ($graded)', AssignmentStatus.graded, isDark),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, AssignmentStatus status, bool isDark) {
    final isSelected = _activeTab == status;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = status),
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

  Widget _buildAssignmentCard(BuildContext context, AssignmentItem item, bool isDark) {
    final isGraded = item.status == AssignmentStatus.graded;

    return PremiumCard(
      padding: const EdgeInsets.all(22),
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
                    Text(
                      item.courseTitle.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF004741),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.moduleTitle} • ${item.lessonTitle}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              if (isGraded && item.score != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004741).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF004741)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${item.score}/${item.maxPoints}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF004741),
                        ),
                      ),
                      Text(
                        'Grade',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // AI Feedback Preview
          if (isGraded && item.aiFeedbackSnippet.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D2220) : const Color(0xFFF0EDE4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFC69234).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(CupertinoIcons.sparkles, color: Color(0xFFC69234), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Evaluator Feedback: "${item.aiFeedbackSnippet}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                isGraded ? CupertinoIcons.check_mark_circled : CupertinoIcons.calendar,
                size: 14,
                color: isGraded ? Colors.green : const Color(0xFFC69234),
              ),
              const SizedBox(width: 6),
              Text(
                item.dueDate,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isGraded ? Colors.green : const Color(0xFFC69234),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignmentScreen(
                        courseId: item.courseId,
                        courseTitle: item.courseTitle,
                        moduleId: item.moduleId,
                        moduleTitle: item.moduleTitle,
                        lessonId: item.lessonId,
                        lessonTitle: item.lessonTitle,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  isGraded ? CupertinoIcons.eye_fill : CupertinoIcons.arrow_up_doc_fill,
                  size: 14,
                ),
                label: Text(
                  isGraded ? 'View Submission' : 'Start Assignment',
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(CupertinoIcons.doc_checkmark, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Assignments in this section',
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
