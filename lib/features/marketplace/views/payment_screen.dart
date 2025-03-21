// lib/features/marketplace/views/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/features/marketplace/models/payment_model.dart';
import 'package:mobiletesting/features/marketplace/models/product_model.dart';
import 'package:mobiletesting/features/marketplace/services/payment_service.dart';
import 'package:mobiletesting/features/marketplace/views/payment_webview_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final Product product;

  const PaymentScreen({Key? key, required this.product}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order summary
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildOrderItem(
                              widget.product.title,
                              widget.product.price.toStringAsFixed(2),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'RM ${widget.product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment method selection (in this case, just Paynet)
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: RadioListTile(
                        title: Row(
                          children: [
                            Image.asset('assets/paynet_logo.png', height: 40),
                            const SizedBox(width: 8),
                            const Text('Paynet'),
                          ],
                        ),
                        subtitle: const Text(
                          'Pay using online banking or e-wallet',
                        ),
                        value: 'Paynet',
                        groupValue: 'Paynet', // Only one option available
                        onChanged: (value) {},
                        activeColor: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message (if any)
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.red.shade100,
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),

                    // Payment button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _processPayment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Proceed to Payment'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildOrderItem(String title, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(widget.product.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Condition: ${widget.product.condition}'),
              ],
            ),
          ),
          Text(
            'RM $price',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create a payment record
      Payment payment = await _paymentService.createPayment(
        productId: widget.product.id!,
        sellerId: widget.product.sellerId,
        amount: widget.product.price,
      );

      // Initialize payment with Paynet
      Map<String, dynamic> paymentDetails = await _paymentService
          .initializePaynetPayment(payment);

      // Check if we have a payment URL
      String? paymentUrl = paymentDetails['payment_url'];
      if (paymentUrl != null) {
        // Handle the payment URL (either open in browser or WebView)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PaymentWebViewScreen(
                  paymentUrl: paymentUrl,
                  paymentId: payment.id!,
                ),
          ),
        );
      } else {
        throw Exception('No payment URL provided');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment initialization failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
