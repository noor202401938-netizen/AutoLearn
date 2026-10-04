import 'package:flutter/material.dart';
import '../../widgets/notebook/shell.dart';
import 'admin_pages.dart';
import 'admin_paths_page.dart';
import 'course_studio.dart';

const _sections = [
  ShellSection('Overview', Icons.insights_outlined),
  ShellSection('Courses', Icons.menu_book_outlined),
  ShellSection('Learning paths', Icons.route_outlined),
  ShellSection('People', Icons.people_outline),
  ShellSection('Payments', Icons.receipt_long_outlined),
  ShellSection('Announcements', Icons.campaign_outlined),
  ShellSection('Account', Icons.person_outline),
];

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) => NotebookShell(
        sections: _sections,
        index: _index,
        onSelect: _go,
        tagline: 'the teacher\'s edition',
        mobileTabs: const [0, 1, 3],
        page: switch (_index) {
          0 => AdminOverviewPage(onNavigate: _go),
          1 => const AdminCoursesPage(),
          2 => const AdminPathsPage(),
          3 => const AdminStudentsPage(),
          4 => const AdminPaymentsPage(),
          5 => const AdminAnnouncementsPage(),
          _ => const AdminAccountPage(),
        },
      );
}
