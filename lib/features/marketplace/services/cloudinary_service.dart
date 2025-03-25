// lib/features/marketplace/services/cloudinary_service.dart
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();

  factory CloudinaryService() {
    return _instance;
  }

  CloudinaryService._internal();

  // Replace with your Cloudinary credentials
  final cloudinary = CloudinaryPublic(
    'docmjo6o9', // Replace with your actual cloud name
    'marketplace', // Replace with your upload preset
    cache: false,
  );

  Future<String> uploadImage(File imageFile, {String? folder}) async {
    try {
      print('CloudinaryService: Beginning upload for file: ${imageFile.path}');
      print('CloudinaryService: Using folder: ${folder ?? 'marketplace'}');

      // Log file size for debugging
      final fileSize = await imageFile.length();
      print('CloudinaryService: File size: ${fileSize ~/ 1024} KB');

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder ?? 'marketplace',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('CloudinaryService: Upload successful: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('CloudinaryService: Error uploading to Cloudinary: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  String getOptimizedImageUrl(
    String originalUrl, {
    int width = 800,
    int height = 600,
    int quality = 80,
  }) {
    // Example transformation for a Cloudinary URL
    if (!originalUrl.contains('cloudinary.com')) return originalUrl;

    // Insert transformation parameters
    final List<String> parts = originalUrl.split('/upload/');
    if (parts.length != 2) return originalUrl;

    return '${parts[0]}/upload/w_${width},h_${height},c_fill,q_${quality}/${parts[1]}';
  }
}
