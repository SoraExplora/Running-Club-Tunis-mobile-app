import 'package:flutter/material.dart';


class PersonalScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const PersonalScreen({super.key, required this.onToggleTheme});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  // UI-only local state (later replace with Firebase user profile)
  String fullName = "Runner";
  String email = "guest@rct.tn";
  String cin = "********";
  String group = "Beginner Group";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Top user card
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
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
                  child: Icon(Icons.person, color: textMain),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          color: textMain,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info list
          _InfoTile(
            label: "Full name",
            value: fullName,
            onEdit: () => _editField(
              title: "Edit full name",
              initial: fullName,
              onSave: (v) => setState(() => fullName = v),
            ),
          ),
          _InfoTile(
            label: "Email",
            value: email,
            onEdit: () => _editField(
              title: "Edit email",
              initial: email,
              keyboardType: TextInputType.emailAddress,
              onSave: (v) => setState(() => email = v),
            ),
          ),
             _InfoTile(
            label: "CIN",
            value: cin,
            onEdit: () => _editField(
              title: "Edit CIN",
              initial: cin,
              keyboardType: TextInputType.number,
              onSave: (v) => setState(() => cin = v),
            ),
          ),
          _InfoTile(
            label: "Running group",
            value: group,
            onEdit: () => _pickGroup(
              current: group,
              onSave: (v) => setState(() => group = v),
            ),
          ),
       

          const SizedBox(height: 18),

          
        ],
      ),
    );
  }

  Future<void> _editField({
    required String title,
    required String initial,
    required ValueChanged<String> onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initial);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 10,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  hintText: "Type here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    final v = controller.text.trim();
                    if (v.isEmpty) return;
                    onSave(v);
                    Navigator.pop(ctx);
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

  Future<void> _pickGroup({
    required String current,
    required ValueChanged<String> onSave,
  }) async {
    final groups = [
      "Beginner Group",
      "Intermediate Group",
      "Advanced Group",
      "Trail / Long Run",
    ];

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                "Select your group",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            ...groups.map((g) {
              final selected = g == current;
              return ListTile(
                title: Text(g),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () {
                  onSave(g);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: textMain,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textSub,
          ),
        ),
        trailing: IconButton(
          onPressed: onEdit,
          icon: Icon(
            Icons.edit,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
