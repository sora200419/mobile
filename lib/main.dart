// lib\main.dart
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mobiletesting/View/home_student.dart';
import 'package:mobiletesting/services/auth_service.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:mobiletesting/utils/theme/theme.dart';
import 'app.dart'; // Make sure MyApp is defined in this file

import 'package:mobiletesting/utils/constants/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:mobiletesting/View/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAuth.instance.signOut();

  // Todo: Add Widgets Binding
  // Todo: Init Local Storage
  // Todo: Await Native Splash
  // Todo: Initialize Firebase
  // Todo: Initialize Authentication

  runApp(
    MultiProvider(
      providers: [
        // Make AuthService globally accessible
        ChangeNotifierProvider(
          create: (context) => AuthProvider()..checkUser(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return authProvider.isAuthenticated ? HomeStudent() : LoginScreen();
        },
      ),
    );
  }
}
