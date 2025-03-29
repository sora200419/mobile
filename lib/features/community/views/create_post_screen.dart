// lib/features/community/views/create_post_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobiletesting/features/community/models/community_post_model.dart';
import 'package:mobiletesting/features/community/services/community_service.dart';
import 'package:mobiletesting/features/community/utils/post_utilities.dart';

class CreatePostScreen extends StatefulWidget {
  final CommunityPost? post; // If editing an existing post

  const CreatePostScreen({Key? key, this.post}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final CommunityService _communityService = CommunityService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late PostType _selectedType;
  late Map<String, dynamic> _metadata;
  final List<File> _imageFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers and state based on whether we're editing or creating
    if (widget.post != null) {
      _titleController = TextEditingController(text: widget.post!.title);
      _contentController = TextEditingController(text: widget.post!.content);
      _selectedType = widget.post!.type;
      _metadata =
          widget.post!.metadata ??
          PostUtilities.getDefaultMetadata(_selectedType);
    } else {
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _selectedType = PostType.general;
      _metadata = PostUtilities.getDefaultMetadata(_selectedType);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      if (widget.post == null) {
        // Create new post
        await _communityService.createPost(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          type: _selectedType,
          images: _imageFiles,
          metadata: _metadata,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Update existing post
        // This is simplified - in reality you'd need to handle existing images
        await _communityService.updatePost(
          postId: widget.post!.id!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          newImages: _imageFiles,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post updated successfully!')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateMetadata(String key, dynamic value) {
    setState(() {
      _metadata[key] = value;
    });
  }

  void _updatePostType(PostType type) {
    setState(() {
      _selectedType = type;
      _metadata = PostUtilities.getDefaultMetadata(type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post == null ? 'Create Post' : 'Edit Post'),
        actions: [
          _isLoading
              ? const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
              : TextButton(
                onPressed: _submitPost,
                child: Text(
                  widget.post == null ? 'Post' : 'Save',
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostTypeSelector(),
              const SizedBox(height: 16),
              _buildTitleInput(),
              const SizedBox(height: 16),
              _buildContentInput(),
              const SizedBox(height: 16),
              _buildMetadataFields(),
              const SizedBox(height: 16),
              _buildImageSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Post Type',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              PostType.values.map((type) {
                final isSelected = _selectedType == type;
                final color = PostUtilities.getPostTypeColor(type);

                return FilterChip(
                  selected: isSelected,
                  label: Text(PostUtilities.getPostTypeLabel(type)),
                  avatar: Icon(
                    PostUtilities.getPostTypeIcon(type),
                    color: isSelected ? Colors.white : color,
                    size: 18,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _updatePostType(type);
                    }
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildTitleInput() {
    return TextFormField(
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
      maxLength: 100,
    );
  }

  Widget _buildContentInput() {
    return TextFormField(
      controller: _contentController,
      decoration: const InputDecoration(
        labelText: 'Content',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter some content';
        }
        return null;
      },
      maxLength: 1000,
      maxLines: 5,
    );
  }

  Widget _buildMetadataFields() {
    if (_selectedType == PostType.general) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${PostUtilities.getPostTypeLabel(_selectedType)} Details',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...PostUtilities.getMetadataFormFields(
          _selectedType,
          _metadata,
          _updateMetadata,
        ),
      ],
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images (Optional)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_imageFiles.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageFiles.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _imageFiles[index],
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _imageFiles.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _imageFiles.length >= 5 ? null : _pickImages,
          icon: const Icon(Icons.photo_library),
          label: Text(
            _imageFiles.isEmpty
                ? 'Add Images'
                : 'Add More Images (${_imageFiles.length}/5)',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade100,
            foregroundColor: Colors.deepPurple.shade900,
          ),
        ),
        if (_imageFiles.length >= 5)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Maximum of 5 images allowed',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
