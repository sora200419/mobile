import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import 'package:mobiletesting/features/task/services/location_service.dart';

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
  bool _showingOwnLocation = false; // Flag to indicate if runner is viewing their own location

  // For directions
  Polyline? _directionsPolyline;

  @override
  void initState() {
    super.initState();

    // Initialize map center with task location if available
    if (widget.taskLocation != null) {
      _center = widget.taskLocation!;
      _addTaskMarker();
    }

    // Get current location of the device
    _getCurrentLocation();

    // If student view or if runner wants to see their own location, start tracking runner's location
    if ((widget.isStudent || !widget.isStudent) && widget.taskId != null) {
      _startTrackingRunnerLocation();

      // If this is a runner viewing their own location
      if (!widget.isStudent && widget.runnerId != null) {
        _showingOwnLocation = true;
      }
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
            markerId: MarkerId('task_location'),
            position: widget.taskLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: 'Task Location'),
          ),
        );
      });
    }
  }

  // Get current device location
  Future<void> _getCurrentLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if location service is enabled
    _serviceEnabled = await _locationService.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationService.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Check if permission is granted
    _permissionGranted = await _locationService.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationService.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get current location
    _currentLocation = await _locationService.getLocation();

    if (_currentLocation != null) {
      setState(() {
        // Add blue circle for user's current location
        _updateUserLocationCircle();

        // If we're a runner and no task location, center on current location
        if (!widget.isStudent && widget.taskLocation == null) {
          _center = LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
          mapController.animateCamera(
            CameraUpdate.newLatLng(_center),
          );
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
        circleId: CircleId('user_location'),
        center: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        radius: 8.0,
        fillColor: Colors.blue.withOpacity(0.7),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      );

      setState(() {
        _circles = {..._circles}; // Create a new Set
        _circles.removeWhere((circle) => circle.circleId.value == 'user_location');
        _circles.add(userLocationCircle);
      });
    }
  }

  // Start tracking runner location from Firebase
  void _startTrackingRunnerLocation() {
    final databaseRef = FirebaseDatabase.instance.ref('taskLocations/${widget.taskId}');

    _runnerLocationSubscription = databaseRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        final latitude = data['latitude'] as double?;
        final longitude = data['longitude'] as double?;

        if (latitude != null && longitude != null) {
          setState(() {
            _runnerLocation = LatLng(latitude, longitude);
            _updateRunnerMarker();
          });
        }
      }
    }, onError: (error) {
      debugPrint('Error tracking runner location: $error');
    });
  }

  // Update marker for runner location
  void _updateRunnerMarker() {
    if (_runnerLocation != null) {
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'runner_location');
        _markers.add(
          Marker(
            markerId: MarkerId('runner_location'),
            position: _runnerLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
                title: _showingOwnLocation ? 'Your Location' : 'Runner Location'
            ),
          ),
        );
      });
    }
  }

  // Center map on specific location
  void _centerMapOn(LatLng location) {
    mapController.animateCamera(
      CameraUpdate.newLatLng(location),
    );
  }

  // Build floating action buttons
  List<Widget> _buildFloatingActionButtons() {
    List<Widget> buttons = [];

    // Center on user location button
    buttons.add(
      FloatingActionButton(
        heroTag: 'btn_my_location',
        child: Icon(Icons.my_location),
        onPressed: () {
          if (_currentLocation != null) {
            _centerMapOn(LatLng(
                _currentLocation!.latitude!,
                _currentLocation!.longitude!
            ));
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
            child: Icon(Icons.person_pin_circle),
            onPressed: () {
              _centerMapOn(_runnerLocation!);
            },
            tooltip: _showingOwnLocation ? 'Your shared location' : 'Runner location',
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
            child: Icon(Icons.place),
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
        title: Text(widget.isStudent ? 'Runner Location' : 'Task & Runner Location'),
        actions: [
          if (!widget.isStudent && widget.taskId != null && widget.runnerId != null)
            IconButton(
              icon: Icon(Icons.share_location),
              onPressed: () => _toggleLocationSharing(context),
            ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(target: _center, zoom: 15.0),
        markers: _markers,
        circles: _circles,
        polylines: _directionsPolyline != null ? {_directionsPolyline!} : {},
        myLocationEnabled: false, // Using custom blue dot
        myLocationButtonEnabled: false,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: _buildFloatingActionButtons(),
      ),
    );
  }

  // Toggle location sharing for runners
  Future<void> _toggleLocationSharing(BuildContext context) async {
    if (widget.taskId == null || widget.runnerId == null) return;

    final isActive = await _isLocationSharingActive();

    if (isActive) {
      // Stop sharing location
      try {
        final locationService = RunnerLocationService(widget.runnerId!);
        await locationService.stopSharingLocation(widget.taskId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location sharing stopped')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop location sharing: $e')),
        );
      }
    } else {
      // Start sharing location
      try {
        final locationService = RunnerLocationService(widget.runnerId!);
        await locationService.startSharingLocation(widget.taskId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location sharing started')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start location sharing: $e')),
        );
      }
    }
  }

  // Check if location sharing is active
  Future<bool> _isLocationSharingActive() async {
    if (widget.taskId == null) return false;
    return await RunnerLocationService.isTrackingActive(widget.taskId!);
  }
}