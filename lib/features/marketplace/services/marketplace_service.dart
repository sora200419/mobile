// lib\features\marketplace\services\marketplace_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mobiletesting/features/marketplace/models/product_model.dart';

class MarketplaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Add a new product listing with multiple images
  Future<String> addProduct(Product product, List<File> imageFiles) async {
    try {
      // Upload all images and get their URLs
      List<String> imageUrls = await uploadProductImages(imageFiles);

      // Create a new product with the image URLs
      Product newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        category: product.category,
        condition: product.condition,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        imageUrls: imageUrls,
        createdAt: product.createdAt,
        location: product.location,
      );

      // Add product to Firestore
      DocumentReference docRef = await _firestore
          .collection('products')
          .add(newProduct.toMap());

      return docRef.id;
    } catch (e) {
      print('Error adding product: $e');
      throw e;
    }
  }

  // Upload multiple product images
  Future<List<String>> uploadProductImages(List<File> imageFiles) async {
    List<String> imageUrls = [];

    if (imageFiles.isEmpty) {
      return imageUrls;
    }

    try {
      for (int i = 0; i < imageFiles.length; i++) {
        final storageRef = _storage.ref();
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_$i';
        final imageRef = storageRef.child('product_images/$fileName');

        await imageRef.putFile(imageFiles[i]);
        String downloadUrl = await imageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } catch (e) {
      print('Error uploading images: $e');
      throw e;
    }
  }

  // Get all available products
  Stream<List<Product>> getAvailableProducts() {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: Product.STATUS_AVAILABLE)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: Product.STATUS_AVAILABLE)
        .where('category', isEqualTo: category)
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

  // Change product status (Available, Reserved, Sold)
  Future<void> updateProductStatus(String productId, String status) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating product status: $e');
      throw e;
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      // Get the product to find its images
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();
      Product product = Product.fromFirestore(doc);

      // Delete the product document
      await _firestore.collection('products').doc(productId).delete();

      // Delete all associated images from storage
      for (String imageUrl in product.imageUrls) {
        try {
          // Extract the path from the URL
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting image: $e');
          // Continue with other images even if one fails
        }
      }
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
        .where('status', isEqualTo: Product.STATUS_AVAILABLE)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .where(
                (product) =>
                    product.title.toLowerCase().contains(query) ||
                    product.description.toLowerCase().contains(query) ||
                    product.category.toLowerCase().contains(query),
              )
              .toList();
        });
  }

  // Increment view count
  Future<void> incrementViewCount(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
      // Silent fail - not critical
    }
  }

  // Get recently viewed products
  Future<List<Product>> getRecentlyViewedProducts(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) {
      return [];
    }

    try {
      // Get all products in the list of IDs
      final querySnapshot =
          await _firestore
              .collection('products')
              .where(FieldPath.documentId, whereIn: productIds)
              .get();

      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting recently viewed products: $e');
      return [];
    }
  }

  // Filter products by price range
  Stream<List<Product>> filterProductsByPrice(
    double minPrice,
    double maxPrice,
  ) {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: Product.STATUS_AVAILABLE)
        .where('price', isGreaterThanOrEqualTo: minPrice)
        .where('price', isLessThanOrEqualTo: maxPrice)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  // Add a product to favorites
  Future<void> addToFavorites(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(productId)
          .set({'addedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Error adding to favorites: $e');
      throw e;
    }
  }

  // Remove a product from favorites
  Future<void> removeFromFavorites(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(productId)
          .delete();
    } catch (e) {
      print('Error removing from favorites: $e');
      throw e;
    }
  }

  // Check if a product is in favorites
  Future<bool> isProductFavorite(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .doc(productId)
              .get();

      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Get all favorite products
  Stream<List<Product>> getFavoriteProducts() {
    final user = _auth.currentUser;
    if (user == null) {
      // Return empty stream if no user is logged in
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .asyncMap((snapshot) async {
          List<String> productIds = snapshot.docs.map((doc) => doc.id).toList();

          if (productIds.isEmpty) {
            return [];
          }

          // Get products by chunks of 10 (Firestore limitation for whereIn)
          List<Product> products = [];
          for (int i = 0; i < productIds.length; i += 10) {
            final endIdx =
                i + 10 < productIds.length ? i + 10 : productIds.length;
            final chunk = productIds.sublist(i, endIdx);

            final querySnapshot =
                await _firestore
                    .collection('products')
                    .where(FieldPath.documentId, whereIn: chunk)
                    .get();

            products.addAll(
              querySnapshot.docs
                  .map((doc) => Product.fromFirestore(doc))
                  .toList(),
            );
          }

          return products;
        });
  }
}
