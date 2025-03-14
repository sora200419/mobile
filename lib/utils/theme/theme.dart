// lib\utils\theme\theme.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/utils/theme/custom_themes/appbar_theme.dart';
import 'package:mobiletesting/utils/theme/custom_themes/bottom_sheet_theme.dart';
import 'package:mobiletesting/utils/theme/custom_themes/checkbox_theme.dart';
import 'package:mobiletesting/utils/theme/custom_themes/chip_theme.dart';
import 'package:mobiletesting/utils/theme/custom_themes/elevated_button_theme.dart';
import 'package:mobiletesting/utils/theme/custom_themes/outlined_button_theme.dart';
import 'package:mobiletesting/utils/theme/custom_themes/text_field_theme.dart';
import 'package:mobiletesting/utils/theme/custom_themes/text_theme.dart';

class CampusLinkAppTheme {
  CampusLinkAppTheme._();

  /// Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    textTheme: CampusLinkTextTheme.lightTextTheme,
    chipTheme: CampusLinkChipTheme.lightChipTheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: CampusLinkAppBarTheme.lightAppBarTheme,
    checkboxTheme: CampusLinkCheckboxTheme.lightCheckboxTheme,
    bottomSheetTheme: CampusLinkBottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: CampusLinkElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: CampusLinkOutlinedButtonTHeme.lightOutlinedButtonTheme,
    inputDecorationTheme:
        CampusLinkTextFormFieldTheme.lightInputDecorationTheme,
  );

  /// Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: Colors.blue,
    textTheme: CampusLinkTextTheme.darkTextTheme,
    chipTheme: CampusLinkChipTheme.darkChipTheme,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: CampusLinkAppBarTheme.darkAppBarTheme,
    checkboxTheme: CampusLinkCheckboxTheme.darkCheckboxTheme,
    bottomSheetTheme: CampusLinkBottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: CampusLinkElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: CampusLinkOutlinedButtonTHeme.darkOutlinedButtonTheme,
    inputDecorationTheme: CampusLinkTextFormFieldTheme.darkInputDecorationTheme,
  );
}
