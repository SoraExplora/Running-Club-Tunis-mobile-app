import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType { daily, weeklyLongRun, special }

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String group; // Changed from groupName
  final EventType kind; // Changed from type
  final List<String> participants;
  final bool isFree;
  final String price;
  final double? latitude;
  final double? longitude;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.group,
    required this.kind,
    required this.participants,
    this.isFree = true,
    this.price = '0',
    this.latitude,
    this.longitude,
  });

  factory EventModel.fromMap(String id, Map<String, dynamic> data) {
    return EventModel(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      // Handle both Timestamp and direct Date if needed, usually Firestore returns Timestamp
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      location: data['location']?.toString() ?? '',
      group: data['group']?.toString() ?? 'All',
      kind: _stringToKind(data['kind']?.toString()),
      participants: List<String>.from(data['participants'] ?? []),
      isFree: data['isFree'] ?? true,
      price: data['price']?.toString() ?? '0',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'group': group,
      'kind': _kindToString(kind),
      'participants': participants,
      'isFree': isFree,
      'price': price,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static EventType _stringToKind(String? str) {
    switch (str) {
      case 'WEEKLY':
        return EventType.weeklyLongRun;
      case 'SPECIAL':
        return EventType.special;
      default:
        return EventType.daily;
    }
  }

  static String _kindToString(EventType kind) {
    switch (kind) {
      case EventType.weeklyLongRun:
        return 'WEEKLY';
      case EventType.special:
        return 'SPECIAL';
      case EventType.daily:
        return 'DAILY';
    }
  }
}
