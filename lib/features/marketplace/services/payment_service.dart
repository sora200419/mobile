// lib/features/marketplace/services/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobiletesting/features/marketplace/models/payment_model.dart';
import 'package:mobiletesting/features/marketplace/models/product_model.dart';
import 'package:mobiletesting/features/marketplace/services/marketplace_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MarketplaceService _marketplaceService = MarketplaceService();

  // Paynet API credentials and endpoints
  final String _apiKey = 'your_paynet_api_key';
  final String _secretKey = 'your_paynet_secret_key';
  final String _baseUrl =
      'https://api.paynet.my'; // Replace with the actual Paynet API URL

  // Create a new payment
  Future<Payment> createPayment({
    required String productId,
    required String sellerId,
    required double amount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final payment = Payment(
      productId: productId,
      buyerId: user.uid,
      sellerId: sellerId,
      amount: amount,
      paymentMethod: 'Paynet',
      status: 'pending',
      createdAt: DateTime.now(),
    );

    DocumentReference docRef = await _firestore
        .collection('payments')
        .add(payment.toMap());
    return payment.copyWith(id: docRef.id);
  }

  // Initialize a Paynet payment
  Future<Map<String, dynamic>> initializePaynetPayment(Payment payment) async {
    try {
      // Get product details
      DocumentSnapshot productDoc =
          await _firestore.collection('products').doc(payment.productId).get();
      Product product = Product.fromFirestore(productDoc);

      // Get buyer details
      DocumentSnapshot buyerDoc =
          await _firestore.collection('users').doc(payment.buyerId).get();
      Map<String, dynamic> buyerData = buyerDoc.data() as Map<String, dynamic>;

      // Prepare the request payload for Paynet
      final payload = {
        'amount': payment.amount,
        'currency': 'MYR',
        'description': 'Payment for ${product.title}',
        'reference_id': payment.id,
        'callback_url':
            'https://yourdomain.com/api/payment/callback', // Replace with your actual callback URL
        'redirect_url':
            'campuslink://payment/completed', // Deep link for your app
        'customer_details': {
          'name': buyerData['name'] ?? '',
          'email': buyerData['email'] ?? '',
          'phone': buyerData['phone'] ?? '',
        },
      };

      // Make the API request to Paynet
      final response = await http.post(
        Uri.parse('${_baseUrl}/v1/payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);

        // Update payment with transaction ID
        await _firestore.collection('payments').doc(payment.id).update({
          'transactionId': responseData['transaction_id'],
          'paymentDetails': responseData,
        });

        return responseData;
      } else {
        throw Exception('Payment initialization failed: ${response.body}');
      }
    } catch (e) {
      print('Error initializing Paynet payment: $e');
      throw e;
    }
  }

  // Process Paynet payment status update
  Future<void> updatePaymentStatus(
    String paymentId,
    String status,
    Map<String, dynamic> details,
  ) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': status,
        'paymentDetails': FieldValue.arrayUnion([details]),
      });

      // If payment is completed, update product status
      if (status == 'completed') {
        DocumentSnapshot paymentDoc =
            await _firestore.collection('payments').doc(paymentId).get();
        Payment payment = Payment.fromFirestore(paymentDoc);

        // Mark product as sold and record the buyer
        await _firestore.collection('products').doc(payment.productId).update({
          'status': Product.STATUS_SOLD,
          'buyerId': payment.buyerId,
          'soldAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating payment status: $e');
      throw e;
    }
  }

  // Get a specific payment
  Future<Payment?> getPayment(String paymentId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('payments').doc(paymentId).get();
      if (doc.exists) {
        return Payment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting payment: $e');
      throw e;
    }
  }

  // Get payments for a user (either as buyer or seller)
  Stream<List<Payment>> getUserPayments({bool asBuyer = true}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    String field = asBuyer ? 'buyerId' : 'sellerId';

    return _firestore
        .collection('payments')
        .where(field, isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Payment.fromFirestore(doc))
              .toList();
        });
  }
}

extension PaymentExtension on Payment {
  Payment copyWith({
    String? id,
    String? productId,
    String? buyerId,
    String? sellerId,
    double? amount,
    String? paymentMethod,
    String? status,
    DateTime? createdAt,
    String? transactionId,
    Map<String, dynamic>? paymentDetails,
  }) {
    return Payment(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      transactionId: transactionId ?? this.transactionId,
      paymentDetails: paymentDetails ?? this.paymentDetails,
    );
  }
}
