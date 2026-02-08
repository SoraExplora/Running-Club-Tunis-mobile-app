import 'package:flutter/material.dart';

import 'admin_users_screen.dart';
import 'admin_roles_screen.dart';
import 'admin_programs_screen.dart';
import 'admin_group_screen.dart';
import 'admin_events_screen.dart';
import '../profile_screen.dart';
import '../../models/user_model.dart';

class AdminShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final UserModel currentUser;

  final bool isCoach;
  final bool isGroupAdmin;

  const AdminShell({
    super.key,
    required this.onToggleTheme,
    required this.currentUser,
    this.isCoach = false,
    this.isGroupAdmin = false,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    if (widget.isGroupAdmin) {
      // 👇 GROUP ADMIN
      _pages = [
        AdminGroupScreen(onToggleTheme: widget.onToggleTheme, currentUser: widget.currentUser),
        AdminEventsScreen(onToggleTheme: widget.onToggleTheme, currentUser: widget.currentUser),
        ProfileScreen(
          onToggleTheme: widget.onToggleTheme,
          onLogout: () => Navigator.popUntil(context, (r) => r.isFirst),
          startTutorial: false,
          onTutorialFinished: () {},
        ),
      ];
    } else if (widget.isCoach) {
      // 👇 COACH ADMIN
      _pages = [
        AdminProgramsScreen(
          onToggleTheme: widget.onToggleTheme,
          currentUser: widget.currentUser,
        ),
        ProfileScreen(
          onToggleTheme: widget.onToggleTheme,
          onLogout: () => Navigator.popUntil(context, (r) => r.isFirst),
          startTutorial: false,
          onTutorialFinished: () {},
        ),
      ];
    } else {
      // 👇 MAIN ADMIN
      _pages = [
        AdminUsersScreen(onToggleTheme: widget.onToggleTheme),
        AdminRolesScreen(onToggleTheme: widget.onToggleTheme),
        AdminProgramsScreen(
          onToggleTheme: widget.onToggleTheme,
          currentUser: widget.currentUser,
        ),
        AdminEventsScreen(onToggleTheme: widget.onToggleTheme, currentUser: widget.currentUser),
        ProfileScreen(
          onToggleTheme: widget.onToggleTheme,
          onLogout: () => Navigator.popUntil(context, (r) => r.isFirst),
          startTutorial: false,
          onTutorialFinished: () {},
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _AdminBottomNav(
              currentIndex: _index,
              onChanged: (i) => setState(() => _index = i),
              isDark: isDark,
              isCoach: widget.isCoach,
              isGroupAdmin: widget.isGroupAdmin,
            ),
          ),
        ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final bool isCoach;
  final bool isGroupAdmin;

  const _AdminBottomNav({
    required this.currentIndex,
    required this.onChanged,
    required this.isDark,
    required this.isCoach,
    required this.isGroupAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final pill = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final iconOn = isDark ? Colors.white : Colors.black;
    final iconOff =
        isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.45);

    Widget icon(int i, IconData ic) => Expanded(
          child: IconButton(
            onPressed: () => onChanged(i),
            icon: Icon(ic, color: currentIndex == i ? iconOn : iconOff),
          ),
        );

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: pill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),

          if (isGroupAdmin) ...[
            icon(0, Icons.group),
            icon(1, Icons.event_note),
            icon(2, Icons.person),
          ] else if (isCoach) ...[
            icon(0, Icons.fitness_center),
            icon(1, Icons.person),
          ] else ...[
            icon(0, Icons.people_outline),
            icon(1, Icons.admin_panel_settings_outlined),
            icon(2, Icons.fitness_center_outlined),
            icon(3, Icons.event_note_outlined),
            icon(4, Icons.person_rounded),
          ],

          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
