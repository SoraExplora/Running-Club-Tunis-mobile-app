import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AdminRolesScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const AdminRolesScreen({super.key, required this.onToggleTheme});

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
  // UI-only: selected role to preview/edit permissions
  // UI-only: selected role to preview/edit permissions
  String selectedRole = "ADMIN_PRINCIPAL";

  Map<String, Map<String, bool>> perms = {};
  bool _isLoadingPerms = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('roles').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
           perms = data.map((key, value) => MapEntry(key, Map<String, bool>.from(value)));
           _isLoadingPerms = false;
        });
      } else {
        // Initialize with default if not found
        _initDefaultPerms();
      }
    } catch (e) {
      debugPrint("Error loading perms: $e");
      _initDefaultPerms();
    }
  }

  void _initDefaultPerms() {
    setState(() {
      perms = {
        "ADMIN_PRINCIPAL": {
          "manage_roles": true,
          "create_users": true,
          "delete_users": true,
        },
        "ADMIN_COACH": {
          "manage_roles": false,
          "create_users": true,
          "delete_users": false,
        },
         "ADMIN_GROUPE": {
          "manage_roles": false,
          "create_users": false,
          "delete_users": false,
        },
      };
      _isLoadingPerms = false;
    });
  }

  Future<void> _savePermissions() async {
    try {
      await FirebaseFirestore.instance.collection('settings').doc('roles').set(perms);
    } catch (e) {
      debugPrint("Error saving perms: $e");
    }
  }

  // UI-only: current admins list removed

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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/RCTCONNECT.png', height: 30),
        ),
        title: const Text("Admin • Roles"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'adminRolesFab',
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => _showAddAdminOptions(context),
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text(
          "Add admin",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Admins list
          Text(
            "Admins",
            style: TextStyle(
              color: textMain,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user')
                .where('role', whereIn: ['ADMIN_PRINCIPAL', 'ADMIN_COACH', 'ADMIN_GROUPE'])
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final adminsList = snapshot.data!.docs.map((doc) {
                return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
              }).toList();

              return Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    if (adminsList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("No admins found", style: TextStyle(color: textSub)),
                      ),
                    for (int i = 0; i < adminsList.length; i++) ...[
                      _AdminRow(
                        name: adminsList[i].name,
                        role: UserModel.getRoleDisplayName(adminsList[i].role),
                        onChangeRole: () => _openChangeRole(context, adminsList[i]),
                        onRemove: () => _confirmRemoveAdmin(context, adminsList[i]),
                      ),
                      if (i != adminsList.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Role selector
          Text(
            "Permissions matrix",
            style: TextStyle(
              color: textMain,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),

          if (_isLoadingPerms)
             const Center(child: CircularProgressIndicator())
          else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: textMain.withValues(alpha: 0.9)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Select a role to preview/edit its permissions.",
                      style: TextStyle(
                        color: textSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedRole,
                    underline: const SizedBox.shrink(),
                    items: perms.keys
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => selectedRole = v);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Permissions list
            if (perms[selectedRole] != null)
            Container(
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                   for (var entry in perms[selectedRole]!.entries) ...[
                    _PermRow(
                      title: entry.key,
                      value: entry.value,
                      onChanged: (val) {
                        setState(() {
                          perms[selectedRole]![entry.key] = val;
                        });
                        _savePermissions(); // Auto-save on toggle
                      },
                    ),
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                   ]
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Safety note
          Text(
            "Changes are saved automatically to 'settings/roles'.",
            style: TextStyle(
              color: textSub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  void _showAddAdminOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text("Create New Admin"),
                subtitle: const Text("Create a new user with admin privileges"),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateAdminForm(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text("Promote Existing Member"),
                subtitle: const Text("Choose a member to promote"),
                onTap: () {
                  Navigator.pop(ctx);
                  _openPromoteMemberSheet(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _openCreateAdminForm(BuildContext context) {
    final nameController = TextEditingController();
    final cinController = TextEditingController();
    final groupController = TextEditingController();
    String selectedRole = "ADMIN_PRINCIPAL";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create New Admin"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cinController,
                decoration: const InputDecoration(labelText: "CIN (8 digits)"),
                keyboardType: TextInputType.number,
                maxLength: 8,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                 decoration: const InputDecoration(labelText: "Role"),
                items: const [
                  DropdownMenuItem(value: "ADMIN_PRINCIPAL", child: Text("Admin Principal")),
                  DropdownMenuItem(value: "ADMIN_COACH", child: Text("Admin Coach")),
                  DropdownMenuItem(value: "ADMIN_GROUPE", child: Text("Group Admin")),
                ],
                onChanged: (v) {
                  if (v != null) selectedRole = v;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: groupController,
                decoration: const InputDecoration(labelText: "Group (Optional)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancel")
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final cin = cinController.text.trim();
              final group = groupController.text.trim();

              if (name.isEmpty || cin.length != 8) {
                if (ctx.mounted) {
                   ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text("Please enter valid Name and 8-digit CIN")),
                  );
                }
                return;
              }

              Navigator.pop(ctx);
              
              try {
                // Check if CIN exists
                final existing = await FirebaseFirestore.instance
                    .collection('user')
                    .where('cin', isEqualTo: cin)
                    .get();
                
                if (existing.docs.isNotEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User with this CIN already exists!")),
                  );
                  return;
                }

                // Create user
                await FirebaseFirestore.instance.collection('user').add({
                  'name': name,
                  'cin': cin,
                  'role': selectedRole,
                  'group': group.isEmpty ? null : group,
                  'isBanned': false,
                  'lastReadTimestamp': FieldValue.serverTimestamp(),
                  'colorMode': 0,
                  'fontScale': 1.0,
                });

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Admin '$name' created successfully")),
                );

              } catch (e) {
                 if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error adding admin: $e")),
                );
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _openPromoteMemberSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                AppBar(
                  title: const Text("Promote Member"),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('user')
                        .where('role', isEqualTo: 'ADHERENT')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final members = snapshot.data!.docs.map((doc) {
                        return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                      }).where((u) => !u.isBanned).toList(); // Filter blocked users

                      if (members.isEmpty) {
                         return const Center(child: Text("No eligible members found to promote"));
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final user = members[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(user.name),
                            subtitle: Text("${user.cin} • ${user.group ?? 'No Group'}"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.pop(ctx);
                              _openChangeRole(context, user); // Reuse existing role change logic
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openChangeRole(BuildContext context, UserModel user) {
    String roleStr = UserModel.roleToString(user.role);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Change role",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: roleStr,
                items: const [
                  DropdownMenuItem(value: "ADMIN_PRINCIPAL", child: Text("Admin Principal")),
                  DropdownMenuItem(value: "ADMIN_COACH", child: Text("Admin Coach")),
                  DropdownMenuItem(value: "ADMIN_GROUPE", child: Text("Group Admin")),
                  DropdownMenuItem(value: "ADHERENT", child: Text("Member (Remove Admin)")),
                ],
                onChanged: (v) => roleStr = v ?? roleStr,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await FirebaseFirestore.instance.collection('user').doc(user.id).update({
                        'role': roleStr,
                      });
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Role updated")),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmRemoveAdmin(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove admin access?"),
        content: Text("Demote ${user.name} to Member?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () async {
              Navigator.pop(ctx);
               try {
                  await FirebaseFirestore.instance.collection('user').doc(user.id).update({
                    'role': 'ADHERENT',
                  });
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User demoted to Member")),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  final String name;
  final String role;
  final VoidCallback onChangeRole;
  final VoidCallback onRemove;

  const _AdminRow({
    required this.name,
    required this.role,
    required this.onChangeRole,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
        child: Icon(Icons.admin_panel_settings_outlined, color: textMain),
      ),
      title: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.w900, color: textMain),
      ),
      subtitle: Text(
        role,
        style: TextStyle(fontWeight: FontWeight.w700, color: textSub),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onChangeRole,
            icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline, color: textMain.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: textMain,
        ),
      ),
      subtitle: Text(
        value ? "Allowed" : "Not allowed",
        style: TextStyle(fontWeight: FontWeight.w700, color: textSub),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }
}
