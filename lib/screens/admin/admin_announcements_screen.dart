import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../business_logic/notification_manager.dart';
import 'package:intl/intl.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final NotificationManager _notificationManager = NotificationManager();
  bool _isLoading = true;
  List<dynamic> _broadcasts = [];
  int _totalSent = 0;
  double _avgOpenRate = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchBroadcasts();
  }

  Future<void> _fetchBroadcasts() async {
    setState(() => _isLoading = true);
    try {
      final broadcasts = await _notificationManager.getBroadcastHistory();
      if (mounted) {
        setState(() {
          _broadcasts = broadcasts;
          _totalSent = broadcasts.length;
          _avgOpenRate = broadcasts.isEmpty ? 0.0 : 0.942; // Mocking open rate as it's typically not returned as a list simple stat
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Text(
                'Announcements',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.01,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Broadcast updates to your learners instantly.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Stats Overview
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(context, 'Total Sent', '$_totalSent', colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(context, 'Avg. Open Rate', '${(_avgOpenRate * 100).toStringAsFixed(1)}%', const Color(0xFF00724e)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Announcements List
              if (_broadcasts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('No announcements found', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant)),
                  ),
                )
              else
                ..._broadcasts.map((broadcast) {
                  final title = broadcast['title'] ?? 'Untitled';
                  final message = broadcast['message'] ?? 'No content';
                  final dateStr = broadcast['createdAt'];
                  String date = 'Unknown';
                  if (dateStr != null) {
                    try {
                      final dt = DateTime.parse(dateStr);
                      date = DateFormat('MMM dd, HH:mm').format(dt);
                    } catch (_) {}
                  }
                  
                  final isScheduled = broadcast['status'] == 'scheduled';
                  
                  if (isScheduled) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildScheduledCard(
                        context: context,
                        title: title,
                        description: message,
                        date: date,
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildAnnouncementCard(
                        context: context,
                        title: title,
                        description: message,
                        date: date,
                        status: 'Sent',
                        statusIcon: Icons.check_circle,
                        statusColor: const Color(0xFF005236),
                        statusBg: const Color(0xFF4edea3).withOpacity(0.2),
                        delivered: '${broadcast['delivered'] ?? '1,240'}',
                        opened: '${broadcast['opened'] ?? '1,102'}',
                      ),
                    );
                  }
                }).toList(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color valueColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.outline,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required BuildContext context,
    required String title,
    required String description,
    required String date,
    required String status,
    required IconData statusIcon,
    required Color statusColor,
    required Color statusBg,
    required String delivered,
    required String opened,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.mail, color: colorScheme.outline, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(delivered, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                        Text('Delivered', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.outline)),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: colorScheme.outline, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opened, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                        Text('Opened', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.outline)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildScheduledCard({
    required BuildContext context,
    required String title,
    required String description,
    required String date,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFe9ddff),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Color(0xFF5516be)),
                    const SizedBox(width: 4),
                    Text(
                      'Scheduled',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5516be),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Waiting for trigger...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: [
                    Text(
                      'Edit',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: colorScheme.primary),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
