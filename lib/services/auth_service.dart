import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to handle user signup
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Create user in Firebase Authentication with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Prepare user data with basic fields
      Map<String, dynamic> userData = {
        'name': name.trim(),
        'email': email.trim(),
        'role': role.trim(),
      };

      // Add default values based on role
      if (role.trim() == 'Student') {
        userData.addAll({
          'points': 0, // Default value for points (int) for Student
          'isBanned': false, // Add isBanned field with default value false
        });
      } else if (role.trim() == 'Runner') {
        userData.addAll({
          'points': 0,          // Default value for points (int) for Runner
          'averageRating': 0.0, // Default value for averageRating (double) for Runner
          'ratingCount': 0,     // Default value for ratingCount (int) for Runner
          'isBanned': false, // Add isBanned field with default value false
        });
      }
      // Admin role does not need additional fields

      // Save user data in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set(userData);

      return null; // Success: no error message
    } catch (e) {
      return e.toString(); // Error: return the exception
    }
  }

  // Function to handle user login
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in user using Firebase Authentication with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Fetching the user's role from Firestore to determine access level
      DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .get();
      return userDoc['role']; // Return the user's role (Admin/Student/Runner)
    } catch (e) {
      return e.toString(); // Error: return the exception
    }
  }
}