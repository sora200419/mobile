// lib/features/marketplace/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  String? id;
  String productId;
  String productTitle;
  String buyerId;
  String buyerName;
  String sellerId;
  String sellerName;
  double amount;
  String paymentMethod;
  String status;
  String? paymentReference;
  String? receiptUrl;
  String? rejectionReason;
  DateTime createdAt;
  DateTime? updatedAt;

  // Constants for status
  static const String STATUS_PENDING = 'Pending';
  static const String STATUS_COMPLETED = 'Completed';
  static const String STATUS_REJECTED = 'Rejected';
  static const String STATUS_CANCELLED = 'Cancelled';

  // Constants for payment methods
  static const String METHOD_BANK_TRANSFER = 'Bank Transfer';
  static const String METHOD_CASH_ON_DELIVERY = 'Cash on Delivery';
  static const String METHOD_E_WALLET = 'E-Wallet';

  Transaction({
    this.id,
    required this.productId,
    required this.productTitle,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.amount,
    required this.paymentMethod,
    this.status = STATUS_PENDING,
    this.paymentReference,
    this.receiptUrl,
    this.rejectionReason,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Factory method to create Transaction from Firestore data
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Transaction(
      id: doc.id,
      productId: data['productId'] ?? '',
      productTitle: data['productTitle'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      amount:
          (data['amount'] is int)
              ? (data['amount'] as int).toDouble()
              : (data['amount'] ?? 0.0),
      paymentMethod: data['paymentMethod'] ?? '',
      status: data['status'] ?? STATUS_PENDING,
      paymentReference: data['paymentReference'],
      receiptUrl: data['receiptUrl'],
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert Transaction to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productTitle': productTitle,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'paymentReference': paymentReference,
      'receiptUrl': receiptUrl,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create a copy of the transaction with updated fields
  Transaction copyWith({
    String? id,
    String? productId,
    String? productTitle,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    String? sellerName,
    double? amount,
    String? paymentMethod,
    String? status,
    String? paymentReference,
    String? receiptUrl,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      paymentReference: paymentReference ?? this.paymentReference,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
