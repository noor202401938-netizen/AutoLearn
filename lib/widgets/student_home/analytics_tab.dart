import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/user_stats_model.dart';
import 'dart:math' as math;

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  late LearningGoalModel _learningGoal;
  late List<LearningStrengthModel> _learningStrengths;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  void _loadAnalyticsData() {
    // In a real app, fetch from backend via AnalyticsRepository
    _learningGoal = LearningGoalModel(
      currentHours: 12,
      goalHours: 16,
      weeklyHours: [2.4, 3.1, 4.5, 2.8, 0, 0, 0],
      avgScore: 89,
      scoreIncrease: 12,
    );

    _learningStrengths = [
      LearningStrengthModel(
        skillName: 'Design Thinking',
        icon: 'psychology',
        level: 'PRO',
        progress: 0.92,
      ),
      LearningStrengthModel(
        skillName: 'User Research',
        icon: 'search_insights',
        level: 'ADV',
        progress: 0.78,
      ),
      LearningStrengthModel(
        skillName: 'UI Design',
        icon: 'palette',
        level: 'ADV',
        progress: 0.85,
      ),
      LearningStrengthModel(
        skillName: 'Prototyping',
        icon: 'code',
        level: 'BEG',
        progress: 0.45,
      ),
    ];
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'psychology':
        return Icons.psychology;
      case 'search_insights':
        return Icons.search; // Fallback or close match
      case 'palette':
        return Icons.palette;
      case 'code':
        return Icons.code;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 16),
              _buildProgressWheelCard(),
              const SizedBox(height: 24),
              _buildHoursLearnedChart(),
              const SizedBox(height: 24),
              _buildQuizPerformance(),
              const SizedBox(height: 24),
              _buildStrengthsSection(),
              const SizedBox(height: 24),
              _buildCourseSuggestion(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Learning Journey',
          style: GoogleFonts.geist(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121c2a),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tracking your growth since Jan 2024',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF474554),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressWheelCard() {
    final progressPercent = (_learningGoal.currentHours / _learningGoal.goalHours).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFffffff),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFc8c4d7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5b4ed9).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Weekly Goal Progress',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF474554),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 192,
            height: 192,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  color: const Color(0xFFd9e3f6),
                ),
                CircularProgressIndicator(
                  value: progressPercent,
                  strokeWidth: 12,
                  color: const Color(0xFF4231c0),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(progressPercent * 100).toInt()}%',
                        style: GoogleFonts.geist(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4231c0),
                        ),
                      ),
                      Text(
                        '${_learningGoal.currentHours.toInt()}/${_learningGoal.goalHours.toInt()} HOURS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.05,
                          color: const Color(0xFF474554),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFe6eeff),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Color(0xFF4edea3), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '5 Day Streak',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF121c2a),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View History',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4231c0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursLearnedChart() {
    final maxHours = _learningGoal.weeklyHours.isEmpty ? 1.0 : _learningGoal.weeklyHours.reduce(math.max);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFffffff),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFc8c4d7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5b4ed9).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hours Learned',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF474554),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4231c0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'THIS WEEK',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.05,
                      color: const Color(0xFF474554),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 128,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final val = index < _learningGoal.weeklyHours.length ? _learningGoal.weeklyHours[index] : 0;
                final heightFactor = maxHours > 0 ? val / maxHours : 0.0;
                // Hardcoding today to be Thursday (index 3) for design matching
                final isToday = index == 3;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Tooltip(
                      message: '${val.toStringAsFixed(1)}h',
                      child: Container(
                        height: 128 * heightFactor,
                        decoration: BoxDecoration(
                          color: isToday ? const Color(0xFF4231c0) : const Color(0xFF5b4ed9).withOpacity(0.2),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isToday = index == 3;
              return Expanded(
                child: Text(
                  days[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday ? const Color(0xFF4231c0) : const Color(0xFF787586),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizPerformance() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFffffff),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFc8c4d7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5b4ed9).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Performance',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF474554),
            ),
          ),
          const SizedBox(height: 16),
          // Simplified graph representation
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5b4ed9).withOpacity(0.1),
                  const Color(0xFFffffff).withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFc8c4d7)),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    'Performance graph placeholder',
                    style: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFe3dfff),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${_learningGoal.scoreIncrease.toInt()}% Avg.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4231c0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFF6b38d4), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Top 5% this month',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF121c2a),
                    ),
                  ),
                ],
              ),
              Text(
                '${_learningGoal.avgScore}/100 AVG',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF787586),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Learning Strengths',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF474554),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
          ),
          itemCount: _learningStrengths.length,
          itemBuilder: (context, index) {
            final strength = _learningStrengths[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFeff4ff), // surface-container-low
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00573a).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        _getIconData(strength.icon),
                        color: const Color(0xFF00573a), // tertiary
                        size: 20,
                      ),
                      Text(
                        strength.level,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4edea3), // tertiary-fixed-dim
                        ),
                      ),
                    ],
                  ),
                  Text(
                    strength.skillName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00573a),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFd9e3f6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.4 * strength.progress, // Approximated
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00573a), Color(0xFF4edea3)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourseSuggestion() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF4231c0).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4231c0).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Next Step',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4231c0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Deep dive into Information Architecture to boost your research score.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF474554),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4231c0), Color(0xFF6b38d4)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    ),
                    child: Text(
                      'Start Module',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFc5c0ff), // primary-fixed-dim
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school,
              color: Color(0xFF4231c0),
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}
