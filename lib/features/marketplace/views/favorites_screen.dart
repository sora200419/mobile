// lib/features/marketplace/views/favorites_screen.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/marketplace_service.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: _buildFavoritesList(),
    );
  }

  Widget _buildFavoritesList() {
    return StreamBuilder<List<Product>>(
      stream: _marketplaceService.getFavoriteProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<Product> favoriteProducts = snapshot.data ?? [];

        if (favoriteProducts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No favorites yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Products you like will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: favoriteProducts.length,
          itemBuilder: (context, index) {
            Product product = favoriteProducts[index];
            return _buildFavoriteItem(product);
          },
        );
      },
    );
  }

  Widget _buildFavoriteItem(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4.0),
                bottomLeft: Radius.circular(4.0),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child:
                    product.imageUrl.isNotEmpty
                        ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Center(
                                child: Icon(
                                  Icons.error,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
              ),
            ),

            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RM ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.status != Product.STATUS_AVAILABLE)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  product.status == Product.STATUS_SOLD
                                      ? Colors.red
                                      : Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              product.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => _removeFromFavorites(product.id!),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFromFavorites(String productId) async {
    try {
      await _marketplaceService.removeFromFavorites(productId);
      // No need to update state manually as we're using a StreamBuilder
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing from favorites: $e')),
        );
      }
    }
  }
}
