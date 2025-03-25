// lib/features/marketplace/views/payment_success_screen.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/features/marketplace/views/manual_payment_screen.dart';
import '../models/transaction_model.dart';
import '../services/payment_service.dart';
import 'my_transactions_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String transactionId;
  final bool showUploadOption;

  const PaymentSuccessScreen({
    Key? key,
    required this.transactionId,
    this.showUploadOption = true,
  }) : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final PaymentService _paymentService = PaymentService();
  Transaction? _transaction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    try {
      final transaction = await _paymentService.getTransactionById(
        widget.transactionId,
      );
      setState(() {
        _transaction = transaction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Success'),
        automaticallyImplyLeading: false,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildSuccessContent(),
    );
  }

  Widget _buildSuccessContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green[700],
              ),
            ),

            const SizedBox(height: 24),

            // Success message
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Transaction info
            if (_transaction != null)
              Text(
                'Your order for ${_transaction!.productTitle} has been placed.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 8),

            Text(
              'Transaction ID: ${widget.transactionId}',
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 24),

            // Payment instructions for Cash on Delivery
            if (_transaction?.paymentMethod ==
                Transaction.METHOD_CASH_ON_DELIVERY)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Cash on Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The seller will contact you to arrange pickup and payment.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            // Payment instructions for other methods
            if (_transaction?.paymentMethod !=
                Transaction.METHOD_CASH_ON_DELIVERY)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Next Steps',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The seller will verify your payment and update the order status.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Upload payment button
            if (widget.showUploadOption &&
                _transaction?.paymentMethod !=
                    Transaction.METHOD_CASH_ON_DELIVERY)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to manual payment screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ManualPaymentScreen(
                              transactionId: widget.transactionId,
                              paymentMethod: _transaction!.paymentMethod,
                            ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('UPLOAD PAYMENT PROOF'),
                ),
              ),

            const SizedBox(height: 16),

            // View transactions button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to transactions screen with proper Material ancestor
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              Scaffold(body: const MyTransactionsScreen()),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('VIEW MY ORDERS'),
              ),
            ),

            const SizedBox(height: 16),

            // Back to home button
            TextButton(
              onPressed: () {
                // Navigate back to marketplace tab
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('BACK TO MARKETPLACE'),
            ),
          ],
        ),
      ),
    );
  }
}
