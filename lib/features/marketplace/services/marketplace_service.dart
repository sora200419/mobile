// lib/features/marketplace/services/marketplace_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobiletesting/features/marketplace/models/product_model.dart';

class MarketplaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new product listing
  Future<String> addProduct(Product product) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('products')
          .add(product.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding product: $e');
      throw e;
    }
  }

  // Get all available products
  Stream<List<Product>> getAvailableProducts() {
    return _firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  // Get my products
  Stream<List<Product>> getMyProducts() {
    String userId = _auth.currentUser?.uid ?? '';

    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  // Mark a product as sold
  Future<void> markProductAsSold(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isAvailable': false,
      });
    } catch (e) {
      print('Error marking product as sold: $e');
      throw e;
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      print('Error deleting product: $e');
      throw e;
    }
  }

  // Search products
  Stream<List<Product>> searchProducts(String query) {
    query = query.toLowerCase();

    return _firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .where(
                (product) =>
                    product.title.toLowerCase().contains(query) ||
                    product.description.toLowerCase().contains(query),
              )
              .toList();
        });
  }
}
