import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';

class TransactionService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a new transaction
  Future<String> createTransaction(TransactionModel transaction) async {
    try {
      final docRef =
          await _firestore.collection('transactions').add(transaction.toMap());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      if (kDebugMode) print("Error creating transaction: $e");
      rethrow;
    }
  }

  // Update transaction status
  Future<void> updateTransactionStatus(
      String transactionId, TransactionStatus status,
      {String? paymentRef}) async {
    try {
      final updates = {
        'status': _statusToString(status),
      };
      if (paymentRef != null) {
        updates['paymentReference'] = paymentRef;
      }
      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .update(updates);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error updating transaction status: $e");
      rethrow;
    }
  }

  // Get transactions for a user
  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  String _statusToString(TransactionStatus status) {
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
