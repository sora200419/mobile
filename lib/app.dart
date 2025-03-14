// lib\app.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiletesting/utils/theme/theme.dart';
import 'package:mobiletesting/view/login_screen.dart'; // Import LoginScreen

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // Use GetMaterialApp
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: CampusLinkAppTheme.lightTheme,
      darkTheme: CampusLinkAppTheme.darkTheme,
      home: LoginScreen(), // Set LoginScreen as the initial screen
    );
  }
}
