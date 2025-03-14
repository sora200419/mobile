<<<<<<< HEAD
// lib\main.dart
=======
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mobiletesting/View/home_student.dart';
import 'package:mobiletesting/services/auth_service.dart';
>>>>>>> origin/Runner
// import 'package:firebase_core/firebase_core.dart';

import 'package:mobiletesting/utils/constants/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobiletesting/app.dart';
import 'package:mobiletesting/services/auth_service.dart';
import 'package:mobiletesting/utils/constants/firebase_options.dart';
=======
import 'package:provider/provider.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:mobiletesting/View/login_screen.dart';
>>>>>>> origin/Runner

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

<<<<<<< HEAD
  // Initialize local storage
  await GetStorage.init();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //Initialize Authentication
  Get.put(AuthService());

  runApp(const App());
=======
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
        ChangeNotifierProvider(create: (context) => AuthProvider()..checkUser()),
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
        builder: (context, authProvider, child){
          return authProvider.isAuthenticated  ? HomeStudent() : LoginScreen();
        },
      ),
    );
  }
>>>>>>> origin/Runner
}
