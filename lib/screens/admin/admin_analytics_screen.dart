import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../business_logic/analytics_monitoring_manager.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  ThemeData get theme => Theme.of(context);

  final AnalyticsMonitoringManager _analyticsManager =
      AnalyticsMonitoringManager();
  bool _isLoading = true;
  double _totalRevenue = 0.0;
  int _activeEnrollments = 0;
  double _completionRate = 0.0;
  int _nps = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _analyticsManager.getPlatformAnalytics();
      if (mounted) {
        setState(() {
          _totalRevenue =
              (stats['totalRevenue'] as num?)?.toDouble() ?? 2482900.0;
          _activeEnrollments =
              (stats['activeEnrollments'] as num?)?.toInt() ?? 45120;
          _completionRate =
              (stats['completionRate'] as num?)?.toDouble() ?? 0.784;
          _nps = (stats['nps'] as num?)?.toInt() ?? 72;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform Analytics',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time performance metrics across all learning verticals.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildControlButton(
                          context, 'Last 30 Days', CupertinoIcons.calendar),
                      const SizedBox(width: 12),
                      _buildControlButton(
                          context, 'Export Reports', CupertinoIcons.arrow_down_doc),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),

              // Key Metrics Grid
              LayoutBuilder(builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                return GridView.count(
                  crossAxisCount: isDesktop ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 1.35 : 1.15,
                  children: [
                    _buildMetricCard(
                      context: context,
                      title: 'Total Revenue',
                      value: '\$${_totalRevenue.toStringAsFixed(2)}',
                      badgeText: '+12.5%',
                      badgeIcon: CupertinoIcons.arrow_up_right,
                      badgeColor: colorScheme.primary,
                      badgeBg: colorScheme.primaryContainer,
                      bottomWidget: Text('Total platform revenue',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                    ),
                    _buildMetricCard(
                      context: context,
                      title: 'Active Enrollments',
                      value: '$_activeEnrollments',
                      badgeText: '+8.2%',
                      badgeIcon: CupertinoIcons.arrow_up_right,
                      badgeColor: colorScheme.primary,
                      badgeBg: colorScheme.primaryContainer,
                      bottomWidget: Text('Across all courses',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                    ),
                    _buildMetricCard(
                      context: context,
                      title: 'Completion Rate',
                      value: '${(_completionRate * 100).toStringAsFixed(1)}%',
                      badgeText: '-0.4%',
                      badgeIcon: CupertinoIcons.arrow_down_right,
                      badgeColor: colorScheme.error,
                      badgeBg: colorScheme.errorContainer.withValues(alpha: 0.5),
                      bottomWidget: _buildProgressBar(context, _completionRate),
                    ),
                    _buildMetricCard(
                      context: context,
                      title: 'Net Promoter Score',
                      value: '$_nps / 100',
                      badgeText: 'Target Met',
                      badgeIcon: CupertinoIcons.checkmark_alt,
                      badgeColor: colorScheme.primary,
                      badgeBg: colorScheme.primaryContainer,
                      bottomWidget: Text('Calculated from reviews',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // Main Analytics Visualization & Side Panel
              LayoutBuilder(builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;
                return Flex(
                  direction: isDesktop ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: isDesktop ? 2 : 0,
                      child: _buildBarChartSection(context, isDesktop),
                    ),
                    if (isDesktop) const SizedBox(width: 24),
                    if (!isDesktop) const SizedBox(height: 24),
                    Expanded(
                      flex: isDesktop ? 1 : 0,
                      child: _buildTopCoursesSection(context, isDesktop),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // Detailed Reports Table
              _buildRecentConversionsTable(context),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurface),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required String badgeText,
    required IconData badgeIcon,
    required Color badgeColor,
    required Color badgeBg,
    required Widget bottomWidget,
  }) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 10, color: badgeColor),
                    const SizedBox(width: 3),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          bottomWidget,
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartSection(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 450,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Growth vs Engagement',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monthly breakdown of new signups and average session hours.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem(context, 'Signups', colorScheme.primary),
                  const SizedBox(width: 16),
                  _buildLegendItem(context, 'Engagement', colorScheme.tertiary),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildDoubleBar(context, 'JAN', 0.4, 0.6),
                _buildDoubleBar(context, 'FEB', 0.55, 0.7),
                _buildDoubleBar(context, 'MAR', 0.75, 0.65),
                _buildDoubleBar(context, 'APR', 0.65, 0.85),
                _buildDoubleBar(context, 'MAY', 0.9, 0.8),
                _buildDoubleBar(context, 'JUN', 0.85, 0.95),
                _buildDoubleBar(context, 'JUL', 1.0, 0.9),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDoubleBar(
      BuildContext context, String label, double fill1, double fill2) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FractionallySizedBox(
                heightFactor: fill1,
                child: Container(
                  width: 16,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              FractionallySizedBox(
                heightFactor: fill2,
                child: Container(
                  width: 16,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildTopCoursesSection(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: isDesktop ? 450 : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performing Courses',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Ranked by conversion & engagement.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: isDesktop ? 1 : 0,
            child: ListView(
              shrinkWrap: !isDesktop,
              physics: isDesktop
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              children: [
                _buildCourseItem(
                    context,
                    'Full-Stack Dev Mastery',
                    '14.2%',
                    '2.4k Students',
                    Icons.terminal,
                    colorScheme.primaryContainer,
                    colorScheme.primary),
                const SizedBox(height: 16),
                _buildCourseItem(
                    context,
                    'AI Ethics & Implementation',
                    '12.8%',
                    '1.9k Students',
                    Icons.psychology,
                    colorScheme.primaryContainer,
                    colorScheme.primary),
                const SizedBox(height: 16),
                _buildCourseItem(
                    context,
                    'Advanced UI Design Systems',
                    '11.5%',
                    '3.1k Students',
                    Icons.design_services,
                    colorScheme.secondaryContainer,
                    colorScheme.secondary),
                const SizedBox(height: 16),
                _buildCourseItem(
                    context,
                    'Data Science Foundations',
                    '9.8%',
                    '1.2k Students',
                    Icons.bar_chart,
                    colorScheme.primaryContainer,
                    colorScheme.onSurfaceVariant),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCourseItem(BuildContext context, String title, String conversion,
      String students, IconData icon, Color iconBg, Color iconColor) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'CONVERSION: $conversion',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.circle,
                          size: 4, color: colorScheme.outlineVariant),
                    ),
                    Text(
                      students,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildRecentConversionsTable(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Conversions',
                  style: theme.textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All Transactions',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(isDark
                  ? colorScheme.surfaceContainer
                  : colorScheme.primaryContainer),
              columns: [
                DataColumn(
                    label: Text('STUDENT', style: theme.textTheme.bodyMedium)),
                DataColumn(
                    label: Text('COURSE', style: theme.textTheme.bodyMedium)),
                DataColumn(
                    label: Text('DATE', style: theme.textTheme.bodyMedium)),
                DataColumn(
                    label: Text('AMOUNT', style: theme.textTheme.bodyMedium)),
                DataColumn(
                    label: Text('STATUS', style: theme.textTheme.bodyMedium)),
              ],
              rows: [
                _buildDataRow(
                    context,
                    'JD',
                    'James D.',
                    'Mastering React 18',
                    'Oct 24, 2023',
                    '\$149.00',
                    'COMPLETED',
                    colorScheme.secondary,
                    colorScheme.secondaryContainer),
                _buildDataRow(
                    context,
                    'MS',
                    'Maria S.',
                    'UX Strategy Workshop',
                    'Oct 24, 2023',
                    '\$299.00',
                    'COMPLETED',
                    colorScheme.secondary,
                    colorScheme.secondaryContainer),
                _buildDataRow(
                    context,
                    'AL',
                    'Alex L.',
                    'Python for Analytics',
                    'Oct 23, 2023',
                    '\$89.00',
                    'PROCESSING',
                    colorScheme.primary,
                    colorScheme.primaryContainer),
              ],
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildDataRow(
      BuildContext context,
      String initials,
      String name,
      String course,
      String date,
      String amount,
      String status,
      Color statusColor,
      Color statusBg) {
    final colorScheme = Theme.of(context).colorScheme;
    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: Text(initials, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(width: 12),
            Text(name, style: theme.textTheme.bodyMedium),
          ],
        )),
        DataCell(Text(course, style: theme.textTheme.bodyMedium)),
        DataCell(Text(date, style: theme.textTheme.bodyMedium)),
        DataCell(Text(amount, style: theme.textTheme.bodyMedium)),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: theme.textTheme.bodyMedium,
          ),
        )),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final Color color;
  _LineChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.75,
        size.width * 0.2, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.3, size.height * 1.1,
        size.width * 0.4, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.1,
        size.width * 0.6, size.height * 0.25);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.4,
        size.width * 0.8, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.6, size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
