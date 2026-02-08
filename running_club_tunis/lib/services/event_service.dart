import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';

class EventService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get events for a specific group (or 'All')
  Stream<List<EventModel>> getEventsForGroup(String groupId) {
    return _firestore
        .collection('events')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.id, doc.data()))
          .where((e) => e.group == 'All' || e.group == groupId)
          .toList();
    });
  }

  // Create event
  Future<void> createEvent(EventModel event) async {
    try {
      await _firestore.collection('events').add(event.toMap());
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error creating event: $e");
      rethrow;
    }
  }

  // Update event
  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore.collection('events').doc(event.id).update(event.toMap());
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error updating event: $e");
      rethrow;
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error deleting event: $e");
      rethrow;
    }
  }

  // Toggle user participation
  Future<void> toggleParticipation(String eventId, String userId) async {
    try {
      final docRef = _firestore.collection('events').doc(eventId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> participants = data['participants'] ?? [];

      if (participants.contains(userId)) {
        await docRef.update({
          'participants': FieldValue.arrayRemove([userId])
        });
      } else {
        await docRef.update({
          'participants': FieldValue.arrayUnion([userId])
        });
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error toggling participation: $e");
      rethrow;
    }
  }
  // Get events (one-time fetch)
  Future<List<EventModel>> getEvents({String group = 'All'}) async {
    try {
      final snapshot = await _firestore.collection('events').get();
      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.id, doc.data()))
          .where((e) => e.group == 'All' || e.group == group)
          .toList();
    } catch (e) {
      if (kDebugMode) print("Error getting events: $e");
      return [];
    }
  }
}
