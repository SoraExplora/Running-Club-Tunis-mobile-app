import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/program_model.dart';

class ProgramService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'programs';

  Stream<List<ProgramModel>> getProgramsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProgramModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> createProgram(ProgramModel program) async {
    try {
      await _firestore.collection(_collection).add(program.toMap());
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error creating program: $e");
      }
      rethrow;
    }
  }

  Future<void> updateProgram(String id, ProgramModel program) async {
    try {
      await _firestore.collection(_collection).doc(id).update(program.toMap());
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error updating program: $e");
      }
      rethrow;
    }
  }

  Future<void> deleteProgram(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting program: $e");
      }
      rethrow;
    }
  }
}