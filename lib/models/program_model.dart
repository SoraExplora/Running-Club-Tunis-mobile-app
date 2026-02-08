import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramModel {
  final String id;
  final String title;
  final String description;
  final String coachId;
  final String? coachName;
  final DateTime timestamp;
  final String? pdfUrl;
  final bool isPublished;

  ProgramModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coachId,
    this.coachName,
    required this.timestamp,
    this.pdfUrl,
    this.isPublished = false,
  });

  factory ProgramModel.fromMap(String id, Map<String, dynamic> data) {
    return ProgramModel(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      coachId: data['coachId']?.toString() ?? '',
      coachName: data['coachName']?.toString(),
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      pdfUrl: data['pdfUrl']?.toString(),
      isPublished: data['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'coachId': coachId,
      'coachName': coachName,
      'timestamp': Timestamp.fromDate(timestamp),
      'pdfUrl': pdfUrl,
      'isPublished': isPublished,
    };
  }
}