import 'package:firebase_database/firebase_database.dart';
import 'package:location/location.dart';
import 'package:flutter/material.dart';

class RunnerLocationService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final String _runnerId;
  Location _location = Location();
  bool _isTrackingEnabled = false;

  // Singleton pattern to ensure only one instance per runner
  static final Map<String, RunnerLocationService> _instances = {};

  factory RunnerLocationService(String runnerId) {
    if (_instances.containsKey(runnerId)) {
      return _instances[runnerId]!;
    } else {
      final instance = RunnerLocationService._internal(runnerId);
      _instances[runnerId] = instance;
      return instance;
    }
  }

  RunnerLocationService._internal(this._runnerId) {
    _initializeLocationService();
  }

  Future<void> _initializeLocationService() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Set location settings
    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 10000, // Update every 10 seconds
      distanceFilter: 10, // Update if moved 10 meters
    );
  }

  // Start sharing location for a specific task
  Future<bool> startSharingLocation(String taskId, [BuildContext? context]) async {
    if (_isTrackingEnabled) return true; // Already tracking


    try {
      await _initializeLocationService();

      await _location.enableBackgroundMode(enable: true);
      _isTrackingEnabled = true;

      // Get initial location and update database
      LocationData currentLocation = await _location.getLocation();
      await _updateLocationInDatabase(taskId, currentLocation);

      // Start location updates subscription
      _location.onLocationChanged.listen((LocationData locationData) {
        if (_isTrackingEnabled) {
          _updateLocationInDatabase(taskId, locationData);
        }
      });

      // Create tracking status in database
      await _database.ref('taskTracking/$taskId').set({
        'active': true,
        'runnerId': _runnerId,
        'startedAt': ServerValue.timestamp,
      });

      debugPrint('Location tracking started for task $taskId');
      return true;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      _isTrackingEnabled = false;
      return false;
    }
  }

  // Stop sharing location
  Future<void> stopSharingLocation(String taskId) async {
    if (!_isTrackingEnabled) return; // Not tracking

    try {
      _isTrackingEnabled = false;
      await _location.enableBackgroundMode(enable: false);

      // Update tracking status in database
      await _database.ref('taskTracking/$taskId').update({
        'active': false,
        'endedAt': ServerValue.timestamp,
      });

      debugPrint('Location tracking stopped for task $taskId');
    } catch (e) {
      debugPrint('Error stopping location tracking: $e');
      rethrow;
    }
  }

  // Update location in Firebase
  Future<void> _updateLocationInDatabase(
    String taskId,
    LocationData locationData,
  ) async {
    try {
      await _database.ref('taskLocations/$taskId').set({
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'heading': locationData.heading,
        'speed': locationData.speed,
        'accuracy': locationData.accuracy,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error updating location in database: $e');
    }
  }

  // Check if tracking is active for a task
  static Future<bool> isTrackingActive(String taskId) async {
    try {
      DatabaseEvent event =
          await FirebaseDatabase.instance
              .ref('taskTracking/$taskId/active')
              .once();

      return event.snapshot.value == true;
    } catch (e) {
      debugPrint('Error checking tracking status: $e');
      return false;
    }
  }
}
