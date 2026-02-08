import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';

class AdminGroupScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final UserModel currentUser;

  const AdminGroupScreen({
    super.key,
    required this.onToggleTheme,
    required this.currentUser,
  });

  @override
  State<AdminGroupScreen> createState() => _AdminGroupScreenState();
}

class _AdminGroupScreenState extends State<AdminGroupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupService = Provider.of<GroupService>(context);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/RCTCONNECT.png', height: 30),
        ),
        title: const Text("Group Management"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Groups"),
            Tab(text: "Requests"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsTab(groupService),
          _buildRequestsTab(groupService),
        ],
      ),
      floatingActionButton: StreamBuilder<List<GroupModel>>(
        stream: groupService.getAllGroups(),
        builder: (context, snapshot) {
          final groups = snapshot.data ?? [];
          final myGroups = groups.where((g) => g.adminId == widget.currentUser.id).toList();
          
          // Only show ADD button if principal admin OR if group admin has no group yet
          final canAdd = widget.currentUser.role == UserRole.adminPrincipal || myGroups.isEmpty;
          
          if (!canAdd) return const SizedBox.shrink();
          
          return FloatingActionButton(
            heroTag: 'adminGroupFab',
            onPressed: () => _showGroupDialog(context, groupService),
            child: const Icon(Icons.add),
          );
        }
      ),
    );
  }

  Widget _buildGroupsTab(GroupService groupService) {
    return StreamBuilder<List<GroupModel>>(
      stream: groupService.getAllGroups(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final groups = snapshot.data!
            .where((g) => g.adminId == widget.currentUser.id || widget.currentUser.role == UserRole.adminPrincipal)
            .toList();

        if (groups.isEmpty) {
          return const Center(child: Text("No groups managed yet."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: groups.length,
          itemBuilder: (context, i) {
            final g = groups[i];
            return _GroupAdminCard(
              group: g,
              groupService: groupService,
              onEdit: () => _showGroupDialog(context, groupService, group: g),
              onDelete: () => _confirmDelete(context, groupService, g),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsTab(GroupService groupService) {
    // For now, let's just get the first group this admin manages to show requests
    // Ideally, if they manage multiple, we'd have a group selector or consolidated view
    return StreamBuilder<List<GroupModel>>(
      stream: groupService.getAllGroups(),
      builder: (context, gSnapshot) {
        if (!gSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final myGroups = gSnapshot.data!
            .where((g) => g.adminId == widget.currentUser.id || widget.currentUser.role == UserRole.adminPrincipal)
            .toList();

        if (myGroups.isEmpty) return const Center(child: Text("Create a group first."));

        return ListView(
          padding: const EdgeInsets.all(18),
          children: myGroups.map((g) {
            return StreamBuilder<List<UserModel>>(
              stream: groupService.getPendingRequests(g.id),
              builder: (context, rSnapshot) {
                if (!rSnapshot.hasData) return const SizedBox.shrink();
                final reqs = rSnapshot.data!;

                if (reqs.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Requests for ${g.name}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue)),
                    ),
                    ...reqs.map((u) => _RequestCard(user: u, group: g, groupService: groupService)),
                    const Divider(),
                  ],
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showGroupDialog(BuildContext context, GroupService service, {GroupModel? group}) {
    final nameCtrl = TextEditingController(text: group?.name ?? "");
    final capCtrl = TextEditingController(text: group?.maxMembers.toString() ?? "50");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(group == null ? "Create Group" : "Edit Group"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Group Name (e.g. Group A)")),
            TextField(controller: capCtrl, decoration: const InputDecoration(labelText: "Max Members"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final cap = int.tryParse(capCtrl.text) ?? 50;
              if (name.isNotEmpty) {
                if (group == null) {
                  service.createGroup(name, widget.currentUser.id, maxMembers: cap);
                } else {
                  service.updateGroup(group.id, name, cap);
                }
                Navigator.pop(ctx);
              }
            },
            child: Text(group == null ? "Create" : "Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, GroupService service, GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Group?"),
        content: Text("This will remove all members from ${group.name}. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              service.deleteGroup(group.id);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _GroupAdminCard extends StatelessWidget {
  final GroupModel group;
  final GroupService groupService;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupAdminCard({
    required this.group,
    required this.groupService,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: ExpansionTile(
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        subtitle: Text("Capacity: ${group.maxMembers} members",
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 20)),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red)),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          const Divider(),
          StreamBuilder<List<UserModel>>(
            stream: groupService.getGroupMembers(group.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator());
              final members = snapshot.data!;
              if (members.isEmpty) return const Padding(padding: EdgeInsets.all(16.0), child: Text("No members yet"));

              return Column(
                children: members.map((u) => ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundImage: u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
                    child: u.photoUrl == null ? const Icon(Icons.person, size: 16) : null,
                  ),
                  title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  trailing: TextButton(
                    onPressed: () => _confirmKick(context, groupService, u),
                    child: const Text("Kick", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w900)),
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _confirmKick(BuildContext context, GroupService service, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kick Member?"),
        content: Text("Are you sure you want to remove ${user.name} from the group?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              service.removeUserFromGroup(user.id);
              Navigator.pop(ctx);
            },
            child: const Text("Kick", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final UserModel user;
  final GroupModel group;
  final GroupService groupService;

  const _RequestCard({required this.user, required this.group, required this.groupService});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Card(
      color: card,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: const Text("Wants to join"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => groupService.acceptJoinRequest(user.id, group.id),
              icon: const Icon(Icons.check_circle, color: Colors.green),
            ),
            IconButton(
              onPressed: () => groupService.denyJoinRequest(user.id),
              icon: const Icon(Icons.cancel, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

