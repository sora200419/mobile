// lib/features/marketplace/models/product_review.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductReview {
  String? id;
  String productId;
  String reviewerId;
  String reviewerName;
  String text;
  int rating;
  DateTime createdAt;

  ProductReview({
    this.id,
    required this.productId,
    required this.reviewerId,
    required this.reviewerName,
    required this.text,
    required this.rating,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ProductReview.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ProductReview(
      id: doc.id,
      productId: data['productId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? '',
      text: data['text'] ?? '',
      rating: data['rating'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'text': text,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
