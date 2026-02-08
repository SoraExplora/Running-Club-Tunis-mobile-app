import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';

class GroupService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Find group by admin ID
  Future<GroupModel?> getGroupByAdmin(String adminId) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('adminId', isEqualTo: adminId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return GroupModel.fromMap(
          snapshot.docs.first.id, snapshot.docs.first.data());
    } catch (e) {
      if (kDebugMode) print("Error fetching group by admin: $e");
      return null;
    }
  }

  // Find group by ID
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (!doc.exists) return null;
      return GroupModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      if (kDebugMode) print("Error fetching group by ID: $e");
      return null;
    }
  }

  // Create a new group
  Future<String> createGroup(String name, String adminId, {int maxMembers = 50}) async {
    try {
      final docRef = await _firestore.collection('groups').add({
        'name': name,
        'adminId': adminId,
        'maxMembers': maxMembers,
      });

      // Update admin user to be in this group
      await _firestore.collection('user').doc(adminId).update({
        'group': docRef.id,
      });

      notifyListeners();
      return docRef.id;
    } catch (e) {
      if (kDebugMode) print("Error creating group: $e");
      rethrow;
    }
  }

  // Get members of a group
  Stream<List<UserModel>> getGroupMembers(String groupId) {
    return _firestore
        .collection('user')
        .where('group', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Invite user by CIN or Name (searching all users)
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Simple search implementation
      final snapshot = await _firestore.collection('user').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .where((user) =>
              (user.group == null || user.group!.isEmpty) &&
              (user.name.toLowerCase().contains(query.toLowerCase()) ||
                  user.cin.contains(query)))
          .toList();
    } catch (e) {
      if (kDebugMode) print("Error searching users: $e");
      return [];
    }
  }

  // Add user to group
  Future<void> addUserToGroup(String userId, String groupId) async {
    try {
      await _firestore.collection('user').doc(userId).update({
        'group': groupId,
      });
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error adding user to group: $e");
      rethrow;
    }
  }

  // Remove user from group (kick or leave)
  Future<void> removeUserFromGroup(String userId) async {
    try {
      await _firestore.collection('user').doc(userId).update({
        'group': FieldValue.delete(),
        'groupStatus': 'none',
        'pendingGroupId': FieldValue.delete(),
      });
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error removing user from group: $e");
      rethrow;
    }
  }

  // Member voluntarily leaves the group
  Future<void> leaveGroup(String userId) => removeUserFromGroup(userId);

  // Request to join a group
  Future<void> requestToJoinGroup(String userId, String groupId) async {
    try {
      await _firestore.collection('user').doc(userId).update({
        'pendingGroupId': groupId,
        'groupStatus': 'pending',
      });
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error requesting to join group: $e");
      rethrow;
    }
  }

  // Accept join request
  Future<void> acceptJoinRequest(String userId, String groupId) async {
    try {
      await _firestore.collection('user').doc(userId).update({
        'group': groupId,
        'groupStatus': 'member',
        'pendingGroupId': FieldValue.delete(),
      });
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error accepting join request: $e");
      rethrow;
    }
  }

  // Deny join request
  Future<void> denyJoinRequest(String userId) async {
    try {
      await _firestore.collection('user').doc(userId).update({
        'pendingGroupId': FieldValue.delete(),
        'groupStatus': 'none',
      });
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error denying join request: $e");
      rethrow;
    }
  }

  // Get pending requests for a group
  Stream<List<UserModel>> getPendingRequests(String groupId) {
    return _firestore
        .collection('user')
        .where('pendingGroupId', isEqualTo: groupId)
        .where('groupStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Delete a group
  Future<void> deleteGroup(String groupId) async {
    try {
      // 1. Remove all members from this group
      final members = await _firestore.collection('user').where('group', isEqualTo: groupId).get();
      for (var doc in members.docs) {
        await doc.reference.update({
          'group': FieldValue.delete(),
          'groupStatus': 'none',
        });
      }

      // 2. Clear pending requests
      final pending = await _firestore.collection('user').where('pendingGroupId', isEqualTo: groupId).get();
      for (var doc in pending.docs) {
        await doc.reference.update({
          'pendingGroupId': FieldValue.delete(),
          'groupStatus': 'none',
        });
      }

      // 3. Delete the group document
      await _firestore.collection('groups').doc(groupId).delete();
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error deleting group: $e");
      rethrow;
    }
  }

  // Get all groups (SuperAdmin)
  Stream<List<GroupModel>> getAllGroups() {
    return _firestore.collection('groups').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return GroupModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Update group details
  Future<void> updateGroup(String groupId, String name, int maxMembers) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'name': name,
        'maxMembers': maxMembers,
      });
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error updating group: $e");
      rethrow;
    }
  }
}