import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                        style: GoogleFonts.geist(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF121c2a),
                          letterSpacing: -0.02,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time performance metrics across all learning verticals.',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFF474554),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildControlButton('Last 30 Days', Icons.calendar_today),
                      const SizedBox(width: 12),
                      _buildControlButton('Export Reports', Icons.file_download),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),

              // Key Metrics Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  return GridView.count(
                    crossAxisCount: isDesktop ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 1.5 : 1.2,
                    children: [
                      _buildMetricCard(
                        title: 'Total Revenue',
                        value: '\$2,482,900',
                        badgeText: '12.5%',
                        badgeIcon: Icons.trending_up,
                        badgeColor: const Color(0xFF00724e),
                        badgeBg: const Color(0xFF6ffbbe),
                        bottomWidget: _buildMockLineChart(),
                      ),
                      _buildMetricCard(
                        title: 'Active Enrollments',
                        value: '45,120',
                        badgeText: '8.2%',
                        badgeIcon: Icons.trending_up,
                        badgeColor: const Color(0xFF00724e),
                        badgeBg: const Color(0xFF6ffbbe),
                        bottomWidget: Text('Across 128 courses', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
                      ),
                      _buildMetricCard(
                        title: 'Completion Rate',
                        value: '78.4%',
                        badgeText: '0.4%',
                        badgeIcon: Icons.trending_down,
                        badgeColor: const Color(0xFFba1a1a),
                        badgeBg: const Color(0xFFffdad6),
                        bottomWidget: _buildProgressBar(0.784),
                      ),
                      _buildMetricCard(
                        title: 'Net Promoter Score',
                        value: '72 / 100',
                        badgeText: 'Target Met',
                        badgeIcon: Icons.check_circle,
                        badgeColor: const Color(0xFF00724e),
                        badgeBg: const Color(0xFF6ffbbe),
                        bottomWidget: Text('Calculated from 12k reviews', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
                      ),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),

              // Main Analytics Visualization & Side Panel
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 900;
                  return Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: isDesktop ? 2 : 0,
                        child: _buildBarChartSection(isDesktop),
                      ),
                      if (isDesktop) const SizedBox(width: 24),
                      if (!isDesktop) const SizedBox(height: 24),
                      Expanded(
                        flex: isDesktop ? 1 : 0,
                        child: _buildTopCoursesSection(isDesktop),
                      ),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),

              // Detailed Reports Table
              _buildRecentConversionsTable(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFdee9fc),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF121c2a)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF121c2a),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String badgeText,
    required IconData badgeIcon,
    required Color badgeColor,
    required Color badgeBg,
    required Widget bottomWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFc8c4d7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF474554),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          Text(
            value,
            style: GoogleFonts.geist(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121c2a),
            ),
          ),
          bottomWidget,
        ],
      ),
    );
  }

  Widget _buildMockLineChart() {
    return SizedBox(
      height: 32,
      child: CustomPaint(
        size: const Size(double.infinity, 32),
        painter: _LineChartPainter(),
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFd9e3f6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00724e), Color(0xFF4edea3)]),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartSection(bool isDesktop) {
    return Container(
      height: 450,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFc8c4d7)),
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
                    style: GoogleFonts.geist(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121c2a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monthly breakdown of new signups and average session hours.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF474554),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem('Signups', const Color(0xFF4231c0)),
                  const SizedBox(width: 16),
                  _buildLegendItem('Engagement', const Color(0xFF8455ef)),
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
                _buildDoubleBar('JAN', 0.4, 0.6),
                _buildDoubleBar('FEB', 0.55, 0.7),
                _buildDoubleBar('MAR', 0.75, 0.65),
                _buildDoubleBar('APR', 0.65, 0.85),
                _buildDoubleBar('MAY', 0.9, 0.8),
                _buildDoubleBar('JUN', 0.85, 0.95),
                _buildDoubleBar('JUL', 1.0, 0.9),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
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
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121c2a),
          ),
        ),
      ],
    );
  }

  Widget _buildDoubleBar(String label, double fill1, double fill2) {
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
                  decoration: const BoxDecoration(
                    color: Color(0xFF4231c0),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              FractionallySizedBox(
                heightFactor: fill2,
                child: Container(
                  width: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8455ef),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF474554),
          ),
        ),
      ],
    );
  }

  Widget _buildTopCoursesSection(bool isDesktop) {
    return Container(
      height: isDesktop ? 450 : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFc8c4d7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performing Courses',
            style: GoogleFonts.geist(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121c2a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ranked by conversion & engagement.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF474554),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: isDesktop ? 1 : 0,
            child: ListView(
              shrinkWrap: !isDesktop,
              physics: isDesktop ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
              children: [
                _buildCourseItem('Full-Stack Dev Mastery', '14.2%', '2.4k Students', Icons.terminal, const Color(0xFFc5c0ff), const Color(0xFF4231c0)),
                const SizedBox(height: 16),
                _buildCourseItem('AI Ethics & Implementation', '12.8%', '1.9k Students', Icons.psychology, const Color(0xFFe9ddff), const Color(0xFF6b38d4)),
                const SizedBox(height: 16),
                _buildCourseItem('Advanced UI Design Systems', '11.5%', '3.1k Students', Icons.design_services, const Color(0xFF4edea3), const Color(0xFF00573a)),
                const SizedBox(height: 16),
                _buildCourseItem('Data Science Foundations', '9.8%', '1.2k Students', Icons.monitoring, const Color(0xFFd9e3f6), const Color(0xFF474554)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCourseItem(String title, String conversion, String students, IconData icon, Color iconBg, Color iconColor) {
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF121c2a),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'CONVERSION: $conversion',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00724e),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.circle, size: 4, color: Color(0xFFc8c4d7)),
                    ),
                    Text(
                      students,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF474554),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF4231c0)),
        ],
      ),
    );
  }

  Widget _buildRecentConversionsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFc8c4d7)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Conversions',
                  style: GoogleFonts.geist(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121c2a),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All Transactions',
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
          const Divider(height: 1, color: Color(0xFFc8c4d7)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFeff4ff)),
              columns: [
                DataColumn(label: Text('STUDENT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF474554)))),
                DataColumn(label: Text('COURSE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF474554)))),
                DataColumn(label: Text('DATE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF474554)))),
                DataColumn(label: Text('AMOUNT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF474554)))),
                DataColumn(label: Text('STATUS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF474554)))),
              ],
              rows: [
                _buildDataRow('JD', 'James D.', 'Mastering React 18', 'Oct 24, 2023', '\$149.00', 'COMPLETED', const Color(0xFF00724e), const Color(0xFF6ffbbe)),
                _buildDataRow('MS', 'Maria S.', 'UX Strategy Workshop', 'Oct 24, 2023', '\$299.00', 'COMPLETED', const Color(0xFF00724e), const Color(0xFF6ffbbe)),
                _buildDataRow('AL', 'Alex L.', 'Python for Analytics', 'Oct 23, 2023', '\$89.00', 'PROCESSING', const Color(0xFF5516be), const Color(0xFFe9ddff)),
              ],
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildDataRow(String initials, String name, String course, String date, String amount, String status, Color statusColor, Color statusBg) {
    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4231c0).withOpacity(0.1),
              child: Text(initials, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4231c0))),
            ),
            const SizedBox(width: 12),
            Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF121c2a))),
          ],
        )),
        DataCell(Text(course, style: GoogleFonts.inter(fontSize: 14))),
        DataCell(Text(date, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554)))),
        DataCell(Text(amount, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          )
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4231c0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.75, size.width * 0.2, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.3, size.height * 1.1, size.width * 0.4, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width * 0.6, size.height * 0.25);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.4, size.width * 0.8, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.6, size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
