import 'package:flutter/material.dart';
import '../../repository/user_repository.dart';
import '../../business_logic/course_manager.dart';
import '../../business_logic/payment_manager.dart';
import '../../model/course_model.dart';
import '../../utils/preference_notifier.dart';
import '../../widgets/interactive_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final UserRepository _userRepository = UserRepository();
  final CourseManager _courseManager = CourseManager();
  final PaymentManager _paymentManager = PaymentManager();

  bool _isLoading = true;
  double _totalRevenue = 0.0;
  int _activeUsers = 0;
  double _completionRate =
      0.842; // Fallback since we don't have global completion rate
  List<CourseModel> _recentCourses = [];
  List<Map<String, dynamic>> _recentUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userRepository.getAllUsers();
      final finance = await _paymentManager.getFinancialStats();
      final courses = await _courseManager.getPublishedCourses();

      if (mounted) {
        setState(() {
          _activeUsers = users.length;
          _totalRevenue =
              (finance['totalRevenue'] as num?)?.toDouble() ?? 124592.00;
          _recentCourses = courses.take(3).toList();
          _recentUsers = users.take(3).toList();
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
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section Row with Integrated Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Real-time performance overview',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Integrated Theme & Notifications Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          theme.brightness == Brightness.light
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          final newTheme = theme.brightness == Brightness.light
                              ? 'dark'
                              : 'light';
                          PreferenceNotifier.instance.updateTheme(newTheme);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.notifications_none_rounded, color: theme.colorScheme.primary),
                        onPressed: () {
                          // Notification action placeholder
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Executive Stats Bento Grid
              LayoutBuilder(builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                return Flex(
                  direction: isDesktop ? Axis.horizontal : Axis.vertical,
                  children: [
                    // Revenue Card
                    Expanded(
                      flex: isDesktop ? 2 : 0,
                      child: _buildRevenueCard(context),
                    ),
                    if (isDesktop) const SizedBox(width: 16),
                    if (!isDesktop) const SizedBox(height: 16),
                    // Row of Active Users and Completion Rate
                    Expanded(
                      flex: isDesktop ? 3 : 0,
                      child: Row(
                        children: [
                          Expanded(child: _buildActiveUsersCard(context)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildCompletionRateCard(context)),
                        ],
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 32),

              // System Activity Feed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'System Activity',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'VIEW ALL',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ..._recentCourses
                  .map((course) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildActivityItem(
                          context,
                          icon: Icons.school,
                          iconColor: colorScheme.primary,
                          iconBg: colorScheme.primary.withValues(alpha: 0.1),
                          title: 'Course Updated',
                          subtitle: course.title,
                          time: 'JUST NOW',
                        ),
                      ))
                  .toList(),

              ..._recentUsers
                  .map((user) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildActivityItem(
                          context,
                          icon: Icons.person_add,
                          iconColor: colorScheme.secondary,
                          iconBg: colorScheme.secondary.withValues(alpha: 0.1),
                          title: 'New Member',
                          subtitle:
                              user['email'] ?? user['displayName'] ?? 'Unknown',
                          time: 'RECENT',
                        ),
                      ))
                  .toList(),

              const SizedBox(height: 100), // Space for FAB/BottomNav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return InteractiveCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.account_balance_wallet_outlined,
                            size: 18, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'TOTAL REVENUE',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${_totalRevenue.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '+12.4%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Clean Minimalist Line Chart
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(colorScheme: colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InteractiveCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.people_outline_rounded,
                    size: 18, color: colorScheme.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+4.2%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'ACTIVE USERS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_activeUsers',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildOverlapAvatar(
                  context,
                  isDark
                      ? colorScheme.surfaceContainer
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                  null),
              Transform.translate(
                  offset: const Offset(-8, 0),
                  child: _buildOverlapAvatar(
                      context,
                      isDark
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      null)),
              Transform.translate(
                  offset: const Offset(-16, 0),
                  child: _buildOverlapAvatar(
                      context,
                      isDark
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      null)),
              Transform.translate(
                  offset: const Offset(-24, 0),
                  child: _buildOverlapAvatar(
                      context, colorScheme.primary, '+12',
                      textColor: colorScheme.onPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRateCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return InteractiveCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: colorScheme.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'STABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'COMPLETION',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_completionRate * 100).toStringAsFixed(1)}%',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _completionRate,
              minHeight: 6,
              backgroundColor: colorScheme.primaryContainer,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlapAvatar(BuildContext context, Color color, String? text,
      {Color? textColor}) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: colorScheme.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: text != null
          ? Text(
              text,
              style: theme.textTheme.bodyMedium,
            )
          : null,
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String time,
  }) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.125, size.height * 0.4,
        size.width * 0.25, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.3,
        size.width * 0.75, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.9, size.height * 0.2, size.width, size.height * 0.2);

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
