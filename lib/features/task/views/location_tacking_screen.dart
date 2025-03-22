import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

class LocationTrackingView extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const LocationTrackingView({
    Key? key,
    required this.taskId,
    required this.taskTitle,
  }) : super(key: key);

  @override
  State<LocationTrackingView> createState() => _LocationTrackingViewState();
}

class _LocationTrackingViewState extends State<LocationTrackingView> {
  GoogleMapController? _mapController;
  LatLng? _runnerPosition;
  bool _isLoading = true;
  String _statusMessage = 'Waiting for runner location...';

  @override
  void initState() {
    super.initState();
    _checkInitialPosition();
  }

  Future<void> _checkInitialPosition() async {
    try {
      DatabaseEvent event =
          await FirebaseDatabase.instance
              .ref('taskLocations/${widget.taskId}')
              .once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> locationData =
            event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _runnerPosition = LatLng(
            locationData['latitude'],
            locationData['longitude'],
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _statusMessage = 'Runner has not started sharing location yet';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading runner location: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Live Tracking: ${widget.taskTitle}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildMapContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildMapContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_statusMessage),
          ],
        ),
      );
    }

    if (_runnerPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_statusMessage, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Stack(
      children: [
        StreamBuilder<DatabaseEvent>(
          stream:
              FirebaseDatabase.instance
                  .ref('taskLocations/${widget.taskId}')
                  .onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              Map<dynamic, dynamic> locationData =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

              LatLng newPosition = LatLng(
                locationData['latitude'],
                locationData['longitude'],
              );

              // Update the map camera if controller exists
              if (_mapController != null && _runnerPosition != newPosition) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(newPosition),
                );
                _runnerPosition = newPosition;
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: newPosition,
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('runner'),
                    position: newPosition,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: InfoWindow(
                      title: 'Runner',
                      snippet:
                          'Last updated: ${DateTime.now().toString().substring(11, 16)}',
                    ),
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Updating runner location...'),
                ],
              ),
            );
          },
        ),

        // Map overlay with estimated arrival
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
                            .ref('taskLocations/${widget.taskId}')
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
                        );

                        return Text(
                          'Runner is ${_formatDistance(_runnerPosition!)} away' +
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
      ],
    );
  }

  // Helper methods for map view
  String _formatDistance(LatLng position) {
    // This is a simplistic calculation - in a real app you'd use the
    // geolocator package to calculate actual route distance
    return '1.2 km';
  }

  double _calculateEstimatedArrival(double speedMps) {
    // Simple estimation based on straight-line distance and current speed
    if (speedMps < 0.5) return 0; // Not moving

    // In a real implementation, you would calculate the actual route distance
    double distanceKm = 1.2; // Example distance
    double speedKmh = speedMps * 3.6;
    return (distanceKm / speedKmh) * 60; // Convert to minutes
  }

  String _formatTime(double minutes) {
    if (minutes < 1) return 'less than a minute';
    if (minutes < 60) return '${minutes.round()} mins';

    int hours = (minutes / 60).floor();
    int mins = (minutes % 60).round();
    return '$hours h ${mins > 0 ? '$mins mins' : ''}';
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
