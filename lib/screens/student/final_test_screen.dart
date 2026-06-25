import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
          style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
                color: const Color(0xFFD9E3F6),
              ),
              child: const Icon(Icons.person, color: Color(0xFF4231C0)),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
      final theme = Theme.of(context);
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
                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.05),
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
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Machine Learning\nMastery Exam',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  height: 1.1,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'This is your final milestone. Upon successful completion, you will earn the AutoLearn Certified ML Professional credential. Ensure you are ready before proceeding.',
                                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                            border: Border.all(color: theme.colorScheme.outline),
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
                                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                                  _buildChecklistItem(context, Icons.wifi, 'Stable Internet', 'A high-speed connection is required.', Colors.green.shade800),
                                  _buildChecklistItem(context, Icons.volume_off, 'Quiet Environment', 'Minimize distractions for 60 mins.', Colors.green.shade800),
                                  _buildChecklistItem(context, Icons.battery_charging_full, 'Power Source', 'Ensure device is fully charged.', Colors.green.shade800),
                                  _buildChecklistItem(context, Icons.lock_reset, 'Single Attempt', 'Leaving the tab may disqualify you.', Colors.green.shade800),
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
                            border: Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                  'EXAM PARAMETERS',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              const SizedBox(height: 24),
                              _buildParameterRow(context, Icons.quiz, '50 Questions', 'Multiple Choice', theme.colorScheme.primary),
                              const SizedBox(height: 16),
                              _buildParameterRow(context, Icons.schedule, '60 Minutes', 'Time Limit', theme.colorScheme.primary),
                              const SizedBox(height: 16),
                              _buildParameterRow(context, Icons.grade, '80% to Pass', '40 Correct', Colors.green.shade800),
                              const SizedBox(height: 32),
                              const Divider(color: Color(0xFFC8C4D7)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Success Probability', style: theme.textTheme.labelLarge),
                                  Text('High', style: theme.textTheme.bodyMedium),
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
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                                color: theme.colorScheme.primary.withOpacity(0.3),
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
                                    moduleId: 'final',
                                    moduleTitle: 'Final Test',
                                    lessonId: 'final_test_',
                                    lessonTitle: 'Final Test: ',
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
                                Text('Start Final Assessment', style: theme.textTheme.bodyMedium),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.play_arrow, size: 16, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text('Ready to begin session', style: theme.textTheme.bodyMedium),
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
        ),
      ),
    );
  }

  Widget _buildChecklistItem(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
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
                Text(title, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildParameterRow(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    final theme = Theme.of(context);
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
            Text(title, style: theme.textTheme.titleMedium),
          ],
        ),
        Text(subtitle, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
