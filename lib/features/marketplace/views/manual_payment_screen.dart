// lib/features/marketplace/views/manual_payment_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobiletesting/features/marketplace/views/payment_success_screen.dart';
import '../models/transaction_model.dart';
import '../services/payment_service.dart';
import '../utils/image_helper.dart';

class ManualPaymentScreen extends StatefulWidget {
  final String transactionId;
  final String paymentMethod;

  const ManualPaymentScreen({
    Key? key,
    required this.transactionId,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  State<ManualPaymentScreen> createState() => _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends State<ManualPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _referenceController = TextEditingController();
  File? _receiptImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body:
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment instructions
                    const Text(
                      'Payment Instructions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Bank transfer instructions
                    if (widget.paymentMethod ==
                        Transaction.METHOD_BANK_TRANSFER)
                      _buildBankInstructions(),

                    // E-wallet instructions
                    if (widget.paymentMethod == Transaction.METHOD_E_WALLET)
                      _buildEWalletInstructions(),

                    const SizedBox(height: 24),

                    // Payment reference input
                    const Text(
                      'Payment Reference',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        hintText: 'Enter transaction ID or reference number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a reference number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Receipt upload
                    const Text(
                      'Upload Payment Receipt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickReceiptImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                        child:
                            _receiptImage != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _receiptImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to upload receipt image',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('SUBMIT PAYMENT'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildBankInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Bank Transfer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Please transfer the payment to:'),
            const SizedBox(height: 8),
            const Text('Bank: Maybank'),
            const Text('Account Number: 1234 5678 9012'),
            const Text('Account Name: Campus Marketplace'),
            const SizedBox(height: 8),
            Text(
              'Important: Include transaction ID "${widget.transactionId.substring(0, 8)}" in the reference',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEWalletInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'E-Wallet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Please transfer the payment to:'),
            const SizedBox(height: 8),
            const Text('E-Wallet: Touch n Go / Boost / GrabPay'),
            const Text('Phone Number: 012-345 6789'),
            const Text('Name: Campus Marketplace'),
            const SizedBox(height: 8),
            Text(
              'Important: Include transaction ID "${widget.transactionId.substring(0, 8)}" in the reference',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReceiptImage() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    final File? image = await ImageHelper.pickImage(
      context: context,
      source: source,
    );

    if (image != null) {
      setState(() => _receiptImage = image);
    }
  }

  Future<void> _submitPayment() async {
    // Validate fields
    if (_referenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a payment reference')),
      );
      return;
    }

    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a receipt image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _paymentService.updateTransactionPayment(
        widget.transactionId,
        _referenceController.text.trim(),
        _receiptImage!,
      );

      if (mounted) {
        // Navigate to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => PaymentSuccessScreen(
                  transactionId: widget.transactionId,
                  showUploadOption: false,
                ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
