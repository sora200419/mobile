import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/View/login_screen.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  String? _role;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get user => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  void checkUser() async {
    _user = FirebaseAuth.instance.currentUser;
    _isAuthenticated = user != null;

    if (_isAuthenticated) {
      await _fetchUserRole();
    }

    notifyListeners();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    // error
    String? result = await _authService.login(email: email, password: password);

    _isLoading = false;
    if (result != null && !result.contains("ERROR")) {
      _user = FirebaseAuth.instance.currentUser;
      _role = result;
      notifyListeners();
      return null;
    } else {
      return result;
    }
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    _role = null;
    _isAuthenticated = false;
    notifyListeners();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _fetchUserRole() async {
    if (_user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(_user!.uid)
              .get();
      _role = userDoc['role'];
      notifyListeners();
    }
  }
}
