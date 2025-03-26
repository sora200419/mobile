// lib/features/task/model/task_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Task {
  final String? id;
  final String title;
  final String description;
  final String requesterId;
  final String requesterName;
  final String? providerId;
  final String? providerName;
  final String location;
  final int rewardPoints;
  final DateTime deadline;
  final String
  status; // 'open', 'assigned', 'in_transit', 'completed', 'cancelled'
  final DateTime createdAt;
  final String category; // e.g., 'delivery', 'printing', 'tutoring', etc.
  LatLng? latLng;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.requesterId,
    required this.requesterName,
    this.providerId,
    this.providerName,
    required this.location,
    required this.rewardPoints,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.category,
    this.latLng,
  });

  // Convert Task object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'providerId': providerId,
      'providerName': providerName,
      'location': location,
      'rewardPoints': rewardPoints,
      'deadline': deadline,
      'status': status,
      'createdAt': createdAt,
      'category': category,
      'latLng': latLng != null ? {'latitude': latLng!.latitude, 'longitude': latLng!.longitude} : null,
    };
  }

  // Create a Task object from a Firestore document
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    LatLng? latLng;
    if (data['latLng'] != null && data['latLng'] is Map) {
      latLng = LatLng(
        (data['latLng'] as Map)['latitude'] as double,
        (data['latLng'] as Map)['longitude'] as double,
      );
    }
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      providerId: data['providerId'],
      providerName: data['providerName'],
      location: data['location'] ?? '',
      rewardPoints: data['rewardPoints'] ?? 0,
      deadline: (data['deadline'] as Timestamp).toDate(),
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      category: data['category'] ?? 'other',
      latLng: latLng,
    );
  }

  Future<void> convertLocationToLatLng() async {
    if (location.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(location);
        if (locations.isNotEmpty) {
          latLng = LatLng(locations.first.latitude, locations.first.longitude);
        } else {
          print('Unable to find the latitude and longitude for this address: $location');
          latLng = null;
        }
      } catch (e) {
        print('Geocoding Errors: $e');
        latLng = null;
      }
    } else {
      latLng = null;
    }
  }
}