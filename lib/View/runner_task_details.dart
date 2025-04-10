//lib\View\runner_task_details.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campuslink/View/status_tag.dart';
import 'package:campuslink/features/task/model/task_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campuslink/features/task/views/task_chat_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'map_screen.dart';
import 'package:campuslink/features/task/services/location_service.dart';

class TaskDetailsPage extends StatefulWidget {
  final Task task;

  TaskDetailsPage({required this.task});

  @override
  _TaskDetailsPageState createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  LatLng? _taskLocation;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    print('Attempting to load location for: ${widget.task.location}');
    if (widget.task.latLng != null) {
      print('Location already has LatLng: ${widget.task.latLng}');
      setState(() {
        _taskLocation = widget.task.latLng;
        _isLoadingLocation = false;
      });
    } else if (widget.task.location.isNotEmpty) {
      try {
        print('Performing geocoding for: ${widget.task.location}');
        List<Location> locations = await locationFromAddress(
          widget.task.location,
        );
        print('Geocoding results: $locations');
        if (locations.isNotEmpty) {
          setState(() {
            _taskLocation = LatLng(
              locations.first.latitude,
              locations.first.longitude,
            );
            _isLoadingLocation = false;
          });
          print('Successfully geocoded to: $_taskLocation');
        } else {
          print(
            'Unable to find the latitude and longitude for this address: ${widget.task.location}',
          );
          setState(() {
            _isLoadingLocation = false;
          });
        }
      } catch (e) {
        print('Geocoding error: $e');
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } else {
      setState(() {
        _isLoadingLocation = false;
        print('Location string is empty.');
      });
    }
  }

  String _getButtonLabel(String status) {
    switch (status) {
      case 'open':
        return 'Accept';
      case 'assigned':
        return 'Picked Up';
      case 'in_transit':
        return 'Completed';
      default:
        return 'Accept';
    }
  }

  Color _getButtonColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green[50]!;
      case 'assigned':
        return Colors.orange[50]!;
      case 'in_transit':
        return Colors.lightBlue[50]!;
      default:
        return Colors.green[50]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Task Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusTag(status: widget.task.status),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.shopping_cart, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        widget.task.category,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildDetailRow("Description", widget.task.description),
              SizedBox(height: 16),
              _buildDetailRow(
                "Reward Points",
                "${widget.task.rewardPoints} points",
                icon: Icons.stars_rounded,
                iconColor: Colors.amber,
              ),
              SizedBox(height: 16),
              _buildDetailRow(
                "Location",
                widget.task.location,
                icon: Icons.location_on,
                iconColor: Colors.red,
              ),
              SizedBox(height: 16),
              _buildDetailRow(
                "Deadline",
                DateFormat('dd/MM/yyyy').format(widget.task.deadline),
                icon: Icons.calendar_today,
                iconColor: Colors.blue,
              ),
              SizedBox(height: 16),
              _buildDetailRow(
                "Requested By",
                widget.task.requesterName,
                icon: Icons.person,
                iconColor: Colors.purple,
              ),
              SizedBox(height: 25),

              // Button to view task location map
              ElevatedButton.icon(
                onPressed: () {
                  if (_taskLocation != null) {
                    // get current user id
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You need to be logged in to view the map',
                          ),
                        ),
                      );
                      return;
                    }

                    final bool isStudent =
                        widget.task.requesterId == currentUser.uid;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MapScreen(
                              taskLocation: _taskLocation,
                              taskId: widget.task.id,
                              runnerId: widget.task.providerId,
                              isStudent: isStudent,
                            ),
                      ),
                    );
                  } else if (!_isLoadingLocation) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to get location')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Loading location...')),
                    );
                  }
                },
                icon: Icon(Icons.map),
                label: Text('View on Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),

              // If the task is assigned and in student view, add a button to view the runner's location.
              if (widget.task.status != 'open' &&
                  widget.task.status != 'completed' &&
                  widget.task.providerId != null &&
                  widget.task.requesterId ==
                      FirebaseAuth.instance.currentUser?.uid)
                SizedBox(height: 12),

              if (widget.task.status != 'open' &&
                  widget.task.status != 'completed' &&
                  widget.task.providerId != null &&
                  widget.task.requesterId ==
                      FirebaseAuth.instance.currentUser?.uid)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MapScreen(
                              taskId: widget.task.id,
                              runnerId: widget.task.providerId,
                              isStudent: true, // Force set to student view
                            ),
                      ),
                    );
                  },
                  icon: Icon(Icons.person_pin_circle),
                  label: Text('Track Runner Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[50],
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),

              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (widget.task.status != 'completed')
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _updateTask(
                              context,
                              widget.task.id!,
                              widget.task.status,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getButtonColor(
                              widget.task.status,
                            ),
                          ),
                          icon: Icon(Icons.check_circle),
                          label: Text(_getButtonLabel(widget.task.status)),
                        ),
                      ),
                    ),
                  if (widget.task.providerId != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        TaskChatScreen(task: widget.task),
                              ),
                            );
                          },
                          icon: Icon(Icons.chat),
                          label: Text("Chat"),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String title,
    String value, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: 24),
              SizedBox(width: 8),
            ],
            Text(value),
          ],
        ),
      ],
    );
  }

  void _updateTask(
    BuildContext context,
    String taskId,
    String currentStatus,
  ) async {
    String newStatus;
    switch (currentStatus) {
      case 'open':
        newStatus = 'assigned';
        // get current runner uid and name
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? user = auth.currentUser;
        if (user != null) {
          final String providerId = user.uid;
          final String providerName = await _getCurrentRunnerName();
          try {
            await FirebaseFirestore.instance
                .collection('tasks')
                .doc(taskId)
                .update({
                  'status': newStatus,
                  'providerId': providerId,
                  'providerName': providerName,
                });
            Navigator.pop(context);
          } catch (error) {
            print("Error updating task status: $error");
          }
        } else {
          print("Error: User not logged in.");
        }
        return; // Update providerId and providerName when the status is 'open' only

      case 'assigned':
        newStatus = 'in_transit';

        // When status changes from "assigned" to "in_transit"
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? user = auth.currentUser;
        if (user != null) {
          // Show a progress indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Starting location sharing...')),
          );

          // Start location sharing using Firestore
          try {
            final locationService = RunnerLocationService(user.uid);
            bool success = await locationService.startSharingLocation(
              taskId,
              context,
            );

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location sharing started successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              // If it fails, show a more detailed error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Location sharing failed. Please check your location permissions.',
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'RETRY',
                    onPressed: () async {
                      // Manually try to start location sharing again
                      await locationService.startSharingLocation(
                        taskId,
                        context,
                      );
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            print("Error starting location sharing: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error starting location sharing: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;

      case 'in_transit':
        newStatus = 'completed';
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? user = auth.currentUser;
        if (user != null) {
          final String userId = user.uid;
          final int rewardPoints = widget.task.rewardPoints;
          try {
            // Stop location sharing
            try {
              final locationService = RunnerLocationService(user.uid);
              await locationService.stopSharingLocation(taskId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Location sharing has been automatically stopped.',
                  ),
                ),
              );
            } catch (e) {
              print("Error occurred while stopping location sharing: $e");
              // Without interrupting the task completion process
            }

            // Update user points
            DocumentSnapshot userDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get();

            if (userDoc.exists) {
              int currentPoints =
                  (userDoc.data() as Map<String, dynamic>)['points'] ?? 0;
              int newPoints = currentPoints + rewardPoints;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({'points': newPoints});
              print('User points updated: $newPoints');
            } else {
              print('User document not found.');
            }

            // Update task status
            await FirebaseFirestore.instance
                .collection('tasks')
                .doc(taskId)
                .update({'status': newStatus});
            Navigator.pop(context);
          } catch (error) {
            print("Error updating task status or user points: $error");
          }
        } else {
          print("Error: User not logged in.");
        }
        return;

      default:
        return;
    }

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'status': newStatus,
      });
      Navigator.pop(context);
    } catch (error) {
      print("Error updating task status: $error");
    }
  }

  Future<String> _getCurrentRunnerName() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          return (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Runner';
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
    return 'Runner';
  }
}
