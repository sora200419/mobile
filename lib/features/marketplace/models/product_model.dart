// lib\features\marketplace\models\product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final String sellerId;
  final String sellerName;
  final List<String> imageUrls;
  final DateTime createdAt;
  final String status;
  final bool isFeatured;
  final int viewCount;
  final String location;

  // Constants for product status
  static const String STATUS_AVAILABLE = 'Available';
  static const String STATUS_RESERVED = 'Reserved';
  static const String STATUS_SOLD = 'Sold';

  // Constants for product condition
  static const String CONDITION_NEW = 'New';
  static const String CONDITION_LIKE_NEW = 'Like New';
  static const String CONDITION_GOOD = 'Good';
  static const String CONDITION_FAIR = 'Fair';
  static const String CONDITION_POOR = 'Poor';

  Product({
    this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.sellerId,
    required this.sellerName,
    required this.imageUrls,
    required this.createdAt,
    this.status = STATUS_AVAILABLE,
    this.isFeatured = false,
    this.viewCount = 0,
    this.location = '',
  });

  // For backward compatibility with single image URLs
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls[0] : '';

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle both single imageUrl and multiple imageUrls for compatibility
    List<String> images = [];
    if (data['imageUrls'] != null) {
      images = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null) {
      images = [data['imageUrl']];
    }

    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      condition: data['condition'] ?? CONDITION_GOOD,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      imageUrls: images,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? STATUS_AVAILABLE,
      isFeatured: data['isFeatured'] ?? false,
      viewCount: data['viewCount'] ?? 0,
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'status': status,
      'isFeatured': isFeatured,
      'viewCount': viewCount,
      'location': location,
    };
  }

  // Create a copy of this product with updated fields
  Product copyWith({
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    List<String>? imageUrls,
    String? status,
    bool? isFeatured,
    int? viewCount,
    String? location,
  }) {
    return Product(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      sellerId: this.sellerId,
      sellerName: this.sellerName,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: this.createdAt,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      viewCount: viewCount ?? this.viewCount,
      location: location ?? this.location,
    );
  }
}
