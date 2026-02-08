class GroupModel {
  final String id;
  final String name;
  final String adminId; // Responsable du groupe
  final int maxMembers;

  GroupModel({
    required this.id,
    required this.name,
    required this.adminId,
    this.maxMembers = 50,
  });

  factory GroupModel.fromMap(String id, Map<String, dynamic> data) {
    return GroupModel(
      id: id,
      name: data['name']?.toString() ?? '',
      adminId: data['adminId']?.toString() ?? '',
      maxMembers: data['maxMembers'] ?? 50,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adminId': adminId,
      'maxMembers': maxMembers,
    };
  }
}