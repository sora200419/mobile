import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobiletesting/View/status_tag.dart';
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/features/task/services/task_service.dart';
import 'package:mobiletesting/features/task/views/task_chat_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'map_screen.dart';
import 'package:mobiletesting/features/task/services/location_service.dart';

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
          print('Unable to find the latitude and longitude for this address: ${widget.task.location}');
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

              // If the task is assigned and in runner view, display location sharing status instead of a button
              if (widget.task.status == 'in_transit' &&
                  widget.task.providerId ==
                      FirebaseAuth.instance.currentUser?.uid)
                SizedBox(height: 12),

              if (widget.task.status == 'in_transit' &&
                  widget.task.providerId ==
                      FirebaseAuth.instance.currentUser?.uid)
                FutureBuilder<bool>(
                  future: RunnerLocationService.isTrackingActive(
                    widget.task.id!,
                  ),
                  builder: (context, snapshot) {
                    final bool isActive = snapshot.data ?? false;

                    return Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green[50] : Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive ? Colors.green : Colors.amber,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? Icons.location_on : Icons.location_off,
                            color: isActive ? Colors.green : Colors.amber,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            isActive
                                ? 'Location Sharing Enabled'
                                : 'Location Sharing Disabled',
                            style: TextStyle(
                              color:
                                  isActive
                                      ? Colors.green[700]
                                      : Colors.amber[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isActive) ...[
                            SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                final runnerId =
                                    FirebaseAuth.instance.currentUser?.uid;
                                if (runnerId == null) return;

                                final locationService = RunnerLocationService(
                                  runnerId,
                                );
                                bool success = await locationService
                                    .startSharingLocation(
                                      widget.task.id!,
                                      context,
                                    );
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Location sharing manually enabled',
                                      ),
                                    ),
                                  );
                                  setState(() {});
                                }
                              },
                              child: Text('Manual enable'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.amber[700],
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                                minimumSize: Size(0, 0),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
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

        // When the status updates from "assigned" to "in_transit," automatically start location sharing
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? user = auth.currentUser;
        if (user != null) {
          // Start location sharing
          try {
            final locationService = RunnerLocationService(user.uid);
            bool success = await locationService.startSharingLocation(
              taskId,
              context,
            );
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Location sharing has been automatically started.',
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to start location sharing. Please enable location sharing manually.',
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          } catch (e) {
            print("Error occured while starting location sharing: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to start location sharing: $e')),
            );
            // Without interrupting the task status update process.
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
              print("Error occured while stopping location sharing: $e");
              // Without interrupting the task completion process
            }

            // 更新用户积分
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

            // update task status
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

      // Close the loading dialog and the task details page
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Return to previous screen
    } catch (error) {
      // Close the loading dialog
      Navigator.pop(context);

      // Show error message
      print("Error updating task: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task: $error'),
          backgroundColor: Colors.red,
        ),
      );
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
