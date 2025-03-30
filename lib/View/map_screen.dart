// lib\View\map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:campuslink/features/task/services/location_service.dart';

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
  bool _initialPositionSet = false;

  // For current user location
  Location _locationService = Location();
  LocationData? _currentLocation;

  // For runner location tracking
  StreamSubscription<DocumentSnapshot>? _runnerLocationSubscription;
  LatLng? _runnerLocation;
  bool _showingOwnLocation =
      false; // Flag to indicate if runner is viewing their own location
  bool _runnerLocationUpdated =
      false; // Flag to track if runner location was received

  // For directions
  Polyline? _directionsPolyline;

  // Timer for auto-timeout
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();

    debugPrint(
      "MapScreen initialized with isStudent=${widget.isStudent}, taskId=${widget.taskId}, runnerId=${widget.runnerId}",
    );

    // Initialize map center with task location if available
    if (widget.taskLocation != null) {
      _center = widget.taskLocation!;
      _addTaskMarker();
    }

    // Get current location of the device
    _getCurrentLocation();

    // Start tracking runner's location if we have a task ID
    if (widget.taskId != null) {
      debugPrint("Starting to track runner location for task ${widget.taskId}");
      _startTrackingRunnerLocation();

      // If this is a runner viewing their own location
      if (!widget.isStudent && widget.runnerId != null) {
        _showingOwnLocation = true;
        debugPrint("Runner is viewing their own location");
      }
    }

    // Set up a timeout for loading indicator
    if (widget.isStudent) {
      _loadingTimer = Timer(Duration(seconds: 15), () {
        if (mounted && !_runnerLocationUpdated) {
          setState(() {
            // Force show map even if no location yet
            _runnerLocationUpdated = true;
            debugPrint("Auto-timeout triggered for loading indicator");
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _runnerLocationSubscription?.cancel();
    _loadingTimer?.cancel();
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
      debugPrint("Added task marker at ${widget.taskLocation}");
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
        debugPrint("Location service not enabled by user");
        return;
      }
    }

    // Check if permission is granted
    _permissionGranted = await _locationService.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationService.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        debugPrint("Location permission not granted by user");
        return;
      }
    }

    // Get current location
    _currentLocation = await _locationService.getLocation();

    if (_currentLocation != null && mounted) {
      setState(() {
        // Add blue circle for user's current location
        _updateUserLocationCircle();

        // If we're a runner and no task location, center on current location
        if (!widget.isStudent && widget.taskLocation == null) {
          _center = LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          );
          mapController.animateCamera(CameraUpdate.newLatLng(_center));
          debugPrint("Centered map on runner's current location: $_center");
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

      // Add a clear marker for current user
      final userLocationMarker = Marker(
        markerId: const MarkerId('current_user_marker'),
        position: LatLng(
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your current location'),
      );

      setState(() {
        // Update circles
        _circles = {..._circles}; // create new collection
        _circles.removeWhere(
          (circle) => circle.circleId.value == 'user_location',
        );
        _circles.add(userLocationCircle);

        // update markers
        _markers = {..._markers}; // create new collection
        _markers.removeWhere(
          (marker) => marker.markerId.value == 'current_user_marker',
        );
        _markers.add(userLocationMarker);
      });

      // if the initial position has not set, set the center of map to current location
      if (!_initialPositionSet && !widget.isStudent) {
        mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          ),
        );
        _initialPositionSet = true;
        debugPrint("Set initial map position to user's location");
      }
    }
  }

  // Start tracking runner location from Firestore - MODIFIED
  void _startTrackingRunnerLocation() {
    if (widget.taskId == null) {
      debugPrint("Cannot track location: No task ID provided");
      return;
    }

    // For student view, verify tracking status and show appropriate feedback
    if (widget.isStudent) {
      debugPrint("Student view: Checking runner location tracking status");

      // Check if tracking is active
      RunnerLocationService.isTrackingActive(widget.taskId!)
          .then((isActive) {
            debugPrint(
              "Runner tracking status: ${isActive ? 'ACTIVE' : 'INACTIVE'}",
            );

            if (!isActive && mounted) {
              // Show a more informative message if tracking isn't active
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Runner has not started sharing location yet. ' +
                        'Wait for runner to begin their delivery.',
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
            }
          })
          .catchError((error) {
            debugPrint("Error checking if tracking is active: $error");
          });
    }

    // Set up the Firestore reference for location updates
    final firestoreRef = FirebaseFirestore.instance
        .collection('taskLocations')
        .doc(widget.taskId);

    debugPrint(
      "Subscribing to Firestore document: taskLocations/${widget.taskId}",
    );

    // Add a one-time check to see if data exists already
    firestoreRef.get().then((snapshot) {
      if (snapshot.exists) {
        debugPrint("Found existing location data in Firestore");
        // If data exists, try to initialize immediately
        try {
          final data = snapshot.data() as Map<String, dynamic>;
          final latitude = data['latitude'] as double?;
          final longitude = data['longitude'] as double?;

          if (latitude != null && longitude != null && mounted) {
            setState(() {
              _runnerLocation = LatLng(latitude, longitude);
              _runnerLocationUpdated = true;
              _updateRunnerMarker();

              // Center map on runner's location for student view
              if (widget.isStudent) {
                mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 15.0),
                );
                _initialPositionSet = true;
                debugPrint("Centered student view on existing runner location");
              }
            });
          }
        } catch (e) {
          debugPrint("Error processing existing location data: $e");
        }
      } else {
        debugPrint("No existing location data found in Firestore");
      }
    });

    // Subscribe to real-time updates using Firestore snapshots
    _runnerLocationSubscription = firestoreRef.snapshots().listen(
      (snapshot) {
        debugPrint(
          "Received location update from Firestore: ${snapshot.exists}",
        );
        if (snapshot.exists && snapshot.data() != null) {
          try {
            final data = snapshot.data() as Map<String, dynamic>;
            final latitude = data['latitude'] as double?;
            final longitude = data['longitude'] as double?;

            if (latitude != null && longitude != null) {
              debugPrint("Runner location updated: $latitude, $longitude");
              if (mounted) {
                setState(() {
                  _runnerLocation = LatLng(latitude, longitude);
                  _runnerLocationUpdated = true;
                  _updateRunnerMarker();

                  // For student view, center on runner's location when it's first received
                  if (widget.isStudent && !_initialPositionSet) {
                    mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(latitude, longitude),
                        15.0,
                      ),
                    );
                    _initialPositionSet = true;
                    debugPrint("Centered student view on runner's location");
                  }
                });
              }
            }
          } catch (e) {
            debugPrint("Error processing location data: $e");
          }
        } else {
          debugPrint("No location data received from Firestore");
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
        debugPrint("Updated runner marker at $_runnerLocation");
      });
    }
  }

  // Center map on specific location
  void _centerMapOn(LatLng location) {
    mapController.animateCamera(CameraUpdate.newLatLng(location));
    debugPrint("Centered map on location: $location");
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
              icon: const Icon(Icons.share_location),
              onPressed: () => _toggleLocationSharing(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Always show the map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 15.0),
            markers: _markers,
            circles: _circles,
            polylines:
                _directionsPolyline != null ? {_directionsPolyline!} : {},
            myLocationEnabled: false, // Using custom blue dot
            myLocationButtonEnabled: false,
          ),

          // Show loading indicator if student view and no runner location yet
          if (widget.isStudent && !_runnerLocationUpdated)
            Center(
              child: Card(
                elevation: 4.0,
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "Waiting for runner location updates...",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
          const SnackBar(content: Text('Location sharing stopped')),
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
        await locationService.startSharingLocation(widget.taskId!, context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location sharing started')),
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
