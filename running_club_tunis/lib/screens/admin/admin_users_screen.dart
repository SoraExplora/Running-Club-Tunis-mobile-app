import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../models/user_model.dart';

class AdminUsersScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const AdminUsersScreen({super.key, required this.onToggleTheme});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String q = "";

  // UI-only mock data removed

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/RCTCONNECT.png', height: 30),
        ),
        title: const Text("Admin • Users"),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: InputDecoration(
                hintText: "Search users, roles, groups...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('user').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final allUsers = docs.map((doc) {
                  return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                }).toList();

                final filtered = allUsers.where((u) {
                  final lowerQ = q.toLowerCase();
                  return u.name.toLowerCase().contains(lowerQ) ||
                      UserModel.roleToString(u.role).toLowerCase().contains(lowerQ) ||
                      (u.group ?? "").toLowerCase().contains(lowerQ);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      "No users found.",
                      style: TextStyle(
                        color: textMain.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return Container(
                      decoration: index == 0 || index == filtered.length ? null : null, // logic for rounded corners handled by container if needed, sticking to list for now
                      child: _UserRow(
                        name: user.name,
                        photoUrl: user.photoUrl,
                        role: UserModel.getRoleDisplayName(user.role),
                        group: user.group ?? "No Group",
                        isBanned: user.isBanned,
                        onBlock: () => _toggleBlockUser(context, user),
                        onDelete: () => _confirmDelete(context, user),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _toggleBlockUser(BuildContext context, UserModel user) async {
    final action = user.isBanned ? "Unblock" : "Block";
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$action ${user.name}?"),
        content: Text("Are you sure you want to ${action.toLowerCase()} this user?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('user').doc(user.id).update({
        'isBanned': !user.isBanned,
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User ${user.isBanned ? 'unblocked' : 'blocked'}")),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete user?"),
        content: Text("Remove ${user.name} from the system?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('user').doc(user.id).delete();
                if (!context.mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User deleted")),
                );
              } catch (e) {
                if (!context.mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error deleting user: $e")),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final String name;
  final String? photoUrl; // Added photoUrl
  final String role;
  final String group;
  final bool isBanned;
  final VoidCallback onBlock;
  final VoidCallback onDelete;

  const _UserRow({
    required this.name,
    this.photoUrl,
    required this.role,
    required this.group,
    required this.isBanned,
    required this.onBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    ImageProvider? imageProvider;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
       if (photoUrl!.startsWith('data:image')) {
          try {
             imageProvider = MemoryImage(base64Decode(photoUrl!.split(',').last));
          } catch (e) {
             debugPrint("Error decoding admin user image: $e");
          }
       } else if (photoUrl!.startsWith('http')) {
          imageProvider = NetworkImage(photoUrl!);
       }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
        backgroundImage: imageProvider,
        child: imageProvider == null ? Icon(Icons.person, color: textMain) : null,
      ),
      title: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.w900, color: textMain),
      ),
      subtitle: Text(
        "$role • $group",
        style: TextStyle(fontWeight: FontWeight.w600, color: textSub),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
           // ... buttons unchanged ...
          IconButton(
            onPressed: onBlock,
            icon: Icon(
              isBanned ? Icons.check_circle_outline : Icons.block,
              color: isBanned ? Colors.green : Theme.of(context).colorScheme.error,
            ),
            tooltip: isBanned ? "Unblock" : "Block",
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: textMain.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}
