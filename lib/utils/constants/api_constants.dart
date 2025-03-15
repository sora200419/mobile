// lib/utils/constants/api_constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIConstants {
  // Prevent instantiation of this class
  APIConstants._();

  static String get firebaseApiKey =>
      dotenv.env['FIREBASE_API_KEY'] ?? _handleMissingKey('FIREBASE_API_KEY');
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ??
      _handleMissingKey('GOOGLE_MAPS_API_KEY');
  static String get cloudFunctionsBaseUrl =>
      dotenv.env['CLOUD_FUNCTIONS_BASE_URL'] ??
      _handleMissingKey('CLOUD_FUNCTIONS_BASE_URL');
  // Add this when you're ready to integrate OpenAI
  // static String get openAIApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static String get CampusLinkSecretAPIKey =>
      dotenv.env['CAMPUSLINK_SECRET_API_KEY'] ??
      _handleMissingKey('CAMPUSLINK_SECRET_API_KEY');

  // Helper function to handle missing keys
  static String _handleMissingKey(String keyName) {
    // In development, throw an error to make it obvious.
    if (const bool.fromEnvironment('dart.vm.product')) {
      // Check if it's in production mode.
      return ''; // return empty string in production
    }

    throw ArgumentError(
      'Missing environment variable: $keyName.  Make sure it is defined in your .env file.',
    );
  }
}
