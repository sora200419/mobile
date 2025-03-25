// lib/features/marketplace/widgets/product_card.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/marketplace_service.dart';
import '../views/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool showFavoriteButton;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;

  // Using static to be compatible with const constructor
  static final MarketplaceService _marketplaceService = MarketplaceService();

  const ProductCard({
    Key? key,
    required this.product,
    this.showFavoriteButton = true,
    this.onToggleFavorite,
    required this.isFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child:
                        product.imageUrl.isNotEmpty
                            ? Image.network(
                              _marketplaceService.getOptimizedImageUrl(
                                product.imageUrl,
                                width: 400,
                                height: 400,
                                quality: 85,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print(
                                  'Image error: $error for ${product.imageUrl}',
                                );
                                return const Center(
                                  child: Icon(
                                    Icons.error,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                            : const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                  ),
                ),

                // Product info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                          if (product.location.isNotEmpty)
                            Flexible(
                              child: Text(
                                product.location,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Status label for reserved or sold items
            if (product.status != Product.STATUS_AVAILABLE)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color:
                      product.status == Product.STATUS_SOLD
                          ? Colors.red.withOpacity(0.8)
                          : Colors.orange.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    product.status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Favorite button
            if (showFavoriteButton)
              Positioned(
                top: 5,
                right: 5,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white.withOpacity(0.7),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                    onPressed: onToggleFavorite,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
