// lib/features/marketplace/views/my_transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart' as models;
import '../services/payment_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class MyTransactionsScreen extends StatefulWidget {
  const MyTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<MyTransactionsScreen> createState() => _MyTransactionsScreenState();
}

class _MyTransactionsScreenState extends State<MyTransactionsScreen>
    with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  final ChatService _chatService = ChatService();
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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: const [Tab(text: "Purchases"), Tab(text: "Sales")],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Purchases tab
              _buildTransactionsTab(
                _paymentService.getBuyerTransactions(),
                true,
              ),

              // Sales tab
              _buildTransactionsTab(
                _paymentService.getSellerTransactions(),
                false,
              ),
            ],
          ),
        ),
      ],
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
            return _buildTransactionCard(transaction, isBuyer);
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(models.Transaction transaction, bool isBuyer) {
    Color statusColor;
    IconData statusIcon;

    switch (transaction.status) {
      case models.Transaction.STATUS_PENDING:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case models.Transaction.STATUS_COMPLETED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case models.Transaction.STATUS_REJECTED:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case models.Transaction.STATUS_CANCELLED:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        transaction.status,
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat.yMMMd().format(transaction.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            const Divider(),

            // Transaction details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),

                const SizedBox(width: 12),

                // Product and transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.productTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBuyer
                            ? 'Seller: ${transaction.sellerName}'
                            : 'Buyer: ${transaction.buyerName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payment: ${transaction.paymentMethod}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Price
                Text(
                  'RM ${transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            // Rejection reason (if any)
            if (transaction.status == models.Transaction.STATUS_REJECTED &&
                transaction.rejectionReason != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejected: ${transaction.rejectionReason}',
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Action buttons
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Chat button
                  OutlinedButton.icon(
                    onPressed: () => _openChat(transaction),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Action button based on status and role
                  if (isBuyer &&
                      transaction.status == models.Transaction.STATUS_PENDING)
                    OutlinedButton.icon(
                      onPressed: () => _cancelTransaction(transaction.id!),
                      icon: const Icon(
                        Icons.cancel,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),

                  if (!isBuyer &&
                      transaction.status == models.Transaction.STATUS_PENDING)
                    ElevatedButton.icon(
                      onPressed: () => _confirmTransaction(transaction.id!),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Confirm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChat(models.Transaction transaction) async {
    try {
      // Get chat for this transaction
      final chat = await _chatService.getChatByTransactionId(transaction.id!);

      if (chat != null && mounted) {
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(chatId: chat.id!)),
        );
      } else {
        // Create a new chat if one doesn't exist
        final chatId = await _chatService.createChat(transaction);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatId)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
      }
    }
  }

  Future<void> _cancelTransaction(String transactionId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Cancel Order'),
                content: const Text(
                  'Are you sure you want to cancel this order?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('NO'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('YES'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    try {
      await _paymentService.cancelTransaction(transactionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmTransaction(String transactionId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Order'),
                content: const Text('Mark this order as completed?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('CONFIRM'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    try {
      await _paymentService.completeTransaction(transactionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order confirmed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
