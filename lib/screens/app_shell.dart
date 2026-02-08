import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'home_screen.dart';
import 'guest_news_screen.dart';
import 'programs_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import '../widgets/notification_overlay.dart';
import '../services/app_tutorial.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';



class AppShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isGuest;
  final bool forceTutorial;

  const AppShell({
    super.key,
    required this.onToggleTheme,
    this.isGuest = false,
    this.forceTutorial = false,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final GlobalKey _kBottomNav = GlobalKey();
  final GlobalKey _kProfileTab = GlobalKey();
  bool _startProfileTutorial = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    if (widget.isGuest) {
      _pages = [
        HomeScreen(onToggleTheme: widget.onToggleTheme, isGuest: true),
        GuestNewsScreen(onToggleTheme: widget.onToggleTheme),
      ];
    } else {
      _pages = [
        HomeScreen(onToggleTheme: widget.onToggleTheme, isGuest: false),
        EventsScreen(onToggleTheme: widget.onToggleTheme),
        ProgramsScreen(onToggleTheme: widget.onToggleTheme),
        _PlaceholderPage(title: "Stats", onToggleTheme: widget.onToggleTheme),
        ProfileScreen(
          onToggleTheme: widget.onToggleTheme,
          onLogout: () => Navigator.popUntil(context, (route) => route.isFirst),
          startTutorial: _startProfileTutorial,
          onTutorialFinished: () => setState(() => _startProfileTutorial = false),
        ),
      ];
    }

    if (!widget.isGuest) {
      final authService = Provider.of<AuthService>(context, listen: false);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await AppTutorial().maybeStart(
          context: context,
          targets: _getTutorialTargets(),
          force: widget.forceTutorial,
        );
        if (widget.forceTutorial) {
          authService.clearJustRegistered();
        }
      });
    }
  }

  List<TargetFocus> _getTutorialTargets() {
    return <TargetFocus>[
      TargetFocus(
        identify: "nav",
        keyTarget: _kBottomNav,
        shape: ShapeLightFocus.RRect,
        radius: 18,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _TutorialCard(
                title: "Navigation",
                body: "Use the bottom bar to move through the app.",
                primaryText: "Continue",
                onPrimary: controller.next,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "profile",
        keyTarget: _kProfileTab,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _TutorialCard(
                title: "Profile & Accessibility",
                body: "Open Profile to personalize your UI/UX (Dark/Light + color-blind palettes).",
                primaryText: "Continue",
                onPrimary: () {
                  setState(() {
                    _index = 4; // Index of Profile
                    _startProfileTutorial = true;
                  });
                  controller.next();
                },
              );
            },
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!widget.isGuest) {
      _pages[4] = ProfileScreen(
        onToggleTheme: widget.onToggleTheme,
        onLogout: () => Navigator.popUntil(context, (route) => route.isFirst),
        startTutorial: _startProfileTutorial,
        onTutorialFinished: () => setState(() => _startProfileTutorial = false),
      );
    }

    return NotificationOverlayListener(
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _RCTBottomNav(
              key: _kBottomNav,
              currentIndex: _index,
              onChanged: (i) => setState(() => _index = i),
              isDark: isDark,
              isGuest: widget.isGuest,
              kProfile: _kProfileTab,
            ),
          ),
        ),
      ),
    );
  }
}

class _RCTBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final bool isGuest;
  final GlobalKey kProfile;

  const _RCTBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.isDark,
    required this.isGuest,
    required this.kProfile,
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

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: pill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),

          _NavIcon(
            selected: currentIndex == 0,
            icon: Icons.home_rounded,
            onTap: () => onChanged(0),
            iconOn: iconOn,
            iconOff: iconOff,
          ),

          // ✅ Guest: only 2 tabs (Home + News)
          if (isGuest) ...[
            _NavIcon(
              selected: currentIndex == 1,
              icon: Icons.article_outlined, // News
              onTap: () => onChanged(1),
              iconOn: iconOn,
              iconOff: iconOff,
            ),
          ] else ...[
            // ✅ Logged-in: 5 tabs
            _NavIcon(
              selected: currentIndex == 1,
              icon: Icons.event_note_rounded,
              onTap: () => onChanged(1),
              iconOn: iconOn,
              iconOff: iconOff,
            ),
             _NavIcon(
              selected: currentIndex == 2,
              icon: Icons.assignment_outlined,
              onTap: () => onChanged(2),
              iconOn: iconOn,
              iconOff: iconOff,
            ),
            _NavIcon(
              selected: currentIndex == 3,
              icon: Icons.bar_chart_rounded,
              onTap: () => onChanged(3),
              iconOn: iconOn,
              iconOff: iconOff,
            ),
            KeyedSubtree(
              key: kProfile,
              child: _NavIcon(
                selected: currentIndex == 4,
                icon: Icons.person_rounded,
                onTap: () => onChanged(4),
                iconOn: iconOn,
                iconOff: iconOff,
              ),
            ),
          ],

          const SizedBox(width: 8),
        ],
      ),
    );
  }
}



class _NavIcon extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  final Color iconOn;
  final Color iconOff;

  const _NavIcon({
    required this.selected,
    required this.icon,
    required this.onTap,
    required this.iconOn,
    required this.iconOff,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: selected ? iconOn : iconOff, size: 24),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final VoidCallback onToggleTheme;
  const _PlaceholderPage({required this.title, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final String title;
  final String body;
  final String primaryText;
  final VoidCallback onPrimary;

  const _TutorialCard({
    required this.title,
    required this.body,
    required this.primaryText,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final card = theme.cardTheme.color ?? (isDark ? const Color(0xFF1C1C1C) : Colors.white);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.86,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onPrimary,
                child: Text(primaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

