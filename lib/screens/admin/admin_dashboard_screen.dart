import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                'Admin Dashboard',
                style: GoogleFonts.geist(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121c2a),
                  letterSpacing: -0.01,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time performance overview',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF474554),
                ),
              ),
              const SizedBox(height: 24),
              
              // Executive Stats Bento Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  return Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    children: [
                      // Revenue Card
                      Expanded(
                        flex: isDesktop ? 2 : 0,
                        child: _buildRevenueCard(),
                      ),
                      if (isDesktop) const SizedBox(width: 16),
                      if (!isDesktop) const SizedBox(height: 16),
                      // Row of Active Users and Completion Rate
                      Expanded(
                        flex: isDesktop ? 3 : 0,
                        child: Row(
                          children: [
                            Expanded(child: _buildActiveUsersCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildCompletionRateCard()),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              ),
              const SizedBox(height: 32),
              
              // System Activity Feed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'System Activity',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF121c2a),
                      letterSpacing: 0.02,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'VIEW ALL',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4231c0),
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              _buildActivityItem(
                icon: Icons.school,
                iconColor: const Color(0xFF6b38d4),
                iconBg: const Color(0xFF6b38d4).withOpacity(0.1),
                title: 'New Course Published',
                subtitle: 'Advanced React Design Patterns',
                time: '2M AGO',
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                icon: Icons.person_add,
                iconColor: const Color(0xFF00573a),
                iconBg: const Color(0xFF00573a).withOpacity(0.1),
                title: 'New Admin Invited',
                subtitle: 'sarah.j@autolearn.com',
                time: '1H AGO',
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                icon: Icons.payments,
                iconColor: const Color(0xFF4231c0),
                iconBg: const Color(0xFF4231c0).withOpacity(0.1),
                title: 'Bulk Payout Processed',
                subtitle: '24 instructors cleared',
                time: '4H AGO',
              ),
              
              const SizedBox(height: 100), // Space for FAB/BottomNav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
      ),
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
                  Text(
                    'TOTAL REVENUE',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF474554),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$124,592.00',
                    style: GoogleFonts.geist(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4231c0),
                      letterSpacing: -0.02,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4edea3).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: Color(0xFF00573a)),
                    const SizedBox(width: 4),
                    Text(
                      '12%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00573a),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mock Line Chart
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE USERS',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF474554),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '18.4k',
                style: GoogleFonts.geist(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121c2a),
                  letterSpacing: -0.01,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '+4.2%',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00573a),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildOverlapAvatar(Colors.grey[200]!, null),
              Transform.translate(offset: const Offset(-8, 0), child: _buildOverlapAvatar(Colors.grey[300]!, null)),
              Transform.translate(offset: const Offset(-16, 0), child: _buildOverlapAvatar(Colors.grey[400]!, null)),
              Transform.translate(offset: const Offset(-24, 0), child: _buildOverlapAvatar(const Color(0xFF5b4ed9), '+12', textColor: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRateCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMPLETION',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF474554),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '84.2%',
                style: GoogleFonts.geist(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121c2a),
                  letterSpacing: -0.01,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '-2.1%',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFba1a1a),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFe6eeff),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.842,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4edea3), Color(0xFF00724e)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlapAvatar(Color color, String? text, {Color? textColor}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: text != null
          ? Text(
              text,
              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: textColor),
            )
          : null,
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF121c2a),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF474554),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF474554),
              letterSpacing: 0.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5b4ed9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.125, size.height * 0.4, size.width * 0.25, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.3, size.width * 0.75, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.2, size.width, size.height * 0.2);
    
    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF5b4ed9).withOpacity(0.2),
          const Color(0xFF5b4ed9).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
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
