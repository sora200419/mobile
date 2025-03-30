// lib/features/marketplace/views/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:campuslink/features/marketplace/views/payment_success_screen.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../services/payment_service.dart';
import 'manual_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Product product;

  const CheckoutScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body:
          _isProcessing
              ? const Center(child: CircularProgressIndicator())
              : _buildCheckoutContent(),
    );
  }

  Widget _buildCheckoutContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order summary
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Product info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        widget.product.imageUrl.isNotEmpty
                            ? Image.network(
                              widget.product.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                            : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                  const SizedBox(width: 16),

                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Condition: ${widget.product.condition}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seller: ${widget.product.sellerName}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Text(
                    'RM ${widget.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Payment methods
          const Text(
            'Select Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Bank transfer option
          _buildPaymentMethodCard(
            title: 'Bank Transfer',
            icon: Icons.account_balance,
            onTap: () => _processPayment(Transaction.METHOD_BANK_TRANSFER),
          ),

          const SizedBox(height: 12),

          // E-wallet option
          _buildPaymentMethodCard(
            title: 'E-Wallet',
            icon: Icons.account_balance_wallet,
            onTap: () => _processPayment(Transaction.METHOD_E_WALLET),
          ),

          const SizedBox(height: 12),

          // Cash on delivery option
          _buildPaymentMethodCard(
            title: 'Meet-up Payment',
            icon: Icons.money,
            onTap: () => _processPayment(Transaction.METHOD_CASH_ON_DELIVERY),
          ),

          const Spacer(),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:', style: TextStyle(fontSize: 16)),
                Text(
                  'RM ${widget.product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.deepPurple, size: 28),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(String paymentMethod) async {
    setState(() => _isProcessing = true);

    try {
      // Create transaction
      String transactionId = await _paymentService.createTransaction(
        widget.product,
        paymentMethod,
      );

      if (mounted) {
        setState(() => _isProcessing = false);

        // Navigate to appropriate payment screen based on method
        if (paymentMethod == Transaction.METHOD_CASH_ON_DELIVERY) {
          // For COD, just show success screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PaymentSuccessScreen(
                    transactionId: transactionId,
                    showUploadOption: false,
                  ),
            ),
          );
        } else {
          // For bank transfer and e-wallet, show manual payment screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ManualPaymentScreen(
                    transactionId: transactionId,
                    paymentMethod: paymentMethod,
                  ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
