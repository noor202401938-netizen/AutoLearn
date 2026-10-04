import 'package:flutter/material.dart';
import '../../widgets/notebook/shell.dart';
import '../admin/admin_pages.dart' show AdminAccountPage;
import '../admin/course_studio.dart';
import 'teacher_pages.dart';

const _sections = [
  ShellSection('Overview', Icons.insights_outlined),
  ShellSection('My courses', Icons.menu_book_outlined),
  ShellSection('Marking', Icons.rate_review_outlined),
  ShellSection('Students', Icons.people_outline),
  ShellSection('Announcements', Icons.campaign_outlined),
  ShellSection('Account', Icons.person_outline),
];

/// The teacher's notebook: their own courses, marking queue and students.
class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) => NotebookShell(
        sections: _sections,
        index: _index,
        onSelect: _go,
        tagline: 'the teacher\'s desk',
        mobileTabs: const [0, 1, 2],
        page: switch (_index) {
          0 => TeacherOverviewPage(onNavigate: _go),
          1 => const AdminCoursesPage(mine: true),
          2 => const TeacherMarkingPage(),
          3 => const TeacherStudentsPage(),
          4 => const TeacherAnnouncementsPage(),
          _ => const AdminAccountPage(roleLabel: 'teacher'),
        },
      );
}
