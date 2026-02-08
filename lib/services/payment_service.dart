import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../models/transaction_model.dart';
import 'transaction_service.dart';

class PaymentService with ChangeNotifier {
  final TransactionService _transactionService;

  PaymentService(this._transactionService);

  /// Initializes a mock payment and returns a mock result.
  Future<Map<String, String>> initiatePayment({
    required String userId,
    required EventModel event,
  }) async {
    try {
      // 1. Create a pending transaction record
      final transactionAmount = double.tryParse(event.price) ?? 0.0;
      final transaction = TransactionModel(
        id: '', // Will be set by Firestore
        userId: userId,
        eventId: event.id,
        amount: transactionAmount,
        status: TransactionStatus.pending,
        timestamp: DateTime.now(),
      );

      final transactionId =
          await _transactionService.createTransaction(transaction);

      // 2. Return mock identifiers
      return {
        'formUrl': 'mock_cliktopay_url',
        'orderId': 'mock_order_${DateTime.now().millisecondsSinceEpoch}',
        'transactionId': transactionId,
      };
    } catch (e) {
      if (kDebugMode) print("Error initiating mock payment: $e");
      rethrow;
    }
  }

  /// Verifies the mock payment status.
  Future<bool> verifyPayment(String transactionId, String orderId,
      {bool simulateSuccess = true}) async {
    try {
      TransactionStatus finalStatus = simulateSuccess
          ? TransactionStatus.completed
          : TransactionStatus.failed;

      await _transactionService.updateTransactionStatus(
          transactionId, finalStatus,
          paymentRef: orderId);

      return simulateSuccess;
    } catch (e) {
      if (kDebugMode) print("Error verifying mock payment: $e");
      return false;
    }
  }
}
