import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/quiz_model.dart';
import 'ai_quiz_screen.dart';

class FinalTestScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const FinalTestScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 1,
        shadowColor: Colors.black12,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF4231C0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AutoLearn',
          style: GoogleFonts.geist(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4231C0),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4231C0).withOpacity(0.2), width: 2),
                color: const Color(0xFFD9E3F6),
              ),
              child: const Icon(Icons.person, color: Color(0xFF4231C0)),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              return Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isDesktop ? 8 : 0,
                    child: Column(
                      children: [
                        // Hero Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4231C0).withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00724E).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified, size: 16, color: Color(0xFF00724E)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'FINAL CERTIFICATION',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF00724E),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Machine Learning\nMastery Exam',
                                style: GoogleFonts.geist(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF121C2A),
                                  height: 1.1,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'This is your final milestone. Upon successful completion, you will earn the AutoLearn Certified ML Professional credential. Ensure you are ready before proceeding.',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: const Color(0xFF474554),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Checklist Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC8C4D7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.fact_check, color: Color(0xFF4231C0)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Before You Begin',
                                    style: GoogleFonts.geist(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF121C2A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              GridView.count(
                                crossAxisCount: isDesktop ? 2 : 1,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 4,
                                children: [
                                  _buildChecklistItem(Icons.wifi, 'Stable Internet', 'A high-speed connection is required.', const Color(0xFF00573A)),
                                  _buildChecklistItem(Icons.volume_off, 'Quiet Environment', 'Minimize distractions for 60 mins.', const Color(0xFF00573A)),
                                  _buildChecklistItem(Icons.battery_charging_full, 'Power Source', 'Ensure device is fully charged.', const Color(0xFF00573A)),
                                  _buildChecklistItem(Icons.lock_reset, 'Single Attempt', 'Leaving the tab may disqualify you.', const Color(0xFF00573A)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop) const SizedBox(width: 24),
                  if (!isDesktop) const SizedBox(height: 24),
                  Expanded(
                    flex: isDesktop ? 4 : 0,
                    child: Column(
                      children: [
                        // Parameter Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC8C4D7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXAM PARAMETERS',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF787586),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildParameterRow(Icons.quiz, '50 Questions', 'Multiple Choice', const Color(0xFF4231C0)),
                              const SizedBox(height: 16),
                              _buildParameterRow(Icons.schedule, '60 Minutes', 'Time Limit', const Color(0xFF4231C0)),
                              const SizedBox(height: 16),
                              _buildParameterRow(Icons.grade, '80% to Pass', '40 Correct', const Color(0xFF00573A)),
                              const SizedBox(height: 32),
                              const Divider(color: Color(0xFFC8C4D7)),
                              const SizedBox(height: 16),
                              Row(
                                justifyContent: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Success Probability', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('High', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF00573A))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDEE9FC),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: 0.92,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF00724E), Color(0xFF4EDEA3)]),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Based on your quiz performance (92% avg)',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF474554), fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // CTA
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4231C0), Color(0xFF6B38D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4231C0).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AIQuizScreen(
                                    courseId: courseId,
                                    courseTitle: courseTitle,
                                    moduleId: \'final\',
                                    moduleTitle: \'Final Test\',
                                    lessonId: \'final_test_\',
                                    lessonTitle: \'Final Test: \',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Start Final Assessment', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.play_arrow, size: 16, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text('Ready to begin session', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF121C2A))),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF474554))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildParameterRow(IconData icon, String title, String subtitle, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF121C2A))),
          ],
        ),
        Text(subtitle, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: color == const Color(0xFF4231C0) ? const Color(0xFF474554) : color)),
      ],
    );
  }
}
