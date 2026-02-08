import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/notification_service.dart';
import '../widgets/semantic_button.dart';
import 'notification_list_screen.dart';
import '../widgets/event_location_map.dart';
import '../services/payment_service.dart';
import 'payment_webview_screen.dart';

class EventsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const EventsScreen({super.key, required this.onToggleTheme});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final eventService = Provider.of<EventService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Members without group or pending
    if (user.role == UserRole.member && user.groupStatus != 'member') {
      return _GroupJoinView(
        user: user,
        onToggleTheme: widget.onToggleTheme,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.70)
        : Colors.black.withValues(alpha: 0.60);

    return StreamBuilder<List<EventModel>>(
      stream: eventService.getEventsForGroup(user.group ?? 'All'),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];

        // Filter events: only same day
        final dayEvents = events
            .where((e) => _isSameDay(e.date, _selectedDay))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/images/RCTCONNECT.png', height: 30),
            ),
            title: const Text("Events"),
            centerTitle: true,
            actions: [
              if (user.role == UserRole.member && user.groupStatus == 'member')
                SemanticIconButton(
                  semanticId: 'events_quit_group',
                  icon: Icons.exit_to_app,
                  color: Colors.red,
                  size: 20,
                  tooltip: 'Quit Group',
                  onPressed: () => _showQuitGroupDialog(context, user.id),
                ),
              if (user.role == UserRole.member)
                StreamBuilder<int>(
                  stream:
                      Provider.of<NotificationService>(context, listen: false)
                          .getUnreadCount(user.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Stack(
                      children: [
                        SemanticIconButton(
                          semanticId: 'events_notifications',
                          icon: Icons.notifications_none_rounded,
                          tooltip: 'Notifications',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationListScreen(
                                  onToggleTheme: widget.onToggleTheme),
                            ),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              constraints: const BoxConstraints(
                                  minWidth: 16, minHeight: 16),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              SemanticIconButton(
                semanticId: 'events_theme_toggle',
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                tooltip: 'Toggle theme',
                onPressed: widget.onToggleTheme,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            children: [
              _WeekStrip(
                selected: _selectedDay,
                onSelect: (d) => setState(() => _selectedDay = d),
              ),

              const SizedBox(height: 14),

              // “Calendar-like” header card (no real calendar)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    _DateBadge(date: _selectedDay),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _prettyDay(_selectedDay),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${dayEvents.length} session(s) planned",
                            style: TextStyle(
                              color: textSub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.calendar_month_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.9)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (dayEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.nightlight_round, color: textSub),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "No events for this day.\nCheck tomorrow or switch group.",
                          style: TextStyle(
                              color: textSub, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...dayEvents.map((e) => _EventCard(
                      event: e,
                      isDark: isDark,
                      onTap: () => _openEventDetails(e),
                    )),
            ],
          ),
        );
      },
    );
  }

  void _openEventDetails(EventModel e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailsSheet(event: e),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _prettyDay(DateTime d) {
    const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final wd = weekdays[(d.weekday - 1).clamp(0, 6)];
    return "$wd • ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  }

  void _showQuitGroupDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Quit Group?"),
        content:
            const Text("Are you sure you want to leave your current group?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Provider.of<GroupService>(context, listen: false)
                    .leaveGroup(userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("You have left the group")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to leave group")),
                  );
                }
              }
            },
            child: const Text("Quit", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/* -------------------- UI pieces -------------------- */
class _WeekStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const _WeekStrip({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final start = DateTime(selected.year, selected.month, selected.day)
        .subtract(const Duration(days: 3));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));

    return SizedBox(
      height: 64, // ✅ was 62 (prevents overflow)
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final d = days[i];
          final isSelected = d.year == selected.year &&
              d.month == selected.month &&
              d.day == selected.day;

          final bg = isSelected
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: isDark ? 0.22 : 0.18)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05));

          final border = isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.55)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06));

          final text = isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.78)
                  : Colors.black.withValues(alpha: 0.72));

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelect(d),
            child: Container(
              width: 60, // ✅ slightly smaller
              padding:
                  const EdgeInsets.symmetric(vertical: 8), // ✅ less padding
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // ✅ prevents stretching
                  children: [
                    Text(
                      _wd(d.weekday),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: text,
                        fontSize: 11, // ✅ was 12
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.day.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: text,
                        fontSize: 15, // ✅ was 16
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _wd(int weekday) {
    const w = ["M", "T", "W", "T", "F", "S", "S"];
    return w[(weekday - 1).clamp(0, 6)];
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;
  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date.month.toString().padLeft(2, '0'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          Text(
            date.day.toString(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool isDark;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.70)
        : Colors.black.withValues(alpha: 0.60);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimePill(time: _hhmm(event.date), kind: event.kind),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            color: textMain,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!event.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${event.price} TND",
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.groups_2_rounded,
                        text: event.group == 'All'
                            ? "Everyone"
                            : "Group ${event.group}",
                        isDark: isDark,
                      ),
                      _MetaChip(
                        icon: Icons.place_rounded,
                        text: event.location,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: textSub,
                        fontWeight: FontWeight.w600,
                        height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hhmm(DateTime d) =>
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  static String _kindLabel(EventType k) {
    switch (k) {
      case EventType.daily:
        return "DAILY";
      case EventType.weeklyLongRun:
        return "WEEKLY";
      case EventType.special:
        return "SPECIAL";
    }
  }

  static Color _kindColor(BuildContext context, EventType k) {
    switch (k) {
      case EventType.daily:
        return Theme.of(context).colorScheme.primary;
      case EventType.weeklyLongRun:
        return const Color(0xFF5E574D);
      case EventType.special:
        return const Color(0xFFB3B6B7);
    }
  }
}

class _TimePill extends StatelessWidget {
  final String time;
  final EventType kind;

  const _TimePill({required this.time, required this.kind});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _EventCard._kindColor(context, kind)
            .withValues(alpha: isDark ? 0.22 : 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            time,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            _EventCard._kindLabel(kind),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.8,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.black.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _MetaChip(
      {required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final fg = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : Colors.black.withValues(alpha: 0.72);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style:
                TextStyle(fontWeight: FontWeight.w700, color: fg, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EventDetailsSheet extends StatelessWidget {
  final EventModel event;
  const _EventDetailsSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheet = isDark ? const Color(0xFF161616) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.black.withValues(alpha: 0.62);

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder: (context, controller) {
        final theme = Theme.of(context);
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final auth = Provider.of<AuthService>(context, listen: false);
            final user = auth.currentUser;
            final eventService =
                Provider.of<EventService>(context, listen: false);

            final isParticipating =
                user != null && event.participants.contains(user.id);

            return Container(
              decoration: BoxDecoration(
                color: sheet,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border.all(color: border),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(18),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: textMain),
                        ),
                      ),
                      if (!event.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${event.price} TND",
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: TextStyle(
                        color: textSub,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  _detailRow(context, Icons.calendar_month_rounded,
                      _fullDate(event.date), textMain, textSub),
                  const SizedBox(height: 12),
                  _detailRow(context, Icons.location_on_outlined,
                      event.location, textMain, textSub),
                  if (event.latitude != null && event.longitude != null) ...[
                    const SizedBox(height: 12),
                    EventLocationMap(
                      latitude: event.latitude!,
                      longitude: event.longitude!,
                      title: event.title,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _detailRow(
                      context,
                      Icons.groups_2_rounded,
                      event.group == 'All'
                          ? "Everyone"
                          : "Group ${event.group}",
                      textMain,
                      textSub),
                  const SizedBox(height: 12),
                  _detailRow(context, Icons.info_outline,
                      _EventCard._kindLabel(event.kind), textMain, textSub),
                  const SizedBox(height: 12),
                  _detailRow(
                      context,
                      Icons.people_alt_rounded,
                      "${event.participants.length} participants",
                      textMain,
                      textSub),
                  const SizedBox(height: 24),
                  if (user != null)
                    SemanticButton(
                      semanticId: isParticipating
                          ? 'events_leave_session'
                          : 'events_join_session',
                      label: isParticipating
                          ? 'Cancel participation'
                          : 'Join session',
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (isParticipating) {
                                    // Handle leaving session as before
                                    setSheetState(() => isLoading = true);
                                    try {
                                      await eventService.toggleParticipation(
                                          event.id, user.id);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      setSheetState(() => isLoading = false);
                                    }
                                  } else {
                                    // Joining flow
                                    if (!event.isFree) {
                                      // Trigger payment flow
                                      final paymentService =
                                          Provider.of<PaymentService>(context,
                                              listen: false);
                                      setSheetState(() => isLoading = true);
                                      try {
                                        final result = await paymentService
                                            .initiatePayment(
                                                userId: user.id, event: event);

                                        final paymentUrl =
                                            result['formUrl'] ?? '';
                                        final transactionId =
                                            result['transactionId'] ?? '';
                                        final orderId = result['orderId'] ?? '';

                                        if (context.mounted) {
                                          final success =
                                              await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PaymentWebViewScreen(
                                                url: paymentUrl,
                                                transactionId: transactionId,
                                                orderId: orderId,
                                              ),
                                            ),
                                          );

                                          if (success == true) {
                                            // Payment successful, now join
                                            await eventService
                                                .toggleParticipation(
                                                    event.id, user.id);
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                            }
                                          } else {
                                            // Payment failed or cancelled
                                            setSheetState(
                                                () => isLoading = false);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "Payment declined.")),
                                              );
                                            }
                                          }
                                        }
                                      } catch (e) {
                                        setSheetState(() => isLoading = false);
                                      }
                                    } else {
                                      // Free event, join directly
                                      setSheetState(() => isLoading = true);
                                      try {
                                        await eventService.toggleParticipation(
                                            event.id, user.id);
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        setSheetState(() => isLoading = false);
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isParticipating
                                ? Colors.red.withValues(alpha: 0.1)
                                : theme.colorScheme.primary,
                            foregroundColor:
                                isParticipating ? Colors.red : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            side: isParticipating
                                ? const BorderSide(color: Colors.red)
                                : null,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(
                                  isParticipating
                                      ? "Cancel Participation"
                                      : "Join Session",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16),
                                ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text("Participants",
                      style: TextStyle(
                          color: textMain,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  if (event.participants.isEmpty)
                    Text("No one has joined yet. Be the first!",
                        style: TextStyle(
                            color: textSub, fontStyle: FontStyle.italic))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: event.participants
                          .take(20)
                          .map((p) => Chip(
                                label: Text(p,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: isDark ? 0.15 : 0.10),
                                side: BorderSide(color: border),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String value,
      Color textMain, Color textSub) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                color: textSub, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _fullDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return "$dd/$mm/${d.year} • $hh:$mi";
  }
}

/* -------------------- Group Join View -------------------- */

class _GroupJoinView extends StatelessWidget {
  final UserModel user;
  final VoidCallback onToggleTheme;

  const _GroupJoinView({required this.user, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupService = Provider.of<GroupService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Join a Group"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: user.groupStatus == 'pending'
          ? _buildPendingView(context)
          : _buildSelectionView(context, groupService),
    );
  }

  Widget _buildPendingView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            const Text(
              "Request Pending",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              "Your request to join the group is waiting for approval from the group administrator.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textSub, fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => Provider.of<GroupService>(context, listen: false)
                  .denyJoinRequest(user.id),
              child: const Text("Cancel Request"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionView(BuildContext context, GroupService groupService) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    return StreamBuilder<List<GroupModel>>(
      stream: groupService.getAllGroups(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = snapshot.data!;

        if (groups.isEmpty) {
          return Center(
            child: Text(
              "No groups available at the moment.",
              style: TextStyle(color: textSub, fontWeight: FontWeight.w600),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              "Choose your group",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              "Select a group to see its events and start training with the team.",
              style: TextStyle(color: textSub, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ...groups.map((g) => _GroupCard(group: g, userId: user.id)),
          ],
        );
      },
    );
  }
}

class _GroupCard extends StatefulWidget {
  final GroupModel group;
  final String userId;

  const _GroupCard({required this.group, required this.userId});

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            child: Text(
              widget.group.name.characters.first.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  "Capacity: ${widget.group.maxMembers} members",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _sent
                ? null
                : () async {
                    setState(() => _sent = true);
                    try {
                      await Provider.of<GroupService>(context, listen: false)
                          .requestToJoinGroup(widget.userId, widget.group.id);
                    } catch (e) {
                      setState(() => _sent = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Failed to send request")),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_sent ? "Sent" : "Request"),
          ),
        ],
      ),
    );
  }
}
