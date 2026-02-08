import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class NotificationOverlayListener extends StatefulWidget {
  final Widget child;
  const NotificationOverlayListener({super.key, required this.child});

  @override
  State<NotificationOverlayListener> createState() => _NotificationOverlayListenerState();
}

class _NotificationOverlayListenerState extends State<NotificationOverlayListener> {
  NotificationModel? _currentNotification;
  Timer? _timer;
  StreamSubscription? _sub;
  String? _lastNotifId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthService>(context).currentUser;
    if (user != null && user.role == UserRole.member) {
      _sub?.cancel();
      _sub = Provider.of<NotificationService>(context, listen: false)
          .getNotifications(user.id)
          .listen((list) {
            if (list.isNotEmpty) {
              final latest = list.first;
              // Only show if it's NEW and UNREAD
              if (latest.id != _lastNotifId && !latest.isRead) {
                _lastNotifId = latest.id;
                _showPopup(latest);
              }
            }
          });
    }
  }

  void _showPopup(NotificationModel notification) {
    setState(() {
      _currentNotification = notification;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _currentNotification = null);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentNotification != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: _PopupWidget(
              notification: _currentNotification!,
              onDismiss: () => setState(() => _currentNotification = null),
            ),
          ),
      ],
    );
  }
}

class _PopupWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;

  const _PopupWidget({required this.notification, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                notification.type == 'special' ? Icons.star_rounded : Icons.notifications_active_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    Text(
                      notification.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}