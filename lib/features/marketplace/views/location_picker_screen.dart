// lib/features/marketplace/views/location_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({Key? key}) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _locationNameController = TextEditingController();

  // For demo purposes, we're using fixed coordinates
  // In a real app, you'd integrate with a map API like Google Maps
  final double _latitude = 3.1390;
  final double _longitude = 101.6869;

  @override
  void dispose() {
    _locationNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Location')),
      body: Column(
        children: [
          // Mock map
          Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.map, size: 100, color: Colors.grey),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Location name input
                TextField(
                  controller: _locationNameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    hintText: 'e.g., Campus Cafeteria',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Location coordinates
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 8),
                            const Text(
                              'Selected Location:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Latitude: $_latitude'),
                        Text('Longitude: $_longitude'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Share button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_locationNameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a location name'),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context, {
                        'location': GeoPoint(_latitude, _longitude),
                        'name': _locationNameController.text.trim(),
                      });
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('SHARE LOCATION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
