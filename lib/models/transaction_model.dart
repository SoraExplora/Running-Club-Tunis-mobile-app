import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus { pending, completed, failed, cancelled }

class TransactionModel {
  final String id;
  final String userId;
  final String eventId;
  final double amount;
  final String currency;
  final TransactionStatus status;
  final DateTime timestamp;
  final String? paymentReference;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.amount,
    this.currency = 'TND',
    required this.status,
    required this.timestamp,
    this.paymentReference,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic> data) {
    return TransactionModel(
      id: id,
      userId: data['userId'] ?? '',
      eventId: data['eventId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'TND',
      status: _stringToStatus(data['status']),
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      paymentReference: data['paymentReference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'amount': amount,
      'currency': currency,
      'status': _statusToString(status),
      'timestamp': Timestamp.fromDate(timestamp),
      'paymentReference': paymentReference,
    };
  }

  static TransactionStatus _stringToStatus(String? status) {
    switch (status) {
      case 'COMPLETED':
        return TransactionStatus.completed;
      case 'FAILED':
        return TransactionStatus.failed;
      case 'CANCELLED':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  static String _statusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return 'COMPLETED';
      case TransactionStatus.failed:
        return 'FAILED';
      case TransactionStatus.cancelled:
        return 'CANCELLED';
      case TransactionStatus.pending:
        return 'PENDING';
    }
  }
}
