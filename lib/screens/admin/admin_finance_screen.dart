import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminFinanceScreen extends StatelessWidget {
  const AdminFinanceScreen({super.key});

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
              // Net Revenue Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4231c0), Color(0xFF6b38d4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4231c0).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
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
                              'NET REVENUE',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$142,850.00',
                              style: GoogleFonts.geist(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.03,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6ffbbe),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up, size: 16, color: Color(0xFF002113)),
                              const SizedBox(width: 4),
                              Text(
                                '+24.8%',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF002113),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6ffbbe),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live data updated 2m ago',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Secondary Stats
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 600;
                  return Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    children: [
                      Expanded(flex: isDesktop ? 1 : 0, child: _buildSecondaryStat('TRANSACTIONS', '1,284', '12%', true)),
                      if (isDesktop) const SizedBox(width: 16),
                      if (!isDesktop) const SizedBox(height: 16),
                      Expanded(flex: isDesktop ? 1 : 0, child: _buildSecondaryStat('AVG ORDER', '\$111.25', '5%', true)),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),

              // Revenue Trends Chart
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC8C4D7)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Revenue Trends',
                          style: GoogleFonts.geist(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF121c2a),
                            letterSpacing: -0.01,
                          ),
                        ),
                        Text(
                          'LAST 6 MONTHS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF474554),
                            letterSpacing: 0.05,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 150,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBar('JAN', 0.4),
                          _buildBar('FEB', 0.55),
                          _buildBar('MAR', 0.48),
                          _buildBar('APR', 0.72),
                          _buildBar('MAY', 0.85),
                          _buildBar('JUN', 1.0),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.geist(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121c2a),
                      letterSpacing: -0.01,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4231c0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildTransactionItem(
                name: 'Alex Rivers',
                txId: '#TXN-89421',
                amount: '\$299.00',
                status: 'SUCCESS',
                statusColor: const Color(0xFF005236),
                statusBg: const Color(0xFF4edea3).withOpacity(0.2),
              ),
              const SizedBox(height: 12),
              _buildTransactionItem(
                name: 'Jordan Smith',
                txId: '#TXN-89422',
                amount: '\$149.50',
                status: 'PENDING',
                statusColor: const Color(0xFF474554),
                statusBg: const Color(0xFFdee9fc),
              ),
              const SizedBox(height: 12),
              _buildTransactionItem(
                name: 'Maria Garcia',
                txId: '#TXN-89423',
                amount: '\$45.00',
                status: 'REFUNDED',
                statusColor: const Color(0xFF93000a),
                statusBg: const Color(0xFFffdad6),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryStat(String title, String value, String change, bool isUp) {
    return Container(
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
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF474554),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.geist(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4231c0),
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isUp ? Icons.expand_less : Icons.expand_more, size: 14, color: const Color(0xFF00573a)),
              const SizedBox(width: 4),
              Text(
                change,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF00573a),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBar(String label, double fillPercent) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5b4ed9).withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: fillPercent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5b4ed9),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF474554),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String name,
    required String txId,
    required String amount,
    required String status,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF5b4ed9).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Color(0xFF4231c0)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF121c2a),
                    ),
                  ),
                  Text(
                    txId,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF474554),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF121c2a),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
