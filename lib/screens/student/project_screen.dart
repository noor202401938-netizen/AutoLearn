import 'package:flutter/material.dart';
import 'assignment_screen.dart';

import '../../repository/quiz_repository.dart';
import '../../repository/auth_repository.dart';
import '../../model/quiz_model.dart';
import 'package:intl/intl.dart';

class ProjectScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String lessonId;
  final String lessonTitle;

  const ProjectScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final QuizRepository _quizRepository = QuizRepository();
  AssignmentModel? _assignment;
  AssignmentSubmissionModel? _existingSubmission;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    try {
      _assignment =
          await _quizRepository.getAssignmentByLessonId(widget.lessonId);
      if (_assignment != null) {
        final user = await AuthRepository().getCurrentUser();
        final uid = user?['uid'] as String?;
        if (uid != null) {
          _existingSubmission =
              await _quizRepository.getUserAssignmentSubmission(
            userId: uid,
            assignmentId: _assignment!.assignmentId,
          );
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AutoLearn',
          style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
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
                        flex: isDesktop ? 4 : 0,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: theme.colorScheme.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      'CAPSTONE PROJECT',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _assignment?.title ?? widget.lessonTitle,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _assignment?.description.isNotEmpty == true
                                        ? _assignment!.description
                                        : 'Complete this final capstone project to demonstrate your mastery of the course material.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: theme.colorScheme.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PROJECT BRIEF',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(letterSpacing: 1.5)),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.description,
                                          color: theme.colorScheme.primary,
                                          size: 18),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Objectives',
                                                style:
                                                    theme.textTheme.labelLarge),
                                            const SizedBox(height: 4),
                                            Text(
                                                '• Real-time sensor fusion processing',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onSurfaceVariant)),
                                            Text(
                                                '• LIDAR-based mapping algorithm',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onSurfaceVariant)),
                                            Text(
                                                '• Battery-efficient flight paths',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onSurfaceVariant)),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.calendar_today,
                                          color: theme.colorScheme.primary,
                                          size: 18),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Deadline',
                                                style:
                                                    theme.textTheme.labelLarge),
                                            const SizedBox(height: 4),
                                            Text(
                                                _assignment != null
                                                    ? DateFormat('MMMM d, yyyy')
                                                        .format(_assignment!
                                                            .dueDate)
                                                    : 'Loading...',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onSurfaceVariant)),
                                          ],
                                        ),
                                      )
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
                        flex: isDesktop ? 8 : 0,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: theme.colorScheme.outlineVariant),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Overall Completion',
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      Text(
                                          _existingSubmission != null
                                              ? '100%'
                                              : '0%',
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme
                                                      .colorScheme.secondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: FractionallySizedBox(
                                      widthFactor: _existingSubmission != null
                                          ? 1.0
                                          : 0.05,
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondary,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            GridView.count(
                              crossAxisCount: isDesktop ? 2 : 1,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: isDesktop ? 2 : 3,
                              children: [
                                _buildMilestoneCard(
                                  context: context,
                                  title: 'Planning & Research',
                                  subtitle:
                                      'Market analysis and hardware specification selection completed.',
                                  phase: 'Phase 1',
                                  isDone: true,
                                ),
                                _buildMilestoneCard(
                                  context: context,
                                  title: 'System Design',
                                  subtitle:
                                      'Architecture diagrams and API schema finalized.',
                                  phase: 'Phase 2',
                                  isDone: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildActiveMilestoneCard(context),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AssignmentScreen(
                                        courseId: widget.courseId,
                                        courseTitle: widget.courseTitle,
                                        moduleId: 'project',
                                        moduleTitle: 'Final Project',
                                        lessonId: widget.lessonId,
                                        lessonTitle: widget.lessonTitle,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send,
                                        color: theme.colorScheme.onPrimary,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                        _existingSubmission != null
                                            ? 'Submitted'
                                            : 'Submit Now',
                                        style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
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

  Widget _buildMilestoneCard(
      {required BuildContext context,
      required String title,
      required String subtitle,
      required String phase,
      required bool isDone}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border(
            left: BorderSide(color: theme.colorScheme.secondary, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.check_circle,
                  color: theme.colorScheme.secondary, size: 20),
              Text(phase, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(subtitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildActiveMilestoneCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 4)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.hourglass_top,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('PHASE 3: IMPLEMENTATION (CURRENT)',
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Text('In Progress',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Core Navigation Logic',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LIDAR Integration',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text('Done', style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pathfinding AI Model',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Training...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
