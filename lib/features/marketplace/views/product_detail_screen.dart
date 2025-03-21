import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobiletesting/features/marketplace/models/product_model.dart';
import 'package:mobiletesting/features/marketplace/services/marketplace_service.dart';
import 'package:mobiletesting/features/marketplace/views/chat_screen.dart';
import 'package:mobiletesting/features/marketplace/views/payment_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  int _currentImageIndex = 0;
  late Product _product;
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _product = widget.product;

    // Increment view count and check favorite status
    if (_product.id != null) {
      _marketplaceService.incrementViewCount(_product.id!);
      _checkFavoriteStatus();
    }
  }

  Future<void> _checkFavoriteStatus() async {
    setState(() {
      _isLoadingFavorite = true;
    });

    if (_product.id != null) {
      bool isFav = await _marketplaceService.isProductFavorite(_product.id!);
      setState(() {
        _isFavorite = isFav;
        _isLoadingFavorite = false;
      });
    } else {
      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_product.id == null) return;

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      if (_isFavorite) {
        await _marketplaceService.removeFromFavorites(_product.id!);
      } else {
        await _marketplaceService.addToFavorites(_product.id!);
      }

      setState(() {
        _isFavorite = !_isFavorite;
        _isLoadingFavorite = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating favorites: $e')));
      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case Product.STATUS_AVAILABLE:
        return Colors.green;
      case Product.STATUS_RESERVED:
        return Colors.orange;
      case Product.STATUS_SOLD:
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  // Get condition color
  Color _getConditionColor(String condition) {
    switch (condition) {
      case Product.CONDITION_NEW:
        return Colors.teal;
      case Product.CONDITION_LIKE_NEW:
        return Colors.blue;
      case Product.CONDITION_GOOD:
        return Colors.green;
      case Product.CONDITION_FAIR:
        return Colors.orange;
      case Product.CONDITION_POOR:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner =
        FirebaseAuth.instance.currentUser?.uid == _product.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          // Favorite button (only for non-owners)
          if (!isOwner)
            _isLoadingFavorite
                ? Container(
                  width: 48,
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                  ),
                  onPressed: _toggleFavorite,
                ),
          // Owner actions
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'mark_reserved') {
                  await _marketplaceService.updateProductStatus(
                    _product.id!,
                    Product.STATUS_RESERVED,
                  );
                  setState(() {
                    _product = _product.copyWith(
                      status: Product.STATUS_RESERVED,
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked as reserved')),
                  );
                } else if (value == 'mark_sold') {
                  await _marketplaceService.updateProductStatus(
                    _product.id!,
                    Product.STATUS_SOLD,
                  );
                  setState(() {
                    _product = _product.copyWith(status: Product.STATUS_SOLD);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked as sold')),
                  );
                } else if (value == 'mark_available') {
                  await _marketplaceService.updateProductStatus(
                    _product.id!,
                    Product.STATUS_AVAILABLE,
                  );
                  setState(() {
                    _product = _product.copyWith(
                      status: Product.STATUS_AVAILABLE,
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked as available')),
                  );
                } else if (value == 'delete') {
                  bool confirm = await _showDeleteConfirmation(context);
                  if (confirm) {
                    await _marketplaceService.deleteProduct(_product.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Listing deleted')),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
                    if (_product.status != Product.STATUS_RESERVED)
                      const PopupMenuItem<String>(
                        value: 'mark_reserved',
                        child: Text('Mark as Reserved'),
                      ),
                    if (_product.status != Product.STATUS_SOLD)
                      const PopupMenuItem<String>(
                        value: 'mark_sold',
                        child: Text('Mark as Sold'),
                      ),
                    if (_product.status != Product.STATUS_AVAILABLE)
                      const PopupMenuItem<String>(
                        value: 'mark_available',
                        child: Text('Mark as Available'),
                      ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete Listing'),
                    ),
                  ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            if (_product.status != Product.STATUS_AVAILABLE)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: _getStatusColor(_product.status),
                child: Text(
                  _product.status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Product image carousel
            _buildImageCarousel(),

            // Product details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _product.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'RM ${_product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Category and condition
                  Row(
                    children: [
                      Chip(
                        label: Text(_product.category),
                        backgroundColor: Colors.deepPurple.shade50,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(_product.condition),
                        backgroundColor: _getConditionColor(
                          _product.condition,
                        ).withOpacity(0.2),
                      ),
                    ],
                  ),

                  // Location
                  if (_product.location.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            _product.location,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_product.description),
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
                          _product.sellerName.isNotEmpty
                              ? _product.sellerName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_product.sellerName),
                            Text(
                              'Listed on ${DateFormat('dd MMM yyyy').format(_product.createdAt)}',
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
                  if (!isOwner && _product.status == Product.STATUS_AVAILABLE)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat with Seller'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ChatScreen(
                                    product: _product,
                                    receiverId: _product.sellerId,
                                    receiverName: _product.sellerName,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Make offer button (if not owner)
                  if (!isOwner && _product.status == Product.STATUS_AVAILABLE)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.local_offer),
                          label: const Text('Make Offer'),
                          onPressed: () {
                            _showMakeOfferDialog(context);
                          },
                        ),
                      ),
                    ),

                  // Buy Now button (if not owner)
                  if (!isOwner && _product.status == Product.STATUS_AVAILABLE)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Buy Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        PaymentScreen(product: _product),
                              ),
                            ).then((result) {
                              if (result == true) {
                                // Payment was successful
                                setState(() {
                                  _product = _product.copyWith(
                                    status: Product.STATUS_SOLD,
                                  );
                                });
                              }
                            });
                          },
                        ),
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

  Widget _buildImageCarousel() {
    if (_product.imageUrls.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.grey,
        ),
      );
    }

    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items:
              _product.imageUrls.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(color: Colors.grey.shade200),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey,
                          );
                        },
                      ),
                    );
                  },
                );
              }).toList(),
        ),
        // Image indicator dots
        if (_product.imageUrls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  _product.imageUrls.asMap().entries.map((entry) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentImageIndex == entry.key
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                      ),
                    );
                  }).toList(),
            ),
          ),
      ],
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

  void _showMakeOfferDialog(BuildContext context) {
    final TextEditingController offerController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Make an Offer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Listed price: RM ${_product.price.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: offerController,
                  decoration: InputDecoration(
                    labelText: 'Your Offer (RM)',
                    border: OutlineInputBorder(),
                    prefixText: 'RM ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Validate offer
                  double? offer = double.tryParse(offerController.text);
                  if (offer == null || offer <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid offer amount'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  // Open chat with preset message about the offer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatScreen(
                            product: _product,
                            receiverId: _product.sellerId,
                            receiverName: _product.sellerName,
                            initialMessage:
                                'Hi, I\'m interested in "${_product.title}". Would you accept RM${offer.toStringAsFixed(2)} for it?',
                          ),
                    ),
                  );
                },
                child: const Text('Send Offer'),
              ),
            ],
          ),
    );
  }
}
