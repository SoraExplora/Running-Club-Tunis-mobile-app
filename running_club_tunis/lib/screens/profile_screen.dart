import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // storage removed as requested
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/accessibility_settings_sheet.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import 'notification_list_screen.dart';
import 'personal_screen.dart';


class ProfileScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;
  final bool startTutorial;
  final VoidCallback onTutorialFinished;

  const ProfileScreen({
    super.key,
    required this.onToggleTheme,
    required this.onLogout,
    required this.startTutorial,
    required this.onTutorialFinished,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey _kThemeBtn = GlobalKey();
  final GlobalKey _kCustomizeTile = GlobalKey();
  bool _didRun = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.startTutorial && !_didRun) {
      _didRun = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTutorial());
    }
  }

  void _startTutorial() {
    final targets = <TargetFocus>[
      TargetFocus(
        identify: "theme",
        keyTarget: _kThemeBtn,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _TutorialCard(
                title: "Dark / Light Mode",
                body: "Switch themes anytime for comfort and better visibility.",
                primaryText: "Continue",
                onPrimary: controller.next,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "customize",
        keyTarget: _kCustomizeTile,
        shape: ShapeLightFocus.RRect,
        radius: 18,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _TutorialCard(
                title: "Customize your UI/UX",
                body: "Personalize the app based on your preferences or needs: 4 color-blind friendly palettes + accessible visuals.",
                primaryText: "Finish",
                onPrimary: controller.next,
              );
            },
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.78,
      paddingFocus: 10,
      textSkip: "Skip",
      onFinish: widget.onTutorialFinished,
      onSkip: () {
        widget.onTutorialFinished();
        return true;
      },
    ).show(context: context);
  }


  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final card = theme.cardTheme.color ?? (isDark ? const Color(0xFF1C1C1C) : Colors.white);
    final border = theme.dividerColor;
    final textMain = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final textSub = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : Colors.black54);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/RCTCONNECT.png', height: 30),
        ),
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (user != null && user.role == UserRole.member)
            StreamBuilder<int>(
              stream: Provider.of<NotificationService>(context, listen: false).getUnreadCount(user.id),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationListScreen(onToggleTheme: widget.onToggleTheme),
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
            ),
          IconButton(
            key: _kThemeBtn,
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Top profile card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                // Avatar + edit
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: primaryColor.withValues(alpha: 0.25),
                      backgroundImage: _getImageProvider(user?.photoUrl),
                      child: _getImageProvider(user?.photoUrl) == null
                          ? const Icon(Icons.person, size: 46)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {
                          if (user != null) _openEditProfile(context, user);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.black : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  user?.name ?? "Runner",
                  style: TextStyle(
                    fontSize: 20 * (theme.textTheme.bodyLarge?.fontSize ?? 16) / 16,
                    fontWeight: FontWeight.w900,
                    color: textMain,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Options list
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                _OptionTile(
                  icon: Icons.badge_outlined,
                  title: "Personal",
                  subtitle: "Name, group, and account details",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonalScreen(onToggleTheme: widget.onToggleTheme),
                      ),
                    );
                  },
                ),
                _DividerLine(color: border),

                _OptionTile(
                  key: _kCustomizeTile,
                  icon: Icons.palette_outlined,
                  title: "Customize",
                  subtitle: "Color blindness modes & text size",
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AccessibilitySettingsSheet(),
                    );
                  },
                ),
                _DividerLine(color: border),


                _OptionTile(
                  icon: Icons.verified_user_outlined,
                  title: "Rules & agreements",
                  subtitle: "Club charter, guidelines, and terms",
                  onTap: () => _toast(context, "Rules & agreements (UI only)"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Logout button
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                auth.logout();
                Provider.of<ThemeService>(context, listen: false).reset();
              },
              child: const Text(
                "Logout",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              "RCT • Running Club Tunis",
              style: TextStyle(
                color: textSub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openEditProfile(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditProfileDialog(user: user),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final UserModel user;
  const _EditProfileDialog({required this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameController;
  Uint8List? _webImageBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Compress aggressively: max 400px, quality 70 (keep size low for Firestore)
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 400, 
      maxHeight: 400,
      imageQuality: 70,
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _webImageBytes = bytes;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      String? newPhotoUrl = widget.user.photoUrl;

      // Convert to Base64 String if new image selected
      if (_webImageBytes != null) {
        final base64String = base64Encode(_webImageBytes!);
        // Prefix helps identify it as a data URL later
        newPhotoUrl = "data:image/jpeg;base64,$base64String";
      }

      await FirebaseFirestore.instance.collection('user').doc(widget.user.id).update({
        'name': newName,
        'photoUrl': newPhotoUrl,
      });

      if (mounted) {
         Provider.of<AuthService>(context, listen: false).refreshUser();
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
        debugPrint(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Profile"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 20),
            const Text("Profile Picture", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _webImageBytes != null 
                    ? MemoryImage(_webImageBytes!) 
                    // Use helper for existing image
                    : _getImageProvider(widget.user.photoUrl),
                child: _webImageBytes == null && (widget.user.photoUrl == null || widget.user.photoUrl!.isEmpty)
                    ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                    : null,
              ),
            ),
            TextButton(
              onPressed: _pickImage,
              child: const Text("Change Photo"),
            ),
            if (_isUploading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 8),
            const Text(
              "Note: Images are compressed to save storage.",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context), 
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _isUploading ? null : _saveProfile,
          child: const Text("Save"),
        ),
      ],
    );
  }
}

// Helper to determine ImageProvider based on URL type
ImageProvider? _getImageProvider(String? url) {
  if (url == null || url.isEmpty) return null;
  
  if (url.startsWith('data:image')) {
    try {
      // Extract base64 part
      final base64Str = url.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    } catch (e) {
      debugPrint("Error decoding base64 image: $e");
      return null;
    }
  } else if (url.startsWith('http')) {
    return NetworkImage(url);
  }
  return null;
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMain = theme.textTheme.bodyLarge?.color;
    final textSub = theme.textTheme.bodyMedium?.color;
    final primaryColor = theme.colorScheme.primary;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: textMain),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: textMain,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textSub,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.white54 : Colors.black45,
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

class _DividerLine extends StatelessWidget {

  final Color color;
  const _DividerLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: color,
    );
  }
}
