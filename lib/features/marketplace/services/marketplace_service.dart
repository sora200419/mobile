// lib/features/marketplace/services/marketplace_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:campuslink/features/marketplace/services/cloudinary_service.dart';
import '../models/product_model.dart';

class MarketplaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get _productsRef => _firestore.collection('products');
  CollectionReference get _favoritesRef => _firestore.collection('favorites');
  CollectionReference get _usersRef => _firestore.collection('users');

  // Get available products stream
  Stream<List<Product>> getAvailableProducts() {
    return _productsRef
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
    if (category == 'All') {
      return getAvailableProducts();
    }

    return _productsRef
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: Product.STATUS_AVAILABLE)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  // Search products
  Stream<List<Product>> searchProducts(String query) {
    // Convert query to lowercase for case-insensitive search
    String lowercaseQuery = query.toLowerCase();

    // Get all available products and filter on the client side
    return _productsRef
        .where('status', isEqualTo: Product.STATUS_AVAILABLE)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          List<Product> allProducts =
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

          return allProducts.where((product) {
            return product.title.toLowerCase().contains(lowercaseQuery) ||
                product.description.toLowerCase().contains(lowercaseQuery) ||
                product.category.toLowerCase().contains(lowercaseQuery) ||
                product.location.toLowerCase().contains(lowercaseQuery);
          }).toList();
        });
  }

  // Get my products (user's listings)
  Stream<List<Product>> getMyProducts() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _productsRef
        .where('sellerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  // Get favorite products for current user
  Stream<List<Product>> getFavoriteProducts() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Get the IDs of favorite products
    return _favoritesRef
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((favSnapshot) async {
          List<String> favoriteIds =
              favSnapshot.docs
                  .map((doc) => doc['productId'] as String)
                  .toList();

          if (favoriteIds.isEmpty) {
            return [];
          }

          // Get the actual product documents
          // We need to do this in batches if there are many favorites
          List<Product> products = [];

          // Process in batches of 10 (Firestore limitation for 'in' queries)
          for (int i = 0; i < favoriteIds.length; i += 10) {
            int end =
                (i + 10 < favoriteIds.length) ? i + 10 : favoriteIds.length;
            List<String> batch = favoriteIds.sublist(i, end);

            QuerySnapshot querySnapshot =
                await _productsRef
                    .where(FieldPath.documentId, whereIn: batch)
                    .get();

            List<Product> batchProducts =
                querySnapshot.docs
                    .map((doc) => Product.fromFirestore(doc))
                    .toList();

            products.addAll(batchProducts);
          }

          return products;
        });
  }

  // Check if a product is in favorites
  Future<bool> isProductFavorite(String productId) async {
    if (currentUserId == null) {
      return false;
    }

    QuerySnapshot querySnapshot =
        await _favoritesRef
            .where('userId', isEqualTo: currentUserId)
            .where('productId', isEqualTo: productId)
            .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Add a product to favorites
  Future<void> addToFavorites(String productId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _favoritesRef.add({
      'userId': currentUserId,
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove a product from favorites
  Future<void> removeFromFavorites(String productId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    QuerySnapshot querySnapshot =
        await _favoritesRef
            .where('userId', isEqualTo: currentUserId)
            .where('productId', isEqualTo: productId)
            .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Add a new product
  Future<String> addProduct(Product product) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Get the seller name from users collection
    DocumentSnapshot userDoc = await _usersRef.doc(currentUserId).get();
    String sellerName = (userDoc.data() as Map<String, dynamic>)['name'] ?? '';

    // Create a product with the seller info
    Product productWithSeller = product.copyWith(
      sellerId: currentUserId,
      sellerName: sellerName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add to Firestore
    DocumentReference docRef = await _productsRef.add(
      productWithSeller.toFirestore(),
    );
    return docRef.id;
  }

  // Update a product
  Future<void> updateProduct(Product product) async {
    if (product.id == null) {
      throw Exception('Product ID is required for update');
    }

    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if the user is the owner of the product
    DocumentSnapshot docSnapshot = await _productsRef.doc(product.id).get();
    Product existingProduct = Product.fromFirestore(docSnapshot);

    if (existingProduct.sellerId != currentUserId) {
      throw Exception('Only the seller can update this product');
    }

    // Update the product with new updatedAt timestamp
    await _productsRef
        .doc(product.id)
        .update(product.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if the user is the owner of the product
    DocumentSnapshot docSnapshot = await _productsRef.doc(productId).get();
    Product product = Product.fromFirestore(docSnapshot);

    if (product.sellerId != currentUserId) {
      throw Exception('Only the seller can delete this product');
    }

    // Delete the product
    await _productsRef.doc(productId).delete();

    // Log image URLs that would need cleanup in Cloudinary
    if (product.imageUrl.isNotEmpty) {
      print(
        'Note: Image at ${product.imageUrl} should be removed from Cloudinary',
      );
    }

    for (String imageUrl in product.additionalImages) {
      print('Note: Image at ${imageUrl} should be removed from Cloudinary');
    }

    // Delete associated favorites
    QuerySnapshot favoritesSnapshot =
        await _favoritesRef.where('productId', isEqualTo: productId).get();

    for (var doc in favoritesSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Update product status (available, reserved, sold)
  Future<void> updateProductStatus(String productId, String status) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if the user is the owner of the product
    DocumentSnapshot docSnapshot = await _productsRef.doc(productId).get();
    Product product = Product.fromFirestore(docSnapshot);

    if (product.sellerId != currentUserId) {
      throw Exception('Only the seller can update this product status');
    }

    // Update status
    await _productsRef.doc(productId).update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // NEW METHOD: Update product status during transaction (no seller check)
  Future<void> updateProductStatusForTransaction(
    String productId,
    String status,
  ) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Update status without checking if user is seller
    await _productsRef.doc(productId).update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Upload an image to Cloudinary
  Future<String> uploadImage(File imageFile, {String? productId}) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Create a folder path for organizing images
    String folder = 'marketplace/${currentUserId}/${productId ?? 'products'}';

    // Upload using Cloudinary service
    String downloadUrl = await _cloudinaryService.uploadImage(
      imageFile,
      folder: folder,
    );

    return downloadUrl;
  }

  // Pick an image from gallery or camera
  Future<File?> pickImage({required ImageSource source}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80, // Reduce image quality to save storage
      maxWidth: 800, // Resize to reasonable dimensions
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }

    return null;
  }

  // Get product details by ID
  Future<Product?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _productsRef.doc(productId).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Get seller details
  Future<Map<String, dynamic>> getSellerInfo(String sellerId) async {
    try {
      DocumentSnapshot doc = await _usersRef.doc(sellerId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'role': data['role'] ?? '',
        };
      }
      return {'name': 'Unknown User'};
    } catch (e) {
      print('Error getting seller info: $e');
      return {'name': 'Unknown User'};
    }
  }

  // Contact seller (send message to the seller)
  // This is a placeholder - in a real app, this would use a messaging service
  Future<void> contactSeller(String sellerId, String message) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // This is where you would integrate with your messaging system
    // For now, we'll just print the message
    print('Message to $sellerId: $message');
  }

  // Get optimized version of a Cloudinary image URL
  String getOptimizedImageUrl(
    String originalUrl, {
    int width = 800,
    int height = 600,
    int quality = 80,
  }) {
    return _cloudinaryService.getOptimizedImageUrl(
      originalUrl,
      width: width,
      height: height,
      quality: quality,
    );
  }
}
