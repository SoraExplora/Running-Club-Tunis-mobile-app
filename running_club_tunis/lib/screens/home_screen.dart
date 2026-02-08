import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import 'notification_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isGuest;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final card = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: isGuest
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Logout visitor and return to splash
                  final authService = Provider.of<AuthService>(context, listen: false);
                  authService.logout();
                  Provider.of<ThemeService>(context, listen: false).reset();
                },
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/images/RCTCONNECT.png', height: 30),
              ),
        title: const Text("RCT Connect"),
        actions: [
          if (!isGuest)
            Consumer<AuthService>(
              builder: (context, auth, _) {
                final user = auth.currentUser;
                if (user == null || user.role != UserRole.member) return const SizedBox();
                return StreamBuilder<int>(
                  stream: Provider.of<NotificationService>(context, listen: false).getUnreadCount(user.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationListScreen(onToggleTheme: onToggleTheme),
                            ),
                          ),
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                '$count',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          IconButton(
            onPressed: onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // HERO
          _HeroCard(
            imagePath: 'assets/images/marathon_1.jpg',
            title: "Plus qu’un club…\nune famille.",
            subtitle:
                "Au RCT, la passion c’est la course à pied et le sport en général.",
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // ABOUT (French text you provided, polished)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bienvenue au RCT",
                  style: TextStyle(
                    color: textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Bienvenue sur le blog officiel de l’association sportive « Running Club Tunis ». "
                  "Au RCT, la passion, c’est la course à pied et le sport en général. "
                  "Courir est un sport accessible à tous ! Quel que soit votre niveau, "
                  "si vous êtes motivés pour pratiquer ce sport passionnant aux bienfaits multiples, "
                  "rejoignez-nous pour des séances de coaching adaptées à votre niveau ou personnalisées.\n\n"
                  "Running Club Tunis… Plus qu’un club… une famille.",
                  style: TextStyle(
                    color: textSub,
                    height: 1.45,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // WHAT WE DO
          Text(
            "Nos activités",
            style: TextStyle(
              color: textMain,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),

          _ActivityGrid(isDark: isDark),

          const SizedBox(height: 14),

          // GALLERY
          Text(
            "Moments RCT",
            style: TextStyle(
              color: textMain,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _GalleryItem(path: 'assets/images/marathon_1.jpg'),
                _GalleryItem(path: 'assets/images/marathon_2.jpg'),
                _GalleryItem(path: 'assets/images/marathon_3.jpg'),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // CTA
            Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rejoindre une séance",
                  style: TextStyle(
                    color: textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Consulte les séances d'aujourd'hui et les événements de ton groupe.",
                  style: TextStyle(
                    color: textSub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final bool isDark;

  const _HeroCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Image.asset(
            imagePath,
            height: 210,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.70),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ActivityGrid extends StatelessWidget {
  final bool isDark;
  const _ActivityGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fontScale = Provider.of<ThemeService>(context).fontScale;
    // Decrease aspect ratio more aggressively as font scale increases to prevent overflow
    // At 1.0 -> ~1.1
    // At 1.4 -> ~0.75 (much taller tiles)
    final double aspectRatio = 1.1 / (fontScale * fontScale).clamp(0.8, 2.0); 

    final card = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    Widget tile(IconData icon, String t, String s) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: textMain),
            ),
            const SizedBox(height: 10),
            Text(
              t,
              style: TextStyle(
                color: textMain,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s,
              style: TextStyle(
                color: textSub,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: aspectRatio,
      children: [
        tile(Icons.groups_2_outlined, "Groupes", "Plusieurs niveaux\npour tous."),
        tile(Icons.run_circle_outlined, "Coaching", "Séances adaptées\net progressives."),
        tile(Icons.event_available_outlined, "Événements", "Sorties longues\n+ courses officielles."),
        tile(Icons.favorite_border, "Santé", "Motivation, discipline\net bien-être."),
      ],
    );
  }
}

class _GalleryItem extends StatelessWidget {
  final String path;
  const _GalleryItem({required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(image: AssetImage(path), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.35),
            ],
          ),
        ),
      ),
    );
  }
}
