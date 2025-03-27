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
  bool _isBanned = false;
  DateTime? _banEnd;

  User? get user => _user;
  String? get role => _role;
  String? get username => _username;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isBanned => _isBanned;
  DateTime? get banEnd => _banEnd;

  Future<void> checkUser() async {
    _user = FirebaseAuth.instance.currentUser;
    _isAuthenticated = user != null;

    if (_isAuthenticated) {
      await _fetchUserRole();
      await fetchUsername();
      await _fetchBanStatus();
    }

    print(username);
    print(role);
    print('Is banned: $isBanned');
    print('Ban end: $banEnd');
    notifyListeners();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    String? result = await _authService.login(email: email, password: password);

    if (result != null && !result.contains("ERROR")) {
      await checkUser();
      _isLoading = false;
      notifyListeners();
      return null;
    } else {
      _isLoading = false;
      notifyListeners();
      return result;
    }
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    _role = null;
    _username = null;
    _isBanned = false;
    _banEnd = null;
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
    }
  }

  Future<void> fetchUsername() async {
    if (_user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(_user!.uid)
              .get();
      _username = userDoc['name'];
    }
  }

  Future<void> _fetchBanStatus() async {
    if (_user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(_user!.uid)
              .get();
      
      // Get the data map and safely check for fields
      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
      
      // Check if isBanned exists and is a boolean, default to false if not present
      _isBanned = data?.containsKey('isBanned') == true ? data!['isBanned'] as bool : false;
      
      // Check if banEnd exists and convert if present
      if (data?.containsKey('banEnd') == true && data!['banEnd'] != null) {
        _banEnd = (data['banEnd'] as Timestamp).toDate();
      } else {
        _banEnd = null;
      }
    }
  }
}
