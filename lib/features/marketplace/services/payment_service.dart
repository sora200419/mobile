// lib/features/marketplace/services/payment_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart' as models;
import 'marketplace_service.dart';
import 'cloudinary_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final MarketplaceService _marketplaceService = MarketplaceService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get _transactionsRef =>
      _firestore.collection('transactions');
  CollectionReference get _notificationsRef =>
      _firestore.collection('notifications');
  CollectionReference get _usersRef => _firestore.collection('users');

  // Create a new transaction
  Future<String> createTransaction(
    Product product,
    String paymentMethod,
  ) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Get current user info
    DocumentSnapshot userDoc = await _usersRef.doc(currentUserId).get();
    String buyerName = (userDoc.data() as Map<String, dynamic>)['name'] ?? '';

    // Create transaction
    models.Transaction transaction = models.Transaction(
      productId: product.id!,
      productTitle: product.title,
      buyerId: currentUserId!,
      buyerName: buyerName,
      sellerId: product.sellerId,
      sellerName: product.sellerName,
      amount: product.price,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );

    // Add to Firestore
    DocumentReference docRef = await _transactionsRef.add(
      transaction.toFirestore(),
    );

    // Update product status to reserved - use the new method instead of updateProductStatus
    await _marketplaceService.updateProductStatusForTransaction(
      product.id!,
      Product.STATUS_RESERVED,
    );

    // Notify seller
    await _notificationsRef.add({
      'userId': product.sellerId,
      'title': 'New Order',
      'message': 'You have a new order for ${product.title}',
      'read': false,
      'createdAt': Timestamp.now(),
    });

    return docRef.id;
  }

  // Update transaction with payment details
  Future<void> updateTransactionPayment(
    String transactionId,
    String paymentReference,
    File receiptImage,
  ) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if transaction exists and belongs to the current user
    DocumentSnapshot doc = await _transactionsRef.doc(transactionId).get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    models.Transaction transaction = models.Transaction.fromFirestore(doc);

    if (transaction.buyerId != currentUserId) {
      throw Exception('You are not authorized to update this transaction');
    }

    // Upload receipt image
    String folder = 'marketplace/payments/$transactionId';
    String receiptUrl = await _cloudinaryService.uploadImage(
      receiptImage,
      folder: folder,
    );

    // Update transaction
    await _transactionsRef.doc(transactionId).update({
      'paymentReference': paymentReference,
      'receiptUrl': receiptUrl,
      'updatedAt': Timestamp.now(),
    });

    // Notify seller about payment proof
    await _notificationsRef.add({
      'userId': transaction.sellerId,
      'title': 'Payment Submitted',
      'message':
          'Payment proof has been submitted for ${transaction.productTitle}',
      'read': false,
      'createdAt': Timestamp.now(),
    });
  }

  // Complete transaction (seller confirms payment)
  Future<void> completeTransaction(String transactionId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if transaction exists and the current user is the seller
    DocumentSnapshot doc = await _transactionsRef.doc(transactionId).get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    models.Transaction transaction = models.Transaction.fromFirestore(doc);

    if (transaction.sellerId != currentUserId) {
      throw Exception('Only the seller can confirm this transaction');
    }

    // Update transaction status
    await _transactionsRef.doc(transactionId).update({
      'status': models.Transaction.STATUS_COMPLETED,
      'updatedAt': Timestamp.now(),
    });

    // Update product status to sold - use the new method instead of updateProductStatus
    await _marketplaceService.updateProductStatusForTransaction(
      transaction.productId,
      Product.STATUS_SOLD,
    );

    // Notify buyer
    await _notificationsRef.add({
      'userId': transaction.buyerId,
      'title': 'Payment Confirmed',
      'message':
          'Your payment for ${transaction.productTitle} has been confirmed',
      'read': false,
      'createdAt': Timestamp.now(),
    });
  }

  // Reject transaction (seller rejects payment)
  Future<void> rejectTransaction(
    String transactionId,
    String rejectionReason,
  ) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if transaction exists and the current user is the seller
    DocumentSnapshot doc = await _transactionsRef.doc(transactionId).get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    models.Transaction transaction = models.Transaction.fromFirestore(doc);

    if (transaction.sellerId != currentUserId) {
      throw Exception('Only the seller can reject this transaction');
    }

    // Update transaction status
    await _transactionsRef.doc(transactionId).update({
      'status': models.Transaction.STATUS_REJECTED,
      'rejectionReason': rejectionReason,
      'updatedAt': Timestamp.now(),
    });

    // Update product status back to available - use the new method instead of updateProductStatus
    await _marketplaceService.updateProductStatusForTransaction(
      transaction.productId,
      Product.STATUS_AVAILABLE,
    );

    // Notify buyer
    await _notificationsRef.add({
      'userId': transaction.buyerId,
      'title': 'Payment Rejected',
      'message':
          'Your payment for ${transaction.productTitle} was rejected: $rejectionReason',
      'read': false,
      'createdAt': Timestamp.now(),
    });
  }

  // Cancel transaction (buyer cancels)
  Future<void> cancelTransaction(String transactionId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if transaction exists and the current user is the buyer
    DocumentSnapshot doc = await _transactionsRef.doc(transactionId).get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    models.Transaction transaction = models.Transaction.fromFirestore(doc);

    if (transaction.buyerId != currentUserId) {
      throw Exception('Only the buyer can cancel this transaction');
    }

    // Update transaction status
    await _transactionsRef.doc(transactionId).update({
      'status': models.Transaction.STATUS_CANCELLED,
      'updatedAt': Timestamp.now(),
    });

    // Update product status back to available - use the new method instead of updateProductStatus
    await _marketplaceService.updateProductStatusForTransaction(
      transaction.productId,
      Product.STATUS_AVAILABLE,
    );

    // Notify seller
    await _notificationsRef.add({
      'userId': transaction.sellerId,
      'title': 'Order Cancelled',
      'message':
          'Order for ${transaction.productTitle} has been cancelled by the buyer',
      'read': false,
      'createdAt': Timestamp.now(),
    });
  }

  // Get buyer transactions
  Stream<List<models.Transaction>> getBuyerTransactions() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _transactionsRef
        .where('buyerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => models.Transaction.fromFirestore(doc))
              .toList();
        });
  }

  // Get seller transactions
  Stream<List<models.Transaction>> getSellerTransactions() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _transactionsRef
        .where('sellerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => models.Transaction.fromFirestore(doc))
              .toList();
        });
  }

  // Get transaction by ID
  Future<models.Transaction?> getTransactionById(String transactionId) async {
    try {
      DocumentSnapshot doc = await _transactionsRef.doc(transactionId).get();
      if (doc.exists) {
        return models.Transaction.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting transaction: $e');
      return null;
    }
  }

  // Get pending transactions count (for sellers)
  Stream<int> getPendingTransactionsCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _transactionsRef
        .where('sellerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: models.Transaction.STATUS_PENDING)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
