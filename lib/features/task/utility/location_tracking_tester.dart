// lib/utils/location_tracking_tester.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobiletesting/features/task/services/location_service.dart';

/// A utility class to help test location tracking functionality.
/// You can use this for debugging and testing purposes.
class LocationTrackingTester {
  /// Check the status of tracking for a specific task
  static Future<void> checkTrackingStatus(
    BuildContext context,
    String taskId,
  ) async {
    try {
      // Check tracking status in database
      DatabaseEvent trackingEvent =
          await FirebaseDatabase.instance.ref('taskTracking/$taskId').once();

      // Check location data in database
      DatabaseEvent locationEvent =
          await FirebaseDatabase.instance.ref('taskLocations/$taskId').once();

      String statusMessage = 'TRACKING STATUS CHECK\n\n';

      // Add tracking status info
      if (trackingEvent.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            trackingEvent.snapshot.value as Map<dynamic, dynamic>;

        bool isActive = data['active'] == true;
        String runnerId = data['runnerId'] ?? 'unknown';

        statusMessage += 'Active: $isActive\n';
        statusMessage += 'Runner ID: $runnerId\n';

        if (data['startedAt'] != null) {
          DateTime startTime = DateTime.fromMillisecondsSinceEpoch(
            data['startedAt'],
          );
          statusMessage += 'Started: ${startTime.toString()}\n';
        }

        if (data['endedAt'] != null) {
          DateTime endTime = DateTime.fromMillisecondsSinceEpoch(
            data['endedAt'],
          );
          statusMessage += 'Ended: ${endTime.toString()}\n';
        }
      } else {
        statusMessage += 'No tracking data found.\n';
      }

      statusMessage += '\nLOCATION DATA\n\n';

      // Add location data info
      if (locationEvent.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            locationEvent.snapshot.value as Map<dynamic, dynamic>;

        statusMessage += 'Latitude: ${data['latitude']}\n';
        statusMessage += 'Longitude: ${data['longitude']}\n';

        if (data['timestamp'] != null) {
          DateTime updateTime = DateTime.fromMillisecondsSinceEpoch(
            data['timestamp'],
          );
          statusMessage += 'Last Update: ${updateTime.toString()}\n';
        }
      } else {
        statusMessage += 'No location data found.\n';
      }

      // Show the information in a dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Tracking Status'),
              content: SingleChildScrollView(child: Text(statusMessage)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () async {
                    await _resetTrackingStatus(context, taskId);
                    Navigator.pop(context);
                  },
                  child: const Text('Reset Status'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking status: $e')));
    }
  }

  /// Force start location tracking for a task (for testing)
  static Future<void> forceStartTracking(
    BuildContext context,
    String taskId,
    String runnerId,
  ) async {
    try {
      // Create a confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Force Start Tracking'),
              content: const Text(
                'This will force start location tracking for this task. '
                'Use this only for testing purposes.\n\n'
                'Do you want to continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Force Start'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      final locationService = RunnerLocationService(runnerId);
      bool success = await locationService.startSharingLocation(
        taskId,
        context,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Forced location tracking started'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to force start tracking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// Reset tracking status for a task
  static Future<void> _resetTrackingStatus(
    BuildContext context,
    String taskId,
  ) async {
    try {
      await RunnerLocationService.resetTrackingStatus(taskId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tracking status reset successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error resetting status: $e')));
    }
  }

  /// Add a manual location entry for testing
  static Future<void> addManualLocation(
    BuildContext context,
    String taskId,
  ) async {
    try {
      // Show a dialog to input coordinates
      final TextEditingController latController = TextEditingController(
        text: "3.1390",
      );
      final TextEditingController lngController = TextEditingController(
        text: "101.6869",
      );

      bool? confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Add Manual Location'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: latController,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: lngController,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Add Location'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Parse coordinates
      double latitude = double.parse(latController.text);
      double longitude = double.parse(lngController.text);

      // Add to database
      await FirebaseDatabase.instance.ref('taskLocations/$taskId').set({
        'latitude': latitude,
        'longitude': longitude,
        'heading': 0.0,
        'speed': 5.0, // mock speed of 5 m/s
        'accuracy': 10.0,
        'timestamp': ServerValue.timestamp,
      });

      // Update tracking status to active
      await FirebaseDatabase.instance.ref('taskTracking/$taskId').update({
        'active': true,
        'runnerId': FirebaseAuth.instance.currentUser?.uid ?? 'manual',
        'startedAt': ServerValue.timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manual location added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding manual location: $e')),
      );
    }
  }
}
