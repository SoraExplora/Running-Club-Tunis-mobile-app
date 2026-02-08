import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/event_service.dart';
import '../../services/notification_service.dart';
import '../../services/location_service.dart';
import '../../widgets/location_picker_map.dart';
import 'package:latlong2/latlong.dart';

class AdminEventsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final UserModel currentUser;

  const AdminEventsScreen({
    super.key,
    required this.onToggleTheme,
    required this.currentUser,
  });

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventService = Provider.of<EventService>(context);

    // Group Admins can only see events for their group.
    // Principal Admins see all (or use a group selector).
    final groupId = widget.currentUser.group ?? 'All';

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/RCTCONNECT.png', height: 30),
        ),
        title: const Text("Session Management"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'adminEventsFab',
        onPressed: () => _showEventDialog(context, eventService),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: eventService.getEventsForGroup(groupId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data!;

          if (events.isEmpty) {
            return const Center(child: Text("No events scheduled."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: events.length,
            itemBuilder: (context, i) {
              final e = events[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(e.title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(
                      "${DateFormat.yMMMd().add_jm().format(e.date)}\n${e.location}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          onPressed: () =>
                              _showEventDialog(context, eventService, event: e),
                          icon: const Icon(Icons.edit_outlined)),
                      IconButton(
                        onPressed: () =>
                            _confirmDelete(context, eventService, e),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
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

  void _showEventDialog(BuildContext context, EventService service,
      {EventModel? event}) {
    final titleCtrl = TextEditingController(text: event?.title ?? "");
    final locCtrl = TextEditingController(text: event?.location ?? "");
    final descCtrl = TextEditingController(text: event?.description ?? "");
    final priceCtrl = TextEditingController(text: event?.price ?? "0");
    bool isFree = event?.isFree ?? true;
    DateTime selectedDate = event?.date ?? DateTime.now();
    EventType selectedKind = event?.kind ?? EventType.daily;
    double? latitude = event?.latitude;
    double? longitude = event?.longitude;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(event == null ? "Create Session" : "Edit Session"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: "Title")),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: locCtrl,
                          decoration: const InputDecoration(
                              labelText: "Location (Address)"),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map_outlined),
                        tooltip: "Pick on Map",
                        onPressed: () async {
                          LatLng initial = LatLng(latitude ?? 36.8065,
                              longitude ?? 10.1815); // Tunis

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationPickerMap(
                                initialLocation: initial,
                                onLocationPicked: (picked) async {
                                  setState(() {
                                    latitude = picked.latitude;
                                    longitude = picked.longitude;
                                  });
                                  final address = await LocationService
                                      .getAddressFromCoordinates(
                                    picked.latitude,
                                    picked.longitude,
                                  );
                                  locCtrl.text = address;
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  TextField(
                      controller: descCtrl,
                      decoration:
                          const InputDecoration(labelText: "Description"),
                      maxLines: 2),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<EventType>(
                    initialValue: selectedKind,
                    items: EventType.values
                        .map((k) => DropdownMenuItem(
                            value: k, child: Text(k.name.toUpperCase())))
                        .toList(),
                    onChanged: (v) => setState(() => selectedKind = v!),
                    decoration: const InputDecoration(labelText: "Kind"),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text("Date & Time"),
                    subtitle:
                        Text(DateFormat.yMMMd().add_jm().format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      if (!context.mounted) return;
                      final d = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) {
                        if (!context.mounted) return;
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (t != null) {
                          setState(() => selectedDate = DateTime(
                              d.year, d.month, d.day, t.hour, t.minute));
                        }
                      }
                    },
                  ),
                  SwitchListTile(
                    title: const Text("Free?"),
                    value: isFree,
                    onChanged: (v) => setState(() => isFree = v),
                  ),
                  if (!isFree)
                    TextField(
                        controller: priceCtrl,
                        decoration:
                            const InputDecoration(labelText: "Price (TND)"),
                        keyboardType: TextInputType.number),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  final newEvent = EventModel(
                    id: event?.id ?? "",
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    date: selectedDate,
                    location: locCtrl.text.trim(),
                    group: widget.currentUser.group ?? 'All',
                    kind: selectedKind,
                    participants: event?.participants ?? [],
                    isFree: isFree,
                    price: isFree ? "0" : priceCtrl.text.trim(),
                    latitude: latitude,
                    longitude: longitude,
                  );

                  if (event == null) {
                    await service.createEvent(newEvent);
                    // Notify members
                    if (context.mounted) {
                      Provider.of<NotificationService>(context, listen: false)
                          .broadcastToGroup(
                        groupId: newEvent.group,
                        title: "New Session: ${newEvent.title}",
                        body:
                            "A new session has been scheduled for ${DateFormat.jm().format(newEvent.date)}.",
                        type: 'event_created',
                      );
                    }
                  } else {
                    await service.updateEvent(newEvent);
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: Text(event == null ? "Create" : "Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, EventService service, EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Session?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              service.deleteEvent(event.id);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
