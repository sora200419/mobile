// lib/app.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/utils/theme/theme.dart';

/// -- Use this Class to setup themes, initial Bindings, any animiation and much
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: CampusLinkAppTheme.lightTheme,
      darkTheme: CampusLinkAppTheme.darkTheme,
    );
  }
}
