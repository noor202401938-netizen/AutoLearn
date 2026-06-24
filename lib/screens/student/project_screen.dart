import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assignment_screen.dart';

class ProjectScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const ProjectScreen({
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
                    flex: isDesktop ? 4 : 0,
                    child: Column(
                      children: [
                        // Brief Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4231C0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  'CAPSTONE PROJECT',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF4231C0),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Autonomous Drone Navigation System',
                                style: GoogleFonts.geist(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF121C2A),
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Develop an AI-driven navigation module capable of obstacle avoidance and path optimization in dynamic urban environments.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF474554),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuANW3-bQ_ummKOuxbZbbaqFe7slSRnrAmV9727pLAaoZgFuWbzjdj04qyrOro56CWjzT1nKJUxMKjJhRIs0NwheQqU6D3EbzTyLWXjVlgDQ6I_8hOGOL6Lg6m26MXAWIfol00hDGo13pXVNcwIHX-9vFCdRZ5OoJmyyw_Sr_g9-zC3F-xIXjTSOx8upU-K5DtheUbbJhT_Nc4-gnxGmtzm5bSaTbZyTSTnnEsCTeObzW6oCR5U4FkY-asp5_N0djxb3AbFhpOQ-crah'),
                                      Transform.translate(offset: const Offset(-10, 0), child: _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuDHm8JbTo9OcYfnih0U3VYPDE47W6BnEALpLQrsl4iLUjvLpEyVa-fEyxmXgdWSOfefEBw7Heibg6dZX1tkUv9MPcY3zLhYfbeIN35yKmKVaJceFtxtwfNwOvLzMsJBQKL9fpwRqMTdIODqM-OppVY9FDWGlFZJ1gLTsEuER40oQw-aQjYJIZbDTtzBrZlfTXRPRgt-eGis330MCgCrFNC5oMtLuJ6XX7FQQaiZ1p-VAdUqEaU5tg7ds81LB-iT-vh0Eku-3mXBpcSC')),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Team Delta', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Project Brief list
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PROJECT BRIEF', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF787586), letterSpacing: 1.5)),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.description, color: Color(0xFF4231C0), size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Objectives', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text('• Real-time sensor fusion processing', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
                                        Text('• LIDAR-based mapping algorithm', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
                                        Text('• Battery-efficient flight paths', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0xFF4231C0), size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Deadline', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text('November 24, 2024 (12 Days Left)', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
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
                        // Progress
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                justifyAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Overall Completion', style: GoogleFonts.geist(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF121C2A))),
                                  Text('65%', style: GoogleFonts.geist(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF00573A))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6EEFF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: 0.65,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF00573A), Color(0xFF4EDEA3)]),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Grid
                        GridView.count(
                          crossAxisCount: isDesktop ? 2 : 1,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: isDesktop ? 2 : 3,
                          children: [
                            _buildMilestoneCard(
                              title: 'Planning & Research',
                              subtitle: 'Market analysis and hardware specification selection completed.',
                              phase: 'Phase 1',
                              isDone: true,
                            ),
                            _buildMilestoneCard(
                              title: 'System Design',
                              subtitle: 'Architecture diagrams and API schema finalized.',
                              phase: 'Phase 2',
                              isDone: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildActiveMilestoneCard(),
                        const SizedBox(height: 24),
                        // Submit Final Project
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
                                  builder: (context) => AssignmentScreen(
                                    courseId: courseId,
                                    courseTitle: courseTitle,
                                    moduleId: \'project\',
                                    moduleTitle: \'Final Project\',
                                    lessonId: \'project_\',
                                    lessonTitle: \'Final Project: \',
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Submit Final Project', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                const Icon(Icons.send, color: Colors.white, size: 20),
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
    );
  }

  Widget _buildAvatar(String url) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMilestoneCard({required String title, required String subtitle, required String phase, required bool isDone}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFF00573A), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF00573A), size: 20),
              Text(phase, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF00573A))),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF121C2A))),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF474554))),
        ],
      ),
    );
  }

  Widget _buildActiveMilestoneCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: Color(0xFF4231C0), width: 4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4231C0).withOpacity(0.05),
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
                  const Icon(Icons.hourglass_top, color: Color(0xFF4231C0), size: 20),
                  const SizedBox(width: 8),
                  Text('PHASE 3: IMPLEMENTATION (CURRENT)', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF4231C0))),
                ],
              ),
              Text('In Progress', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4231C0))),
            ],
          ),
          const SizedBox(height: 24),
          Text('Core Navigation Logic', style: GoogleFonts.geist(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF121C2A))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LIDAR Integration', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
              Text('Done', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF00573A))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pathfinding AI Model', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4231C0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Training...', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
