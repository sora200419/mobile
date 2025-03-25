// lib/features/marketplace/widgets/transaction_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart' as models;

class TransactionCard extends StatelessWidget {
  final models.Transaction transaction;
  final bool isBuyer;
  final VoidCallback? onActionPressed;

  const TransactionCard({
    Key? key,
    required this.transaction,
    required this.isBuyer,
    this.onActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                _buildStatusLabel(transaction.status),
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

            // Action buttons based on status and role
            if (_shouldShowActionButton())
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getActionButtonColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(_getActionButtonText()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLabel(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case models.Transaction.STATUS_PENDING:
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case models.Transaction.STATUS_COMPLETED:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case models.Transaction.STATUS_REJECTED:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case models.Transaction.STATUS_CANCELLED:
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  bool _shouldShowActionButton() {
    if (isBuyer) {
      // Buyer actions
      if (transaction.status == models.Transaction.STATUS_PENDING) {
        if (transaction.paymentMethod ==
            models.Transaction.METHOD_CASH_ON_DELIVERY) {
          return true; // Can cancel
        } else if (transaction.receiptUrl == null) {
          return true; // Can upload payment
        } else {
          return true; // Can cancel
        }
      }
      return false;
    } else {
      // Seller actions
      return transaction.status == models.Transaction.STATUS_PENDING &&
          transaction.receiptUrl != null;
    }
  }

  Color _getActionButtonColor() {
    if (isBuyer) {
      if (transaction.paymentMethod !=
              models.Transaction.METHOD_CASH_ON_DELIVERY &&
          transaction.receiptUrl == null) {
        return Colors.deepPurple;
      } else {
        return Colors.red;
      }
    } else {
      return Colors.green;
    }
  }

  String _getActionButtonText() {
    if (isBuyer) {
      if (transaction.paymentMethod !=
              models.Transaction.METHOD_CASH_ON_DELIVERY &&
          transaction.receiptUrl == null) {
        return 'UPLOAD PAYMENT';
      } else {
        return 'CANCEL ORDER';
      }
    } else {
      return 'VERIFY PAYMENT';
    }
  }
}
