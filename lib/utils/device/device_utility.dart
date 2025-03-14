// lib\utils\device\device_utility.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CampusLinkDeviceUtils {
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  /// Set the status bar color
  static Future<void> setStatusBarColor(Color color) async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: color),
    );
  }

  /// Check if the device is in landscape orientation
  static bool isLandscapeOrientation(BuildContext context) {
    // return MediaQuery.of(context).orientation == Orientation.landscape;
    final viewInsets = View.of(context).viewInsets;
    return viewInsets.bottom == 0;
  }

  /// Check if the device is in portrait orientation
  static bool isPortraitOrientation(BuildContext context) {
    // return MediaQuery.of(context).orientation == Orientation.portrait;
    final viewInsets = View.of(context).viewInsets;
    return viewInsets.bottom != 0;
  }

  /// Enable or disable full‐screen mode
  static void setFullScreen(bool enable) {
    SystemChrome.setEnabledSystemUIMode(
      enable ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  /// Get the screen height using GetX’s context
  static double getScreenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  /// Get the screen width (requires a BuildContext)
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get the device pixel ratio using GetX’s context
  static double getPixelRatio() {
    return MediaQuery.of(Get.context!).devicePixelRatio;
  }

  /// Get the status bar height (top padding)
  static double getStatusBarHeight() {
    return MediaQuery.of(Get.context!).padding.top;
  }

  /// Get the bottom navigation bar height (a Flutter constant)
  static double getBottomNavigationBarHeight() {
    return kBottomNavigationBarHeight;
  }

  /// Get the standard Material AppBar height
  static double getAppBarHeight() {
    return kToolbarHeight;
  }

  /// Get the current keyboard height
  static double getKeyboardHeight() {
    final viewInsets = MediaQuery.of(Get.context!).viewInsets;
    return viewInsets.bottom;
  }

  /// Check if the keyboard is currently visible
  static Future<bool> isKeyboardVisible() async {
    // final bottom = MediaQuery.of(Get.context!).viewInsets.bottom;
    // return bottom > 0;
    final viewInsets = View.of(Get.context!).viewInsets;
    return viewInsets.bottom > 0;
  }

  static Future<bool> isPhysicalDevice() async {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Vibrate the device for the given duration (two short vibrations)
  static void vibrate(Duration duration) {
    HapticFeedback.vibrate();
    Future.delayed(duration, () => HapticFeedback.vibrate());
  }

  /// Lock the app to specific orientations
  static Future<void> setPreferredOrientations(
    List<DeviceOrientation> orientations,
  ) async {
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// Hide the status bar (fullscreen manual mode)
  static void hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  /// Show the status bar again
  static void showStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  /// Check if there is an active internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static bool isIOS() {
    return Platform.isIOS;
  }

  static bool isAndroid() {
    return Platform.isAndroid;
  }

  static void launchUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw "Could not launch $url";
    }
  }
}
