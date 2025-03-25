// lib/features/marketplace/views/edit_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/marketplace_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceService _marketplaceService = MarketplaceService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;

  String _selectedCategory = '';
  String _selectedCondition = '';
  String _imageUrl = '';
  List<String> _additionalImages = [];
  bool _isLoading = false;

  // List of product categories
  final List<String> _categories = [
    'Books',
    'Electronics',
    'Furniture',
    'Clothing',
    'Other',
  ];

  // List of product conditions
  final List<String> _conditions = [
    Product.CONDITION_NEW,
    Product.CONDITION_LIKE_NEW,
    Product.CONDITION_GOOD,
    Product.CONDITION_FAIR,
    Product.CONDITION_POOR,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _locationController = TextEditingController(text: widget.product.location);
    _selectedCategory = widget.product.category;
    _selectedCondition = widget.product.condition;
    _imageUrl = widget.product.imageUrl;
    _additionalImages = List.from(widget.product.additionalImages);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Update the product image
  Future<void> _updateProductImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    setState(() => _isLoading = true);

    try {
      final File? imageFile = await _marketplaceService.pickImage(
        source: source,
      );
      if (imageFile != null) {
        final String newImageUrl = await _marketplaceService.uploadImage(
          imageFile,
          productId: widget.product.id,
        );
        setState(() => _imageUrl = newImageUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create updated product
      Product updatedProduct = widget.product.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory,
        condition: _selectedCondition,
        location: _locationController.text.trim(),
        imageUrl: _imageUrl,
        additionalImages: _additionalImages,
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _marketplaceService.updateProduct(updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context, updatedProduct);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating product: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProduct,
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Center(
              child: GestureDetector(
                onTap: _updateProductImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _imageUrl.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => const Center(
                                    child: Icon(
                                      Icons.error,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          )
                          : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text('Tap to add image'),
                              ],
                            ),
                          ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Price field
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (RM)',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Price must be greater than zero';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items:
                  _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Condition dropdown
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
              items:
                  _conditions.map((String condition) {
                    return DropdownMenuItem<String>(
                      value: condition,
                      child: Text(condition),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCondition = newValue;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a condition';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Location field
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (e.g., Campus Building)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Update button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('UPDATE PRODUCT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
