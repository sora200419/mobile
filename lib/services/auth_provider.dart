// lib\services\auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/View/login_screen.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  String? _role;
  String? _username;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get user => _user;
  String? get role => _role;
  String? get username => _username;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkUser() async {
    _user = FirebaseAuth.instance.currentUser;
    _isAuthenticated = user != null;

    if (_isAuthenticated) {
      await _fetchUserRole();
      await _fetchUsername();
    }

    print(username);
    print(role);
    notifyListeners();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    String? result = await _authService.login(email: email, password: password);

    _isLoading = false;
    if (result != null && !result.contains("ERROR")) {
      await checkUser();
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

    Navigator.of(context).pushAndRemoveUntil(
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
      // notifyListeners();
    }
  }

  Future<void> _fetchUsername() async {
    if (_user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(_user!.uid)
              .get();
      _username = userDoc['name'];
      // notifyListeners();
    }
  }
}
