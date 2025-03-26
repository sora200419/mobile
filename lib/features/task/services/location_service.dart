// lib/features/task/services/location_service.dart

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
    debugPrint('RunnerLocationService initialized for runner: $_runnerId');
    _initializeLocationService();
  }

  Future<void> _initializeLocationService() async {
    debugPrint('Initializing location service for runner: $_runnerId');
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      debugPrint('Location service is not enabled, requesting...');
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        debugPrint('User denied enabling location service');
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      debugPrint('Location permission denied, requesting...');
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        debugPrint('User denied location permission');
        return;
      }
    }

    // Check for background permission separately (for newer versions of Android/iOS)
    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted != PermissionStatus.granted) {
      debugPrint('Background location permission not granted');
    }

    debugPrint(
      'Setting location settings: high accuracy, 10s interval, 10m filter',
    );
    // Set location settings
    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 10000, // Update every 10 seconds
      distanceFilter: 10, // Update if moved 10 meters
    );

    debugPrint('Location service initialized successfully');
  }

  // Start sharing location for a specific task
  Future<bool> startSharingLocation(
    String taskId, [
    BuildContext? context,
  ]) async {
    debugPrint(
      'Starting location sharing for task: $taskId, runner: $_runnerId',
    );

    if (_isTrackingEnabled) {
      debugPrint('Already tracking, returning true');
      return true; // Already tracking
    }

    try {
      debugPrint('Re-initializing location service to ensure permissions');
      await _initializeLocationService();

      debugPrint('Enabling background mode');
      bool backgroundEnabled = await _location.enableBackgroundMode(
        enable: true,
      );
      if (!backgroundEnabled) {
        debugPrint('Failed to enable background mode');
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Background location permission required for tracking',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        debugPrint('Background mode enabled successfully');
      }

      _isTrackingEnabled = true;

      // Get initial location and update database
      debugPrint('Getting current location');
      LocationData currentLocation = await _location.getLocation();
      debugPrint(
        'Current location: lat=${currentLocation.latitude}, '
        'lng=${currentLocation.longitude}',
      );

      debugPrint('Updating initial location in database');
      await _updateLocationInDatabase(taskId, currentLocation);

      // Start location updates subscription
      debugPrint('Starting location change listener');
      _location.onLocationChanged.listen((LocationData locationData) {
        debugPrint(
          'Location changed: '
          'lat=${locationData.latitude}, lng=${locationData.longitude}',
        );
        if (_isTrackingEnabled) {
          _updateLocationInDatabase(taskId, locationData);
        }
      });

      // Create tracking status in database
      debugPrint('Setting tracking status in database');
      await _database.ref('taskTracking/$taskId').set({
        'active': true,
        'runnerId': _runnerId,
        'startedAt': ServerValue.timestamp,
      });

      debugPrint('Location tracking started successfully for task $taskId');
      return true;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      _isTrackingEnabled = false;
      return false;
    }
  }

  // Stop sharing location
  Future<void> stopSharingLocation(String taskId) async {
    debugPrint(
      'Stopping location sharing for task: $taskId, runner: $_runnerId',
    );

    if (!_isTrackingEnabled) {
      debugPrint('Not tracking, nothing to stop');
      return; // Not tracking
    }

    try {
      debugPrint('Setting tracking flag to false');
      _isTrackingEnabled = false;

      debugPrint('Disabling background mode');
      await _location.enableBackgroundMode(enable: false);

      // Update tracking status in database
      debugPrint('Updating tracking status in database');
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
      if (locationData.latitude == null || locationData.longitude == null) {
        debugPrint('Invalid location data (null coordinates), skipping update');
        return;
      }

      debugPrint(
        'Updating location in database for task $taskId: '
        'lat=${locationData.latitude}, lng=${locationData.longitude}',
      );

      await _database.ref('taskLocations/$taskId').set({
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'heading': locationData.heading,
        'speed': locationData.speed,
        'accuracy': locationData.accuracy,
        'timestamp': ServerValue.timestamp,
      });

      debugPrint('Location updated successfully');
    } catch (e) {
      debugPrint('Error updating location in database: $e');
    }
  }

  // Get current tracking status
  bool get isTracking => _isTrackingEnabled;

  // Check if tracking is active for a task
  static Future<bool> isTrackingActive(String taskId) async {
    try {
      debugPrint('Checking if tracking is active for task: $taskId');
      DatabaseEvent event =
          await FirebaseDatabase.instance
              .ref('taskTracking/$taskId/active')
              .once();

      bool isActive = event.snapshot.value == true;
      debugPrint('Tracking status for task $taskId: $isActive');
      return isActive;
    } catch (e) {
      debugPrint('Error checking tracking status: $e');
      return false;
    }
  }

  // Manual helper to reset tracking status if stuck (for debugging)
  static Future<void> resetTrackingStatus(String taskId) async {
    try {
      debugPrint('MANUAL RESET: Resetting tracking status for task: $taskId');
      await FirebaseDatabase.instance.ref('taskTracking/$taskId').set({
        'active': false,
        'resetAt': ServerValue.timestamp,
      });
      debugPrint('Tracking status reset complete');
    } catch (e) {
      debugPrint('Error resetting tracking status: $e');
    }
  }
}
