// lib/features/marketplace/views/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobiletesting/features/marketplace/models/product_model.dart';
import 'package:mobiletesting/features/marketplace/services/marketplace_service.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MarketplaceService _marketplaceService = MarketplaceService();
    final bool isOwner =
        FirebaseAuth.instance.currentUser?.uid == product.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions:
            isOwner
                ? [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'mark_sold') {
                        await _marketplaceService.markProductAsSold(
                          product.id!,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Marked as sold')),
                        );
                        Navigator.pop(context);
                      } else if (value == 'delete') {
                        bool confirm = await _showDeleteConfirmation(context);
                        if (confirm) {
                          await _marketplaceService.deleteProduct(product.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Listing deleted')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                    itemBuilder:
                        (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'mark_sold',
                            child: Text('Mark as Sold'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete Listing'),
                          ),
                        ],
                  ),
                ]
                : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey.shade200,
              child:
                  product.imageUrl.isNotEmpty
                      ? Image.network(product.imageUrl, fit: BoxFit.cover)
                      : const Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey,
                      ),
            ),

            // Product details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'RM ${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Category chip
                  Chip(
                    label: Text(product.category),
                    backgroundColor: Colors.deepPurple.shade50,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(product.description),
                  const SizedBox(height: 16),

                  // Seller info
                  const Text(
                    'Seller',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Text(
                          product.sellerName.isNotEmpty
                              ? product.sellerName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.sellerName),
                            Text(
                              'Listed on ${DateFormat('dd MMM yyyy').format(product.createdAt)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chat button (if not owner)
                  if (!isOwner)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat with Seller'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chat feature coming soon!'),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Listing'),
                content: const Text(
                  'Are you sure you want to delete this listing? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;
  }
}
