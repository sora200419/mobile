// lib/features/marketplace/models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String sellerId;
  final String sellerName;
  final String imageUrl;
  final DateTime createdAt;
  final bool isAvailable;

  Product({
    this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.sellerId,
    required this.sellerName,
    required this.imageUrl,
    required this.createdAt,
    this.isAvailable = true,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'isAvailable': isAvailable,
    };
  }
}
