import 'package:flutter/material.dart';
import '../main.dart'; // Access navigatorKey
import 'assistant_overlay.dart';
import 'notification_overlay.dart';

class AppOverlay extends StatefulWidget {
  final Widget child;

  const AppOverlay({super.key, required this.child});

  @override
  State<AppOverlay> createState() => _AppOverlayState();
}

class _AppOverlayState extends State<AppOverlay> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertOverlay();
    });
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  void _insertOverlay() {
    if (_entry != null) return;

    final overlay = RCTConnectApp.navigatorKey.currentState?.overlay;
    if (overlay != null) {
      _entry = OverlayEntry(
        builder: (context) => const _GlobalOverlayStack(),
      );
      overlay.insert(_entry!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _GlobalOverlayStack extends StatelessWidget {
  const _GlobalOverlayStack();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        // Notification layer at the top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: NotificationOverlayListener(child: SizedBox.shrink()),
        ),

        // Assistant button at the bottom right
        Positioned(
          bottom: 240,
          right: 20,
          child: AssistantOverlay(),
        ),
      ],
    );
  }
}