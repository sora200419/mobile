// lib/app.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/utils/theme/theme.dart';
import 'package:mobiletesting/view/home_student.dart'; // Import LoginScreen

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: CampusLinkAppTheme.lightTheme,
      darkTheme: CampusLinkAppTheme.darkTheme,
      home: const HomeStudent(),
    );
  }
}
