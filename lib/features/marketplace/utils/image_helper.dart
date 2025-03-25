// lib/features/marketplace/utils/image_helper.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class ImageHelper {
  static Future<File?> pickImage({
    required BuildContext context,
    required ImageSource source,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80, // Reduce image quality to save storage
        maxWidth: 800, // Resize to reasonable dimensions
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Could not pick image: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }

    return null;
  }

  static Future<File?> downloadImage(String imageUrl) async {
    try {
      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = path.basename(imageUrl);
      final String filePath = '${tempDir.path}/$fileName';

      // Download file
      final http.Response response = await http.get(Uri.parse(imageUrl));

      // Save to file
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } catch (e) {
      print('Error downloading image: $e');
      return null;
    }
  }
}
