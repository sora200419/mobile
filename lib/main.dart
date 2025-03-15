// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mobiletesting/View/home_admin.dart';
import 'package:mobiletesting/View/home_runner.dart';
import 'package:mobiletesting/View/home_student.dart';
import 'package:mobiletesting/View/login_screen.dart';
import 'package:mobiletesting/providers/auth_provider.dart';
import 'package:mobiletesting/providers/tasks_provider.dart'; // Import TasksProvider
import 'package:mobiletesting/utils/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/utils/constants/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Don't provide TasksProvider here globally
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusLink',
      theme: CampusLinkAppTheme.lightTheme,
      darkTheme: CampusLinkAppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Define named routes
      routes: {
        '/login': (context) => LoginScreen(),
        '/home_student':
            (context) => ChangeNotifierProvider(
              // Provide TasksProvider *here*
              create: (_) => TasksProvider(),
              child: HomeStudent(),
            ),
        '/home_runner':
            (context) => ChangeNotifierProvider(
              // Provide TasksProvider *here*
              create: (_) => TasksProvider(),
              child: HomeRunner(),
            ),
        '/home_admin':
            (context) => ChangeNotifierProvider(
              // Provide TasksProvider *here*
              create: (_) => TasksProvider(),
              child: HomeAdmin(),
            ),
        // Add other routes as needed
      },
      home: StreamBuilder<fb_auth.User?>(
        stream: fb_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user == null) {
              return LoginScreen(); // Show login screen
            } else {
              return FutureBuilder<String?>(
                future: _getUserRole(user.uid),
                builder: (context, roleSnapshot) {
                  if (roleSnapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (roleSnapshot.hasError || roleSnapshot.data == null) {
                    return LoginScreen(); // If error fetching the role
                  }

                  final role = roleSnapshot.data;
                  if (role == 'student') {
                    return HomeStudent();
                  } else if (role == 'runner') {
                    // if user has runner role
                    return HomeRunner(); // Implemented to the home runner page
                  } else {
                    // Handle unknown roles or default to login.
                    return LoginScreen();
                  }
                },
              );
            }
          }
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }

  // Helper function to get user role
  Future<String?> _getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('role')) {
          return data['role'];
        }
      }
    } catch (e) {
      print("Error fetching user role: $e");
      // Handle error (e.g., show error message, default to login)
    }
    return null; // Return null if role not found or error occurs
  }
}
