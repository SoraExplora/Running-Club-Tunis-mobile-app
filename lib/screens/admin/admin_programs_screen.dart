import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/program_model.dart';
import '../../models/user_model.dart';


class AdminProgramsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final UserModel currentUser;
  const AdminProgramsScreen({
    super.key,
    required this.onToggleTheme,
    required this.currentUser,
  });

  @override
  State<AdminProgramsScreen> createState() => _AdminProgramsScreenState();
}

class _AdminProgramsScreenState extends State<AdminProgramsScreen> {

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
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "programsFab",
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => _openProgramDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: () {
          Query query = FirebaseFirestore.instance.collection('programs');
          
          // If COACH: filter by their ID
          if (widget.currentUser.role == UserRole.adminCoach) {
            query = query.where('coachId', isEqualTo: widget.currentUser.id);
          }
          
          return query.orderBy('timestamp', descending: true).snapshots();
        }(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No programs found"));

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final program = ProgramModel.fromMap(docs[i].id, data);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          program.title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (!program.isPublished)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.secondary),
                          ),
                          child: Text(
                            "DRAFT",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(program.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                           Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Icons.person, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                               const SizedBox(width: 4),
                               Text(program.coachName ?? "Unknown Coach", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                             ],
                           ),
                           Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Icons.calendar_today, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                               const SizedBox(width: 4),
                               Text(DateFormat.yMMMd().format(program.timestamp), style: const TextStyle(fontSize: 12)),
                             ],
                           ),
                           if (program.pdfUrl != null) 
                             Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                  const Icon(Icons.picture_as_pdf, size: 14, color: Colors.red),
                                  const SizedBox(width: 4),
                                  const Text("PDF", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                               ],
                             ),
                        ],
                      )
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!program.isPublished)
                        IconButton(
                          icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                          tooltip: "Publish Program",
                          onPressed: () => _publishProgram(context, program),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _openProgramDialog(context, program: program),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Program?"),
                              content: const Text("Are you sure you want to permanently delete this program?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance.collection('programs').doc(program.id).delete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Program deleted")),
                              );
                            }
                          }
                        },
                        tooltip: "Delete Program",
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

  void _openProgramDialog(BuildContext context, {ProgramModel? program}) async {
    final isEditing = program != null;
    final titleController = TextEditingController(text: program?.title);
    final descController = TextEditingController(text: program?.description);
    String? pdfBase64; // To hold new file data
    
    DateTime selectedDate = program?.timestamp ?? DateTime.now();
    
    // Coach Selection
    String? selectedCoachId = isEditing ? program.coachId : (widget.currentUser.role == UserRole.adminCoach ? widget.currentUser.id : null);
    String? selectedCoachName = isEditing ? program.coachName : (widget.currentUser.role == UserRole.adminCoach ? widget.currentUser.name : null);
    
    final bool isRestrictiveCoach = widget.currentUser.role == UserRole.adminCoach;
    
    // Fetch coaches
    List<UserModel> coaches = [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('user')
          .where('role', whereIn: ['ADMIN_COACH', 'ADMIN_PRINCIPAL'])
          .get();
      coaches = snap.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList();

      // Validate selectedCoachId
      if (selectedCoachId != null && !coaches.any((c) => c.id == selectedCoachId)) {
        selectedCoachId = null; // Reset if coach not found in list
      }
    } catch (e) {
      debugPrint("Error fetching coaches: $e");
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? "Edit Program" : "New Program"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7, // 70% of screen width
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 4,
                      maxLength: 1000,
                    ),
                    const SizedBox(height: 16),
                    // Coach Dropdown - Only show if current user is NOT a restricted coach
                    if (!isRestrictiveCoach)
                      DropdownButtonFormField<String>(
                        initialValue: selectedCoachId,
                        decoration: const InputDecoration(
                          labelText: "Coach",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: coaches.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )).toList(),
                        onChanged: (v) {
                           setState(() {
                             selectedCoachId = v;
                             if (v != null) {
                                selectedCoachName = coaches.firstWhere((c) => c.id == v).name;
                             }
                           });
                        },
                      )
                    else 
                      // For coaches, just show their name (read only)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, size: 20),
                            const SizedBox(width: 12),
                            Text("Coach: ${widget.currentUser.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    // PDF Picker (Base64)
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                             pdfBase64 != null ? "PDF Selected (Ready to save)" 
                             : (program?.pdfUrl != null ? "Current PDF Attached" : "No PDF Attached"),
                             style: const TextStyle(fontSize: 12, color: Colors.grey),
                             maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: const Text("Attach PDF"),
                          onPressed: () async {
                             FilePickerResult? result = await FilePicker.platform.pickFiles(
                               type: FileType.custom,
                               allowedExtensions: ['pdf'],
                               withData: true, // Important for Web/Base64
                             );
                             
                             if (result != null) {
                               PlatformFile file = result.files.first;
                               if (file.bytes != null) {
                                 if (file.size > 500000) { // 500KB limit warning
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Warning: PDF is large (>500KB). It may fail to save.")),
                                      );
                                    }
                                 }
                                 
                                 final base64String = base64Encode(file.bytes!);
                                 setState(() {
                                   pdfBase64 = "data:application/pdf;base64,$base64String";
                                 });
                               }
                             }
                          },
                        ),
                      ],
                    ),
                  if (pdfBase64 != null)
                     Text("New file selected: ${(pdfBase64!.length / 1024).toStringAsFixed(1)} KB", style: const TextStyle(fontSize: 10, color: Colors.green)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Date"),
                    subtitle: Text(DateFormat.yMMMd().format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final desc = descController.text.trim();

                if (title.isEmpty || selectedCoachId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text("Title and Coach are required")),
                  );
                  return;
                }

                Navigator.pop(ctx);
                
                final data = {
                  'title': title,
                  'description': desc,
                  'coachId': selectedCoachId,
                  'coachName': selectedCoachName,
                  'timestamp': Timestamp.fromDate(selectedDate),
                  'pdfUrl': pdfBase64 ?? program?.pdfUrl, 
                  'isPublished': isEditing ? program.isPublished : false,
                };

                try {
                  if (isEditing) {
                    await FirebaseFirestore.instance.collection('programs').doc(program.id).update(data);
                  } else {
                    await FirebaseFirestore.instance.collection('programs').add(data);
                  }
                  if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? "Program updated" : "Draft created")),
                    );
                  }
                } catch (e) {
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                }
              },
              child: Text(isEditing ? "Save" : "Save Draft"),
            ),
            if (isEditing)
              IconButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text("Delete Program?"),
                      content: const Text("This action cannot be undone."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true), 
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    await FirebaseFirestore.instance.collection('programs').doc(program.id).delete();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Program deleted")));
                    }
                  }
                },
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                tooltip: "Delete Program",
              ),
          ],
        );
      },
    ),
  );
}

  void _publishProgram(BuildContext context, ProgramModel program) async {
      try {
        await FirebaseFirestore.instance.collection('programs').doc(program.id).update({
          'isPublished': true,
        });
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Program Published!")),
          );
        }
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
  }
}
