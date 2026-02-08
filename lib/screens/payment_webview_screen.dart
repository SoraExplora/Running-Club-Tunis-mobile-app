import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/payment_service.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  final String transactionId;
  final String orderId;

  const PaymentWebViewScreen({
    super.key,
    required this.url,
    required this.transactionId,
    required this.orderId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  bool _isLoading = false;

  void _completePayment(bool simulateSuccess) async {
    setState(() => _isLoading = true);
    final paymentService = Provider.of<PaymentService>(context, listen: false);

    final success = await paymentService.verifyPayment(
        widget.transactionId, widget.orderId,
        simulateSuccess: simulateSuccess);

    if (mounted) {
      Navigator.pop(context, success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock ClikToPay'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Image.asset('assets/images/RCTCONNECT.png', height: 60),
                  const SizedBox(height: 20),
                  Text(
                    "ClikToPay Secure Sandbox",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textMain),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "This is a simulated payment gateway for testing purposes.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSub),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Transaction ID:", style: TextStyle(color: textSub)),
                      Text(widget.transactionId.substring(0, 8),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textMain)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Order ID:", style: TextStyle(color: textSub)),
                      Text(widget.orderId.substring(mockOrderIdPrefix().length),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textMain)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _completePayment(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("PAY SUCCESS",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _completePayment(false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("PAY DECLINE",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String mockOrderIdPrefix() => "mock_order_";
}
