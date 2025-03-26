// lib/features/task/views/location_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:mobiletesting/features/task/services/location_service.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;

import 'package:mobiletesting/features/task/utility/location_tracking_tester.dart';

class LocationTrackingScreen extends StatefulWidget {
  final Task task;
  final bool isStudent; // To determine if the user is a student or runner

  const LocationTrackingScreen({
    Key? key,
    required this.task,
    required this.isStudent,
  }) : super(key: key);

  @override
  State<LocationTrackingScreen> createState() => _LocationTrackingScreenState();
}

class _LocationTrackingScreenState extends State<LocationTrackingScreen> {
  GoogleMapController? _mapController;
  LatLng? _runnerPosition;
  LatLng? _taskLocation;
  bool _isLoading = true;
  String _statusMessage = 'Initializing tracking...';
  bool _isTrackingActive = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      // Try to get the task's location coordinates
      debugPrint('Step 1: Getting task location for ${widget.task.location}');
      await _getTaskLocation();

      // Check if tracking is active
      debugPrint('Step 2: Checking tracking status for task ${widget.task.id}');
      await _checkTrackingStatus();

      // Check for initial runner position
      debugPrint('Step 3: Checking initial runner position');
      await _checkInitialRunnerPosition();
    } catch (e) {
      debugPrint('Error during tracking initialization: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error initializing tracking: $e';
      });
    }
  }

  Future<void> _getTaskLocation() async {
    try {
      if (widget.task.latLng != null) {
        debugPrint('Task already has LatLng: ${widget.task.latLng}');
        setState(() {
          _taskLocation = widget.task.latLng;
          _updateTaskMarker();
        });
      } else {
        // Try to geocode the location string
        debugPrint('Attempting to geocode: ${widget.task.location}');
        try {
          List<Location> locations = await locationFromAddress(
            widget.task.location,
          );
          debugPrint('Geocoding results: ${locations.length} locations found');
          if (locations.isNotEmpty) {
            setState(() {
              _taskLocation = LatLng(
                locations.first.latitude,
                locations.first.longitude,
              );
              _updateTaskMarker();
            });
            debugPrint('Successfully geocoded to: $_taskLocation');
          } else {
            debugPrint(
              'Unable to find coordinates for address: ${widget.task.location}',
            );
            setState(() {
              _statusMessage = 'Could not find location on map';
            });
          }
        } catch (e) {
          debugPrint('Geocoding error: $e');
          setState(() {
            _statusMessage = 'Error finding location: $e';
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting task location: $e');
      throw e; // Rethrow to be caught by the caller
    }
  }

  void _updateTaskMarker() {
    if (_taskLocation != null) {
      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('task_location'),
            position: _taskLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Task Location',
              snippet: widget.task.location,
            ),
          ),
        );
      });
    }
  }

  Future<void> _checkTrackingStatus() async {
    if (widget.task.id != null) {
      debugPrint('Checking if tracking is active for task: ${widget.task.id}');
      bool isActive = await RunnerLocationService.isTrackingActive(
        widget.task.id!,
      );
      debugPrint('Is tracking active: $isActive');
      setState(() {
        _isTrackingActive = isActive;
        if (!isActive) {
          _statusMessage = 'Runner has not started sharing location yet';
        } else {
          _statusMessage = 'Runner is sharing location';
        }
      });
    } else {
      debugPrint('Task ID is null, cannot check tracking status');
    }
  }

  Future<void> _checkInitialRunnerPosition() async {
    try {
      if (widget.task.id == null) {
        debugPrint('Task ID is null, cannot check runner position');
        setState(() {
          _isLoading = false;
          _statusMessage = 'Cannot track: Missing task ID';
        });
        return;
      }

      debugPrint('Fetching initial runner position from Firebase');
      DatabaseEvent event =
          await FirebaseDatabase.instance
              .ref('taskLocations/${widget.task.id}')
              .once();

      if (event.snapshot.value != null) {
        debugPrint('Initial runner position data: ${event.snapshot.value}');
        Map<dynamic, dynamic> locationData =
            event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _runnerPosition = LatLng(
            locationData['latitude'],
            locationData['longitude'],
          );
          _updateRunnerMarker();
          _isLoading = false;
          _statusMessage = 'Runner location found';
        });
      } else {
        debugPrint('No initial runner position data available');
        setState(() {
          _isLoading = false;
          if (_isTrackingActive) {
            _statusMessage = 'Waiting for runner location updates...';
          } else {
            _statusMessage = 'Runner has not started sharing location yet';
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking initial runner position: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading runner location: $e';
      });
    }
  }

  void _updateRunnerMarker() {
    if (_runnerPosition != null) {
      setState(() {
        // Remove existing runner marker if it exists
        _markers.removeWhere((marker) => marker.markerId.value == 'runner');

        // Add new runner marker
        _markers.add(
          Marker(
            markerId: const MarkerId('runner'),
            position: _runnerPosition!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: 'Runner',
              snippet:
                  'Last updated: ${DateTime.now().toString().substring(11, 16)}',
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tracking: ${widget.task.title}')),
      body: Column(
        children: [
          // Task info card
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(widget.task.location)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tracking status indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color:
                  _isTrackingActive
                      ? Colors.green.shade50
                      : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    _isTrackingActive
                        ? Colors.green.shade200
                        : Colors.amber.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isTrackingActive ? Icons.location_on : Icons.location_off,
                  color: _isTrackingActive ? Colors.green : Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isTrackingActive
                      ? 'Runner is sharing location'
                      : 'Waiting for runner to share location',
                  style: TextStyle(
                    color:
                        _isTrackingActive
                            ? Colors.green.shade700
                            : Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Map view
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(_statusMessage),
                        ],
                      ),
                    )
                    : _buildMapView(),
          ),
        ],
      ),
      // Student debugging feature - usually hidden in production
      floatingActionButton:
          widget.isStudent
              ? FloatingActionButton(
                onPressed: () {
                  if (widget.task.id != null) {
                    LocationTrackingTester.addManualLocation(
                      context,
                      widget.task.id!,
                    );
                  }
                },
                child: const Icon(Icons.science),
                backgroundColor: Colors.deepPurple,
                tooltip: 'Add Test Location',
              )
              : null,
    );
  }

  Widget _buildMapView() {
    // If no runner position and not tracking
    if (_runnerPosition == null && !_isTrackingActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_statusMessage, textAlign: TextAlign.center),
            const SizedBox(height: 24),

            // Debug info - this helps during testing
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Debug Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Task ID: ${widget.task.id ?? "null"}\n'
                    'Runner ID: ${widget.task.providerId ?? "null"}\n'
                    'Status: ${widget.task.status}\n'
                    'Is Student View: ${widget.isStudent}',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Map with runner tracking
    return Stack(
      children: [
        StreamBuilder<DatabaseEvent>(
          stream:
              FirebaseDatabase.instance
                  .ref('taskLocations/${widget.task.id}')
                  .onValue,
          builder: (context, snapshot) {
            // Handle stream data updates
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              debugPrint('Received new location update');
              Map<dynamic, dynamic> locationData =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

              LatLng newPosition = LatLng(
                locationData['latitude'],
                locationData['longitude'],
              );

              // Update the map camera if controller exists and position changed
              if (_mapController != null &&
                  (_runnerPosition == null || _runnerPosition != newPosition)) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(newPosition),
                );
                _runnerPosition = newPosition;
                _updateRunnerMarker();
              }
            } else if (snapshot.hasError) {
              debugPrint('Error in location stream: ${snapshot.error}');
            }

            // Initial map view
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target:
                    _runnerPosition ??
                    _taskLocation ??
                    const LatLng(
                      3.1390,
                      101.6869,
                    ), // Default to KL if no positions
                zoom: 15,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
              zoomControlsEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            );
          },
        ),

        // Estimated arrival overlay
        if (_runnerPosition != null && _taskLocation != null)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.directions_run, color: Colors.blue),
                    const SizedBox(width: 8),
                    StreamBuilder<DatabaseEvent>(
                      stream:
                          FirebaseDatabase.instance
                              .ref('taskLocations/${widget.task.id}')
                              .onValue,
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            snapshot.data!.snapshot.value != null) {
                          Map<dynamic, dynamic> data =
                              snapshot.data!.snapshot.value
                                  as Map<dynamic, dynamic>;
                          double speed = data['speed'] ?? 0;
                          double estimatedMinutes = _calculateEstimatedArrival(
                            speed,
                            _runnerPosition!,
                            _taskLocation!,
                          );

                          return Text(
                            'Runner is ${_calculateDistance(_runnerPosition!, _taskLocation!)} away' +
                                (estimatedMinutes > 0
                                    ? ' • Est. arrival: ${_formatTime(estimatedMinutes)}'
                                    : ''),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          );
                        }
                        return const Text('Calculating distance...');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Navigation controls
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              // Center on task location button (if available)
              if (_taskLocation != null)
                FloatingActionButton(
                  heroTag: 'taskLocationButton',
                  mini: true,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.place),
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(_taskLocation!),
                    );
                  },
                ),
              const SizedBox(height: 8),

              // Center on runner button (if available)
              if (_runnerPosition != null)
                FloatingActionButton(
                  heroTag: 'runnerLocationButton',
                  mini: true,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.directions_run),
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(_runnerPosition!),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _calculateDistance(LatLng position1, LatLng position2) {
    // Calculate simple straight-line distance (replace with more accurate calculation for production)
    const double earthRadius = 6371.0; // kilometers

    double lat1 = position1.latitude * (math.pi / 180);
    double lon1 = position1.longitude * (math.pi / 180);
    double lat2 = position2.latitude * (math.pi / 180);
    double lon2 = position2.longitude * (math.pi / 180);

    double dlon = lon2 - lon1;
    double dlat = lat2 - lat1;

    double a =
        math.sin(dlat / 2) * math.sin(dlat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dlon / 2) *
            math.sin(dlon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distance = earthRadius * c;

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  double _calculateEstimatedArrival(double speedMps, LatLng from, LatLng to) {
    // Simple estimation based on straight-line distance and current speed
    if (speedMps < 0.5) return 0; // Not moving

    // Calculate distance in kilometers
    const double earthRadius = 6371.0; // kilometers

    double lat1 = from.latitude * (math.pi / 180);
    double lon1 = from.longitude * (math.pi / 180);
    double lat2 = to.latitude * (math.pi / 180);
    double lon2 = to.longitude * (math.pi / 180);

    double dlon = lon2 - lon1;
    double dlat = lat2 - lat1;

    double a =
        math.sin(dlat / 2) * math.sin(dlat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dlon / 2) *
            math.sin(dlon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distanceKm = earthRadius * c;

    double speedKmh = speedMps * 3.6;
    return (distanceKm / speedKmh) * 60; // Convert to minutes
  }

  String _formatTime(double minutes) {
    if (minutes < 1) return 'less than a minute';
    if (minutes < 60) return '${minutes.round()} mins';

    int hours = (minutes / 60).floor();
    int mins = (minutes % 60).round();
    return '$hours h${mins > 0 ? ' $mins mins' : ''}';
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
