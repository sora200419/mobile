// lib/features/marketplace/views/my_transactions_screen.dart
import 'package:flutter/material.dart';
import '../models/transaction_model.dart' as models;
import '../services/payment_service.dart';
import '../widgets/transaction_card.dart';
import 'manual_payment_screen.dart';

class MyTransactionsScreen extends StatefulWidget {
  const MyTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<MyTransactionsScreen> createState() => _MyTransactionsScreenState();
}

class _MyTransactionsScreenState extends State<MyTransactionsScreen>
    with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: const [Tab(text: "Purchases"), Tab(text: "Sales")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Purchases tab
          _buildTransactionsTab(_paymentService.getBuyerTransactions(), true),

          // Sales tab
          _buildTransactionsTab(_paymentService.getSellerTransactions(), false),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(
    Stream<List<models.Transaction>> transactionsStream,
    bool isBuyer,
  ) {
    return StreamBuilder<List<models.Transaction>>(
      stream: transactionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<models.Transaction> transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isBuyer ? Icons.shopping_basket : Icons.store,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  isBuyer ? 'No purchases yet' : 'No sales yet',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            models.Transaction transaction = transactions[index];
            return TransactionCard(
              transaction: transaction,
              isBuyer: isBuyer,
              onActionPressed: () => _handleActionPressed(transaction, isBuyer),
            );
          },
        );
      },
    );
  }

  void _handleActionPressed(models.Transaction transaction, bool isBuyer) {
    if (isBuyer) {
      // Buyer actions
      if (transaction.status == models.Transaction.STATUS_PENDING &&
          transaction.receiptUrl == null &&
          transaction.paymentMethod !=
              models.Transaction.METHOD_CASH_ON_DELIVERY) {
        // Upload payment proof
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ManualPaymentScreen(
                  transactionId: transaction.id!,
                  paymentMethod: transaction.paymentMethod,
                ),
          ),
        );
      } else if (transaction.status == models.Transaction.STATUS_PENDING) {
        // Cancel order
        _showCancelConfirmation(transaction);
      }
    } else {
      // Seller actions
      if (transaction.status == models.Transaction.STATUS_PENDING &&
          transaction.receiptUrl != null) {
        // Confirm payment
        _showConfirmationOptions(transaction);
      }
    }
  }

  void _showCancelConfirmation(models.Transaction transaction) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: const Text('Are you sure you want to cancel this order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('NO'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _paymentService.cancelTransaction(transaction.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order cancelled successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('YES'),
              ),
            ],
          ),
    );
  }

  void _showConfirmationOptions(models.Transaction transaction) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Payment Verification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Verify payment receipt:'),
                const SizedBox(height: 16),
                if (transaction.receiptUrl != null &&
                    transaction.receiptUrl!.isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Image.network(
                      transaction.receiptUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Could not load receipt image'),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Reference: ${transaction.paymentReference ?? "N/A"}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showRejectionDialog(transaction);
                },
                child: const Text('REJECT'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _paymentService.completeTransaction(transaction.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment confirmed successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('CONFIRM'),
              ),
            ],
          ),
    );
  }

  void _showRejectionDialog(models.Transaction transaction) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please provide a reason for rejection:'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Enter reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) {
                    return;
                  }

                  Navigator.pop(context);
                  try {
                    await _paymentService.rejectTransaction(
                      transaction.id!,
                      reasonController.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment rejected')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('SUBMIT'),
              ),
            ],
          ),
    );
  }
}
