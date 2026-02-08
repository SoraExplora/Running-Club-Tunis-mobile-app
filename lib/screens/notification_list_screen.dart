import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../widgets/semantic_button.dart';

class NotificationListScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const NotificationListScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final notificationService = Provider.of<NotificationService>(context);

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        actions: [
          SemanticButton(
            semanticId: 'notifications_mark_all_read',
            label: 'Mark all as read',
            child: TextButton(
              onPressed: () => notificationService.markAllAsRead(user.id),
              child: const Text("Read All",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.getNotifications(user.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = snapshot.data!;

          if (notes.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: notes.length,
            itemBuilder: (context, i) {
              final n = notes[i];
              return Card(
                color: n.isRead
                    ? null
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.05),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: n.isRead
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                    child: Icon(
                      n.type == 'special' ? Icons.star : Icons.notifications,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(n.title,
                      style: TextStyle(
                          fontWeight:
                              n.isRead ? FontWeight.normal : FontWeight.w900)),
                  subtitle: Text(
                      "${n.body}\n${DateFormat.yMMMd().add_jm().format(n.timestamp)}"),
                  onTap: () => notificationService.markAsRead(n.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
