// lib/features/marketplace/views/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:campuslink/features/marketplace/models/chat_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart' as models;
import '../services/marketplace_service.dart';
import '../services/chat_service.dart';
import '../services/payment_service.dart';
import 'edit_product_screen.dart';
import 'checkout_screen.dart';
import 'chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final ChatService _chatService = ChatService();
  final PaymentService _paymentService = PaymentService();
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    if (widget.product.id != null) {
      setState(() => _isLoading = true);
      try {
        bool isFavorite = await _marketplaceService.isProductFavorite(
          widget.product.id!,
        );
        setState(() => _isFavorite = isFavorite);
      } catch (e) {
        // Handle error
        print('Error checking favorite status: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.product.id == null) return;

    setState(() => _isLoading = true);
    try {
      if (_isFavorite) {
        await _marketplaceService.removeFromFavorites(widget.product.id!);
      } else {
        await _marketplaceService.addToFavorites(widget.product.id!);
      }
      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating favorites: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProductStatus(String status) async {
    if (widget.product.id == null) return;

    setState(() => _isLoading = true);
    try {
      await _marketplaceService.updateProductStatus(widget.product.id!, status);
      // Refresh the product details
      Product? updatedProduct = await _marketplaceService.getProductById(
        widget.product.id!,
      );

      if (updatedProduct != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product status updated to $status')),
        );

        // If we're marking it as sold, we might want to navigate back
        if (status == Product.STATUS_SOLD) {
          Navigator.pop(context, updatedProduct);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (widget.product.id == null) return;

    // Show confirmation dialog
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Product'),
                content: const Text(
                  'Are you sure you want to delete this product? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await _marketplaceService.deleteProduct(widget.product.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting product: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openChat() async {
    if (widget.product.id == null) return;

    setState(() => _isLoading = true);
    try {
      // Get transaction related to this product
      firestore.QuerySnapshot querySnapshot =
          await firestore.FirebaseFirestore.instance
              .collection('transactions')
              .where('productId', isEqualTo: widget.product.id)
              .where('buyerId', isEqualTo: _marketplaceService.currentUserId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        // No transaction found, show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please purchase the item to chat with the seller'),
            ),
          );
        }
        return;
      }

      String transactionId = querySnapshot.docs.first.id;

      // Get or create chat for this transaction
      Chat? chat = await _chatService.getChatByTransactionId(transactionId);

      if (chat != null && mounted) {
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(chatId: chat.id!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = _marketplaceService.currentUserId == widget.product.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.title, style: const TextStyle(fontSize: 18)),
        actions: [
          if (!isOwner)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              onPressed: _isLoading ? null : _toggleFavorite,
            ),
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _navigateToEditScreen();
                    break;
                  case 'mark_reserved':
                    _updateProductStatus(Product.STATUS_RESERVED);
                    break;
                  case 'mark_sold':
                    _updateProductStatus(Product.STATUS_SOLD);
                    break;
                  case 'mark_available':
                    _updateProductStatus(Product.STATUS_AVAILABLE);
                    break;
                  case 'delete':
                    _deleteProduct();
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Product'),
                        ],
                      ),
                    ),
                    if (widget.product.status != Product.STATUS_RESERVED)
                      const PopupMenuItem(
                        value: 'mark_reserved',
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 20),
                            SizedBox(width: 8),
                            Text('Mark as Reserved'),
                          ],
                        ),
                      ),
                    if (widget.product.status != Product.STATUS_SOLD)
                      const PopupMenuItem(
                        value: 'mark_sold',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 20),
                            SizedBox(width: 8),
                            Text('Mark as Sold'),
                          ],
                        ),
                      ),
                    if (widget.product.status != Product.STATUS_AVAILABLE)
                      const PopupMenuItem(
                        value: 'mark_available',
                        child: Row(
                          children: [
                            Icon(Icons.shopping_bag, size: 20),
                            SizedBox(width: 8),
                            Text('Mark as Available'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete Product',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildProductDetails(),
    );
  }

  Widget _buildProductDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          if (widget.product.imageUrl.isNotEmpty)
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: Image.network(
                widget.product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => const Center(
                      child: Icon(Icons.error, size: 50, color: Colors.grey),
                    ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),

          // Status badge
          if (widget.product.status != Product.STATUS_AVAILABLE)
            Container(
              width: double.infinity,
              color:
                  widget.product.status == Product.STATUS_SOLD
                      ? Colors.red
                      : Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                widget.product.status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

          // Product info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.product.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'RM ${widget.product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Location and posted date
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.product.location,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Posted ${DateFormat.yMMMd().format(widget.product.createdAt)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Category and condition
                Row(
                  children: [
                    Chip(
                      label: Text(widget.product.category),
                      backgroundColor: Colors.deepPurple.withOpacity(0.1),
                      labelStyle: const TextStyle(color: Colors.deepPurple),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(widget.product.condition),
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      labelStyle: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.product.description,
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 24),

                // Seller info
                const Text(
                  'Seller Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          child: Text(
                            widget.product.sellerName.isNotEmpty
                                ? widget.product.sellerName[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.sellerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Member since ${DateFormat.yMMMd().format(widget.product.createdAt)}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Buy Now button for non-sellers
                if (_marketplaceService.currentUserId !=
                        widget.product.sellerId &&
                    widget.product.status == Product.STATUS_AVAILABLE)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    CheckoutScreen(product: widget.product),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('BUY NOW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                if (_marketplaceService.currentUserId !=
                        widget.product.sellerId &&
                    widget.product.status == Product.STATUS_AVAILABLE)
                  const SizedBox(height: 16),

                // Chat button for reserved products
                if (_marketplaceService.currentUserId !=
                        widget.product.sellerId &&
                    widget.product.status == Product.STATUS_RESERVED)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openChat,
                      icon: const Icon(Icons.chat),
                      label: const Text('CHAT WITH SELLER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                if (_marketplaceService.currentUserId !=
                        widget.product.sellerId &&
                    widget.product.status == Product.STATUS_RESERVED)
                  const SizedBox(height: 16),

                // Contact seller button for non-sellers
                if (_marketplaceService.currentUserId !=
                        widget.product.sellerId &&
                    widget.product.status == Product.STATUS_AVAILABLE)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        try {
                          // Create a transaction for the chat
                          String
                          transactionId = await _paymentService.createTransaction(
                            widget.product,
                            models
                                .Transaction
                                .METHOD_CASH_ON_DELIVERY, // Use any payment method as placeholder
                          );

                          // Get or create chat for this transaction
                          final chat = await _chatService
                              .getChatByTransactionId(transactionId);

                          setState(() => _isLoading = false);

                          if (chat != null && mounted) {
                            // Navigate to chat screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ChatScreen(chatId: chat.id!),
                              ),
                            );
                          } else {
                            throw Exception('Failed to create chat');
                          }
                        } catch (e) {
                          setState(() => _isLoading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error contacting seller: $e'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('CONTACT SELLER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: widget.product),
      ),
    );

    if (result != null && result is Product) {
      // The product was updated
      setState(() {}); // Refresh the UI
    }
  }
}
