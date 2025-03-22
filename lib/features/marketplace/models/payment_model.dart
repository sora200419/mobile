// lib/features/marketplace/models/payment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, processing, completed, failed, cancelled }

class Payment {
  final String? id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final double amount;
  final String paymentMethod; // "Paynet" or other methods you might add later
  final String status;
  final DateTime createdAt;
  final String? transactionId; // Paynet transaction ID
  final Map<String, dynamic>? paymentDetails;

  Payment({
    this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.transactionId,
    this.paymentDetails,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      productId: data['productId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      transactionId: data['transactionId'],
      paymentDetails: data['paymentDetails'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt,
      'transactionId': transactionId,
      'paymentDetails': paymentDetails,
    };
  }
}
