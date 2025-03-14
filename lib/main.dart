// lib\main.dart
// import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobiletesting/app.dart';
import 'package:mobiletesting/services/auth_service.dart';
import 'package:mobiletesting/utils/constants/firebase_options.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage
  await GetStorage.init();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //Initialize Authentication
  Get.put(AuthService());

  runApp(const App());
}
