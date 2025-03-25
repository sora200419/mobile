import 'package:flutter/material.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ProductDetailsPage({
    Key? key,
    required this.productId,
    required this.productData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(productData['title'] ?? 'Product Details'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if (productData['imageUrl'] != null &&
                  productData['imageUrl'].toString().isNotEmpty)
                Center(
                  child: Image.network(
                    productData['imageUrl'],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 200,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                const Center(
                  child: Icon(
                    Icons.image,
                    size: 200,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(height: 16),

              Text(
                productData['title'] ?? 'No Title',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                "Price: \$${productData['price']?.toString() ?? 'N/A'}",
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                "Seller: ${productData['sellerName'] ?? 'Unknown'}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              Text(
                "Status: ${productData['status'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              Text(
                "Category: ${productData['category'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              Text(
                "Condition: ${productData['condition'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              Text(
                "Location: ${productData['location'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              Text(
                "Description: ${productData['description'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              if (productData['createdAt'] != null)
                Text(
                  "Created At: ${productData['createdAt'].toDate().toString()}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 4),
              if (productData['updatedAt'] != null)
                Text(
                  "Updated At: ${productData['updatedAt'].toDate().toString()}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}