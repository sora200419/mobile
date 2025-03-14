// lib\main.dart
import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:mobiletesting/utils/theme/theme.dart';
import 'app.dart'; // Make sure MyApp is defined in this file

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mobiletesting/View/login_screen.dart';
import 'package:mobiletesting/utils/constants/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Todo: Add Widgets Binding
  // Todo: Init Local Storage
  // Todo: Await Native Splash
  // Todo: Initialize Firebase
  // Todo: Initialize Authentication

  runApp(CampusLink());
}

class CampusLink extends StatelessWidget {
  const CampusLink({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen());
  }
}
