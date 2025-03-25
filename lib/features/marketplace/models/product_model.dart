// lib/features/marketplace/models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String? id;
  String sellerId;
  String sellerName;
  String title;
  String description;
  double price;
  String category;
  String condition;
  String location;
  String imageUrl;
  List<String> additionalImages;
  String status;
  DateTime createdAt;
  DateTime updatedAt;

  // Constants for status
  static const String STATUS_AVAILABLE = 'Available';
  static const String STATUS_RESERVED = 'Reserved';
  static const String STATUS_SOLD = 'Sold';

  // Constants for condition
  static const String CONDITION_NEW = 'New';
  static const String CONDITION_LIKE_NEW = 'Like New';
  static const String CONDITION_GOOD = 'Good';
  static const String CONDITION_FAIR = 'Fair';
  static const String CONDITION_POOR = 'Poor';

  Product({
    this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.location,
    required this.imageUrl,
    this.additionalImages = const [],
    this.status = STATUS_AVAILABLE,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Factory method to create Product from Firestore data
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price:
          (data['price'] is int)
              ? (data['price'] as int).toDouble()
              : (data['price'] ?? 0.0),
      category: data['category'] ?? '',
      condition: data['condition'] ?? '',
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      additionalImages: List<String>.from(data['additionalImages'] ?? []),
      status: data['status'] ?? STATUS_AVAILABLE,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Product to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'location': location,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Create a copy of the product with updated fields
  Product copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    String? location,
    String? imageUrl,
    List<String>? additionalImages,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
