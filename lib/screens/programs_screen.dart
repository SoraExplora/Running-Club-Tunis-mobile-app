import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import '../models/program_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'notification_list_screen.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';

class ProgramsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const ProgramsScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/RCTCONNECT.png', height: 30),
        ),
        title: const Text("Programs"),
        actions: [
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('programs')
            .where('isPublished', isEqualTo: true) // Only published
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.assignment_outlined, size: 64, color: Theme.of(context).disabledColor),
                   const SizedBox(height: 16),
                   const Text("No programs available yet."),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final program = ProgramModel.fromMap(docs[i].id, data);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              program.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              DateFormat.yMMMd().format(program.timestamp),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                         program.description,
                         style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                           CircleAvatar(
                             radius: 12,
                             backgroundColor: Colors.grey.shade300,
                             child: const Icon(Icons.person, size: 16, color: Colors.grey),
                           ),
                           const SizedBox(width: 8),
                           Text(
                             program.coachName ?? "Coach",
                             style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                           ),
                           const Spacer(),
                           if (program.pdfUrl != null)
                             FilledButton.icon(
                               onPressed: () => _downloadPdf(context, program.pdfUrl!, program.title),
                               icon: const Icon(Icons.download_rounded, size: 18),
                               label: const Text("Download PDF"),
                               style: FilledButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                 visualDensity: VisualDensity.compact,
                               ),
                             ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _downloadPdf(BuildContext context, String url, String title) async {
    if (kIsWeb && url.startsWith('data:')) {
      final anchor = html.AnchorElement(href: url);
      anchor.download = "${title.replaceAll(' ', '_')}.pdf";
      anchor.click();
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch PDF")),
        );
      }
    }
  }
}
