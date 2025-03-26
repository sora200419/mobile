// lib/features/task/views/map_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobiletesting/features/task/services/location_service.dart';
import 'package:mobiletesting/features/task/utility/location_tracking_tester.dart';

class MapScreen extends StatefulWidget {
  final LatLng? taskLocation;
  final String? taskId;
  final String? runnerId;
  final bool isStudent; // To determine if viewer is a student or runner

  MapScreen({
    this.taskLocation,
    this.taskId,
    this.runnerId,
    this.isStudent = false,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng _center = const LatLng(3.1390, 101.6869); // default: KL
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  // For current user location
  Location _locationService = Location();
  LocationData? _currentLocation;

  // For runner location tracking
  StreamSubscription<DatabaseEvent>? _runnerLocationSubscription;
  LatLng? _runnerLocation;
  bool _showingOwnLocation =
      false; // Flag to indicate if runner is viewing their own location

  // Tracking status
  bool _isTrackingActive = false;
  bool _isStartingTracking = false;
  bool _isStoppingTracking = false;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    debugPrint(
      'Initializing map with task ID: ${widget.taskId}, runner ID: ${widget.runnerId}',
    );

    // Initialize map center with task location if available
    if (widget.taskLocation != null) {
      _center = widget.taskLocation!;
      _addTaskMarker();
      debugPrint('Task location set as map center: $_center');
    }

    // Get current location of the device
    await _getCurrentLocation();

    // Check tracking status
    if (widget.taskId != null) {
      await _checkTrackingStatus();
    }

    // If this is a runner viewing their own location
    if (!widget.isStudent && widget.runnerId != null) {
      _showingOwnLocation = true;
      debugPrint('Runner is viewing their own location sharing');
    }

    // Start tracking runner's location
    if (widget.taskId != null) {
      _startTrackingRunnerLocation();
    }
  }

  @override
  void dispose() {
    _runnerLocationSubscription?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Add marker for task location
  void _addTaskMarker() {
    if (widget.taskLocation != null) {
      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('task_location'),
            position: widget.taskLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: const InfoWindow(title: 'Task Location'),
          ),
        );
      });
      debugPrint('Added task location marker');
    }
  }

  // Get current device location
  Future<void> _getCurrentLocation() async {
    debugPrint('Getting current device location');
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if location service is enabled
    _serviceEnabled = await _locationService.serviceEnabled();
    if (!_serviceEnabled) {
      debugPrint('Location service is not enabled, requesting...');
      _serviceEnabled = await _locationService.requestService();
      if (!_serviceEnabled) {
        debugPrint('User denied enabling location service');
        return;
      }
    }

    // Check if permission is granted
    _permissionGranted = await _locationService.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      debugPrint('Location permission denied, requesting...');
      _permissionGranted = await _locationService.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        debugPrint('User denied location permission');
        return;
      }
    }

    // Get current location
    _currentLocation = await _locationService.getLocation();
    debugPrint(
      'Current location retrieved: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}',
    );

    if (_currentLocation != null) {
      setState(() {
        // Add blue circle for user's current location
        _updateUserLocationCircle();

        // If we're a runner and no task location, center on current location
        if (!widget.isStudent && widget.taskLocation == null) {
          _center = LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          );
          debugPrint('Setting map center to current location: $_center');

          if (this.mounted && mapController != null) {
            mapController.animateCamera(CameraUpdate.newLatLng(_center));
          }
        }
      });
    }

    // Set up location change listener
    _locationService.onLocationChanged.listen((LocationData newLocation) {
      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
          _updateUserLocationCircle();
        });
      }
    });
  }

  // Update blue circle showing user's current location
  void _updateUserLocationCircle() {
    if (_currentLocation != null) {
      final userLocationCircle = Circle(
        circleId: const CircleId('user_location'),
        center: LatLng(
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
        ),
        radius: 8.0,
        fillColor: Colors.blue.withOpacity(0.7),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      );

      setState(() {
        _circles = {..._circles}; // Create a new Set
        _circles.removeWhere(
          (circle) => circle.circleId.value == 'user_location',
        );
        _circles.add(userLocationCircle);
      });
    }
  }

  // Check if location sharing is active
  Future<void> _checkTrackingStatus() async {
    if (widget.taskId == null) return;

    debugPrint('Checking tracking status for task: ${widget.taskId}');
    try {
      bool isActive = await RunnerLocationService.isTrackingActive(
        widget.taskId!,
      );

      setState(() {
        _isTrackingActive = isActive;
        _statusMessage =
            isActive
                ? 'Location sharing is active'
                : 'Location sharing is inactive';
      });

      debugPrint('Tracking status: $_isTrackingActive');
    } catch (e) {
      debugPrint('Error checking tracking status: $e');
      setState(() {
        _statusMessage = 'Error checking tracking status';
      });
    }
  }

  // Start tracking runner location from Firebase
  void _startTrackingRunnerLocation() {
    if (widget.taskId == null) return;

    debugPrint('Starting to track runner location for task: ${widget.taskId}');
    final databaseRef = FirebaseDatabase.instance.ref(
      'taskLocations/${widget.taskId}',
    );

    _runnerLocationSubscription = databaseRef.onValue.listen(
      (DatabaseEvent event) {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          debugPrint('Received location update: $data');

          final latitude = data['latitude'] as double?;
          final longitude = data['longitude'] as double?;

          if (latitude != null && longitude != null) {
            setState(() {
              _runnerLocation = LatLng(latitude, longitude);
              _updateRunnerMarker();
            });
          }
        }
      },
      onError: (error) {
        debugPrint('Error tracking runner location: $error');
      },
    );
  }

  // Update marker for runner location
  void _updateRunnerMarker() {
    if (_runnerLocation != null) {
      setState(() {
        _markers.removeWhere(
          (marker) => marker.markerId.value == 'runner_location',
        );
        _markers.add(
          Marker(
            markerId: const MarkerId('runner_location'),
            position: _runnerLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: _showingOwnLocation ? 'Your Location' : 'Runner Location',
            ),
          ),
        );
      });
    }
  }

  // Center map on specific location
  void _centerMapOn(LatLng location) {
    mapController.animateCamera(CameraUpdate.newLatLng(location));
  }

  // Toggle location sharing for runners
  Future<void> _toggleLocationSharing(BuildContext context) async {
    if (widget.taskId == null || widget.runnerId == null) {
      debugPrint('Cannot toggle location sharing: missing taskId or runnerId');
      return;
    }

    setState(() {
      if (_isTrackingActive) {
        _isStoppingTracking = true;
      } else {
        _isStartingTracking = true;
      }
    });

    try {
      final locationService = RunnerLocationService(widget.runnerId!);

      if (_isTrackingActive) {
        // Stop sharing location
        debugPrint('Stopping location sharing');
        await locationService.stopSharingLocation(widget.taskId!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location sharing stopped')),
        );

        setState(() {
          _isTrackingActive = false;
          _isStoppingTracking = false;
          _statusMessage = 'Location sharing stopped';
        });
      } else {
        // Start sharing location
        debugPrint('Starting location sharing');
        bool success = await locationService.startSharingLocation(
          widget.taskId!,
          context,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location sharing started')),
          );
          setState(() {
            _isTrackingActive = true;
            _statusMessage = 'Location sharing active';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start location sharing')),
          );
          setState(() {
            _statusMessage = 'Failed to start location sharing';
          });
        }

        setState(() {
          _isStartingTracking = false;
        });
      }

      // Force update tracking status
      await _checkTrackingStatus();
    } catch (e) {
      debugPrint('Error toggling location sharing: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));

      setState(() {
        _isStartingTracking = false;
        _isStoppingTracking = false;
        _statusMessage = 'Error managing location sharing';
      });
    }
  }

  // Build floating action buttons
  List<Widget> _buildFloatingActionButtons() {
    List<Widget> buttons = [];

    // Center on user location button
    buttons.add(
      FloatingActionButton(
        heroTag: 'btn_my_location',
        child: const Icon(Icons.my_location),
        onPressed: () {
          if (_currentLocation != null) {
            _centerMapOn(
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
            );
          }
        },
      ),
    );

    // If student view or if runner viewing own location, add button to center on runner
    if ((widget.isStudent || _showingOwnLocation) && _runnerLocation != null) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: FloatingActionButton(
            heroTag: 'btn_runner_location',
            backgroundColor: Colors.green,
            child: const Icon(Icons.person_pin_circle),
            onPressed: () {
              _centerMapOn(_runnerLocation!);
            },
            tooltip:
                _showingOwnLocation
                    ? 'Your shared location'
                    : 'Runner location',
          ),
        ),
      );
    }

    // If runner view, add button to center on task
    if (!widget.isStudent && widget.taskLocation != null) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: FloatingActionButton(
            heroTag: 'btn_task_location',
            backgroundColor: Colors.red,
            child: const Icon(Icons.place),
            onPressed: () {
              _centerMapOn(widget.taskLocation!);
            },
          ),
        ),
      );
    }

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isStudent ? 'Runner Location' : 'Task & Runner Location',
        ),
        actions: [
          if (!widget.isStudent &&
              widget.taskId != null &&
              widget.runnerId != null)
            IconButton(
              icon: Icon(
                _isTrackingActive ? Icons.location_off : Icons.location_on,
              ),
              onPressed:
                  (_isStartingTracking || _isStoppingTracking)
                      ? null
                      : () => _toggleLocationSharing(context),
              tooltip:
                  _isTrackingActive
                      ? 'Stop sharing location'
                      : 'Start sharing location',
            ),
        ],
      ),
      body: Column(
        children: [
          // Tracking status indicator
          if (!widget.isStudent &&
              widget.taskId != null &&
              widget.runnerId != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              margin: const EdgeInsets.all(8),
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
                    _statusMessage,
                    style: TextStyle(
                      color:
                          _isTrackingActive
                              ? Colors.green.shade700
                              : Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isStartingTracking || _isStoppingTracking)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              _isTrackingActive ? Colors.green : Colors.amber,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Map view
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 15.0,
              ),
              markers: _markers,
              circles: _circles,
              myLocationEnabled: false, // Using custom blue dot
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              compassEnabled: true,
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: _buildFloatingActionButtons(),
      ),
      // Debug button for runners
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      persistentFooterButtons: [
        if (!widget.isStudent && widget.taskId != null)
          ElevatedButton.icon(
            icon: const Icon(Icons.bug_report, size: 16),
            label: const Text('Debug Tracking'),
            onPressed:
                () => LocationTrackingTester.checkTrackingStatus(
                  context,
                  widget.taskId!,
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        if (!widget.isStudent &&
            widget.taskId != null &&
            widget.runnerId != null &&
            !_isTrackingActive)
          ElevatedButton.icon(
            icon: const Icon(Icons.map, size: 16),
            label: const Text('Add Test Location'),
            onPressed:
                () => LocationTrackingTester.addManualLocation(
                  context,
                  widget.taskId!,
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
      ],
    );
  }
}
