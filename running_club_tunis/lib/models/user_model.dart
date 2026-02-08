import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  adminPrincipal, // Comité directrice
  adminCoach, // Admin Coach
  groupAdmin, // Responsable de groupe
  member, // Adhérent
  visitor // Visiteurn
}

class UserModel {
  final String id;
  final String name;
  final String cin; // Full CIN
  final UserRole role;
  final String? group; // Current group ID
  final String? pendingGroupId; // If user requested to join a group
  final String groupStatus; // 'none', 'pending', 'member'
  final DateTime? lastReadTimestamp;
  final String? colorMode; // "normal", "protanopia", etc.
  final double? fontScale; // 0.8 to 1.4
  final bool isBanned;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.cin,
    required this.role,
    this.group,
    this.pendingGroupId,
    this.groupStatus = 'none',
    this.lastReadTimestamp,
    this.colorMode,
    this.fontScale,
    this.isBanned = false,
    this.photoUrl,
  });

  // Factory to create from Firestore document
  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name']?.toString() ?? '',
      cin: data['cin']?.toString() ?? '',
      role: _stringToRole(data['role']?.toString()),
      group: data['group']?.toString(),
      pendingGroupId: data['pendingGroupId']?.toString(),
      groupStatus: data['groupStatus']?.toString() ?? 'none',
      lastReadTimestamp: data['lastReadTimestamp'] != null
          ? (data['lastReadTimestamp'] as Timestamp).toDate()
          : null,
      colorMode: data['colorMode']?.toString(),
      fontScale: (data['fontScale'] as num?)?.toDouble(),
      isBanned: data['isBanned'] ?? false,
      photoUrl: data['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cin': cin,
      'role': _roleToString(role),
      'group': group,
      'pendingGroupId': pendingGroupId,
      'groupStatus': groupStatus,
      'lastReadTimestamp': lastReadTimestamp != null
          ? Timestamp.fromDate(lastReadTimestamp!)
          : null,
      'colorMode': colorMode,
      'fontScale': fontScale,
      'isBanned': isBanned,
      'photoUrl': photoUrl,
    };
  }

  static UserRole _stringToRole(String? roleStr) {
    switch (roleStr) {
      case 'ADMIN_PRINCIPAL':
        return UserRole.adminPrincipal;
      case 'ADMIN_COACH':
        return UserRole.adminCoach;
      case 'ADMIN_GROUPE':
        return UserRole.groupAdmin;
      case 'ADHERENT':
      case 'member':
      case 'Member':
        return UserRole.member;
      default:
        return UserRole.visitor;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.adminPrincipal:
        return 'ADMIN_PRINCIPAL';
      case UserRole.adminCoach:
        return 'ADMIN_COACH';
      case UserRole.groupAdmin:
        return 'ADMIN_GROUPE';
      case UserRole.member:
        return 'ADHERENT';
      case UserRole.visitor:
        return 'VISITEUR';
    }
  }

  // Public version for external use
  static String roleToString(UserRole role) => _roleToString(role);

  // Get display name for role (French labels)
  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.adminPrincipal:
        return 'Comité Directrice';
      case UserRole.adminCoach:
        return 'Admin Coach';
      case UserRole.groupAdmin:
        return 'Responsable de Groupe';
      case UserRole.member:
        return 'Adhérent';
      case UserRole.visitor:
        return 'Visiteur';
    }
  }

  // Get role description
  static String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.adminPrincipal:
        return 'Accès complet à toutes les fonctionnalités';
      case UserRole.adminCoach:
        return 'Peut gérer les événements et les membres';
      case UserRole.groupAdmin:
        return 'Peut gérer son groupe';
      case UserRole.member:
        return 'Membre actif du club';
      case UserRole.visitor:
        return 'Accès limité en tant que visiteur';
    }
  }

  // Get color for role
  static int getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.adminPrincipal:
        return 0xFFD32F2F; // Red
      case UserRole.adminCoach:
        return 0xFFF57C00; // Orange
      case UserRole.groupAdmin:
        return 0xFF1976D2; // Blue
      case UserRole.member:
        return 0xFF388E3C; // Green
      case UserRole.visitor:
        return 0xFF757575; // Grey
    }
  }

  // Get all available roles for selection
  static List<UserRole> getAllRoles() {
    return [
      UserRole.adminPrincipal,
      UserRole.adminCoach,
      UserRole.groupAdmin,
      UserRole.member,
      UserRole.visitor,
    ];
  }
}