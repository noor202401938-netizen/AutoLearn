import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminCoursesScreen extends StatelessWidget {
  const AdminCoursesScreen({super.key});

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
              // Dashboard Header
              Text(
                'Course Management',
                style: GoogleFonts.geist(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121c2a),
                  letterSpacing: -0.01,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and organize your learning curriculum.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF474554),
                ),
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFeff4ff),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFFc8c4d7)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF787586)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', true),
                    const SizedBox(width: 8),
                    _buildFilterChip('Published', false),
                    const SizedBox(width: 8),
                    _buildFilterChip('Drafts', false),
                    const SizedBox(width: 8),
                    _buildFilterChip('Archived', false),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Courses List Grid for Desktop / List for Mobile
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  return GridView.count(
                    crossAxisCount: isDesktop ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 3 : 2.5,
                    children: [
                      _buildCourseCard(
                        title: 'Advanced React Patterns',
                        status: 'PUBLISHED',
                        statusBg: const Color(0xFF6ffbbe),
                        statusColor: const Color(0xFF002113),
                        enrolled: '1,284',
                        progress: 0.85,
                      ),
                      _buildCourseCard(
                        title: 'UI/UX Strategy 2024',
                        status: 'DRAFT',
                        statusBg: const Color(0xFFe9ddff),
                        statusColor: const Color(0xFF23005c),
                        enrolled: '0',
                        progress: 0.0,
                        isDraft: true,
                      ),
                      _buildCourseCard(
                        title: 'Backend Architecture',
                        status: 'PUBLISHED',
                        statusBg: const Color(0xFF6ffbbe),
                        statusColor: const Color(0xFF002113),
                        enrolled: '2,540',
                        progress: 0.92,
                      ),
                      _buildCourseCard(
                        title: 'Legacy Content Strategy',
                        status: 'ARCHIVED',
                        statusBg: const Color(0xFFffdad6),
                        statusColor: const Color(0xFF93000a),
                        enrolled: '450',
                        progress: 1.0,
                        isArchived: true,
                      ),
                    ],
                  );
                }
              ),

              const SizedBox(height: 100), // Space for FAB/Nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF5b4ed9) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? const Color(0xFF5b4ed9) : const Color(0xFFC8C4D7)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF474554),
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required String title,
    required String status,
    required Color statusBg,
    required Color statusColor,
    required String enrolled,
    required double progress,
    bool isDraft = false,
    bool isArchived = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Image / Thumbnail area
          Container(
            width: 100,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFd9e3f6),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(8),
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.geist(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF121c2a),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Color(0xFF474554)),
                          const SizedBox(width: 4),
                          Text(
                            '$enrolled Enrolled',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF474554),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: isDraft
                            ? Text('Drafting in progress...', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF787586), fontStyle: FontStyle.italic, fontWeight: FontWeight.bold))
                            : isArchived
                                ? Text('Access Restricted', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF787586), fontWeight: FontWeight.bold))
                                : Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFe6eeff),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: progress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFF4edea3), Color(0xFF00724e)]),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.chevron_right, color: Color(0xFF4231c0)),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
