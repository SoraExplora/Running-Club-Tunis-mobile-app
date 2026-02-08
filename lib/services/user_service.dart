import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all users from Firestore
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('user').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Update user role
  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    try {
      await _firestore.collection('user').doc(userId).update({
        'role': UserModel.roleToString(newRole),
      });
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Error updating user role: $e");
      }
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('user').doc(userId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting user: $e");
      }
      return false;
    }
  }

  // Get user count by role (optional utility)
  Future<Map<UserRole, int>> getUserCountByRole() async {
    try {
      final snapshot = await _firestore.collection('user').get();
      final Map<UserRole, int> counts = {
        UserRole.adminPrincipal: 0,
        UserRole.adminCoach: 0,
        UserRole.groupAdmin: 0,
        UserRole.member: 0,
        UserRole.visitor: 0,
      };

      for (var doc in snapshot.docs) {
        final user = UserModel.fromMap(doc.id, doc.data());
        counts[user.role] = (counts[user.role] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting user counts: $e");
      }
      return {};
    }
  }
}