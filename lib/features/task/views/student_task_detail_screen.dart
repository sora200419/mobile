//lib\features\task\views\student_task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:campuslink/features/task/model/task_model.dart';
import 'package:campuslink/features/task/services/task_service.dart';
import 'package:campuslink/features/task/views/task_chat_screen.dart';
import 'package:campuslink/features/task/views/task_rating_screen.dart';
import 'package:campuslink/features/task/services/rating_service.dart';
import 'package:provider/provider.dart';
import 'package:campuslink/services/auth_provider.dart';
import 'package:campuslink/utils/ui_utils.dart';
import 'package:campuslink/utils/formatting_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:campuslink/View/map_screen.dart';
import 'package:campuslink/features/task/services/location_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final bool isCreating;
  final Task? task;

  const TaskDetailScreen({Key? key, required this.isCreating, this.task})
    : super(key: key);
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  final RatingService _ratingService = RatingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for creating a new task
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedLocation;
  String _selectedCategory = 'Other';
  int _calculatedRewardPoints = 5; // Default base points

  bool _isLoading = false;
  bool _hasUserRatedTask = false;

  // Location related variables
  LatLng? _taskLocation;
  bool _isLoadingLocation = true;

  // List of task categories
  final List<String> _categories = [
    'Delivery',
    'Printing',
    'Tutoring',
    'Food',
    'Shopping',
    'Technical Help',
    'Other',
  ];

  // Base points for each category
  final Map<String, int> _categoryBasePoints = {
    'Delivery': 8,
    'Printing': 5,
    'Tutoring': 10,
    'Food': 7,
    'Shopping': 9,
    'Technical Help': 12,
    'Other': 5,
  };

  // List of task locations
  final List<String> _locations = [
    'APU Dormitory K1',
    'APU Satellite Residence',
    'Parkhill Residence',
  ];

  @override
  void initState() {
    super.initState();

    // If we're editing a task, populate the fields
    if (!widget.isCreating && widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedLocation = widget.task!.location;
      _selectedDate = widget.task!.deadline;
      _selectedCategory = widget.task!.category;
      _calculatedRewardPoints = widget.task!.rewardPoints;

      // Load location coordinates
      _loadLocation();

      // Check if user has already rated this task
      if (widget.task!.status == 'completed' && widget.task!.id != null) {
        _checkIfUserRatedTask();
      }
    } else {
      // For new tasks, calculate initial points
      _calculateRewardPoints();
    }
  }

  Future<void> _loadLocation() async {
    debugPrint('Attempting to load location for: ${widget.task!.location}');
    if (widget.task!.latLng != null) {
      debugPrint('Location already has LatLng: ${widget.task!.latLng}');
      setState(() {
        _taskLocation = widget.task!.latLng;
        _isLoadingLocation = false;
      });
    } else if (widget.task!.location.isNotEmpty) {
      try {
        debugPrint('Performing geocoding for: ${widget.task!.location}');
        List<Location> locations = await locationFromAddress(
          widget.task!.location,
        );
        debugPrint('Geocoding results: $locations');
        if (locations.isNotEmpty) {
          setState(() {
            _taskLocation = LatLng(
              locations.first.latitude,
              locations.first.longitude,
            );
            _isLoadingLocation = false;
          });
          debugPrint('Successfully geocoded to: $_taskLocation');
        } else {
          debugPrint(
            'Unable to find the latitude and longitude for this address: ${widget.task!.location}',
          );
          setState(() {
            _isLoadingLocation = false;
          });
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } else {
      setState(() {
        _isLoadingLocation = false;
        debugPrint('Location string is empty.');
      });
    }
  }

  // Method to handle map navigation - MODIFIED
  void _viewOnMap() {
    // Get current user id
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to view the map'),
        ),
      );
      return;
    }

    // Check if location is still loading
    if (_isLoadingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location is still loading. Please try again in a moment.',
          ),
        ),
      );
      return;
    }

    // Check if location is available
    if (_taskLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to locate this address. Please check the location details.',
          ),
        ),
      );
      return;
    }

    // Determine if this is a student or runner view
    final bool isStudent = widget.task!.requesterId == currentUser.uid;

    // Simplify logic - for students with assigned tasks, always enable tracking
    if (isStudent &&
        (widget.task!.status == 'assigned' ||
            widget.task!.status == 'in_transit') &&
        widget.task!.providerId != null) {
      // Navigate to map screen with tracking parameters
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MapScreen(
                taskLocation: _taskLocation,
                taskId: widget.task!.id,
                runnerId: widget.task!.providerId,
                isStudent: true, // Force student view
              ),
        ),
      );
    } else {
      // Otherwise just show task location
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MapScreen(
                taskLocation: _taskLocation,
                taskId: widget.task!.id,
                runnerId: widget.task!.providerId,
                isStudent: isStudent,
              ),
        ),
      );
    }
  }

  Future<void> _checkIfUserRatedTask() async {
    if (widget.task == null || widget.task!.id == null) return;

    try {
      bool hasRated = await _ratingService.hasUserRatedTask(widget.task!.id!);

      if (mounted) {
        setState(() {
          _hasUserRatedTask = hasRated;
        });
      }
    } catch (e) {
      debugPrint('Error checking if user has rated task: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Calculate reward points based on task details
  void _calculateRewardPoints() {
    // Base points from selected category
    int basePoints = _categoryBasePoints[_selectedCategory] ?? 5;

    // Urgency factor: closer deadlines = more points
    int daysUntilDeadline = _selectedDate.difference(DateTime.now()).inDays;
    double urgencyMultiplier = 1.0;
    if (daysUntilDeadline <= 1) {
      urgencyMultiplier = 1.5; // Same day or next day
    } else if (daysUntilDeadline <= 3) {
      urgencyMultiplier = 1.2; // Within 3 days
    }

    // Description complexity factor (based on length)
    double complexityFactor = 1.0;
    int descriptionLength = _descriptionController.text.length;
    if (descriptionLength > 100) {
      complexityFactor = 1.2; // More detailed description
    } else if (descriptionLength > 50) {
      complexityFactor = 1.1; // Moderately detailed
    }

    // Calculate total points and round to nearest integer
    double totalPoints = basePoints * urgencyMultiplier * complexityFactor;

    // Set the calculated reward points
    setState(() {
      _calculatedRewardPoints = totalPoints.round();
    });
  }

  // Display date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // Recalculate points when deadline changes
      _calculateRewardPoints();
    }
  }

  // Create a new task
  Future<void> _createTask() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user name
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      String userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? '';

      // Create task object with calculated reward points
      Task newTask = Task(
        title: _titleController.text,
        description: _descriptionController.text,
        requesterId: user.uid,
        requesterName: userName,
        location: _selectedLocation!, // Use selected location
        rewardPoints: _calculatedRewardPoints,
        deadline: _selectedDate,
        status: 'open',
        createdAt: DateTime.now(),
        category: _selectedCategory,
      );

      // Save to Firestore
      await _taskService.createTask(newTask);

      // Return to previous screen
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Accept a task
  Future<void> _acceptTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.acceptTask(widget.task!.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh page
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mark task as in transit
  Future<void> _markInTransit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.markTaskInTransit(widget.task!.id!);

      // When status changes from "assigned" to "in_transit"
      final User? user = _auth.currentUser;
      if (user != null) {
        // Show a progress indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Starting location sharing...')),
        );

        // Start location sharing using Firestore
        try {
          final locationService = RunnerLocationService(user.uid);
          bool success = await locationService.startSharingLocation(
            widget.task!.id!,
            context,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location sharing started successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // If it fails, show a more detailed error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Location sharing failed. Please check your location permissions.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'RETRY',
                  onPressed: () async {
                    // Manually try to start location sharing again
                    await locationService.startSharingLocation(
                      widget.task!.id!,
                      context,
                    );
                  },
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint("Error starting location sharing: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error starting location sharing: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // Refresh page
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Inside the _completeTask() method:
  Future<void> _completeTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.completeTask(widget.task!.id!);

      // Stop location sharing
      final User? user = _auth.currentUser;
      if (user != null) {
        try {
          final locationService = RunnerLocationService(user.uid);
          await locationService.stopSharingLocation(widget.task!.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location sharing has been automatically stopped.'),
            ),
          );
        } catch (e) {
          debugPrint("Error occurred while stopping location sharing: $e");
          // Without interrupting the task completion process
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task marked as completed'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh page
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Inside the _viewOnMap() method:

  // Navigate to rating screen
  void _navigateToRatingScreen(String userIdToRate, String userNameToRate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TaskRatingScreen(
              task: widget.task!,
              userIdToRate: userIdToRate,
              userNameToRate: userNameToRate,
            ),
      ),
    ).then((rated) {
      if (rated == true) {
        // Update the state to reflect that user has now rated
        setState(() {
          _hasUserRatedTask = true;
        });
      }
    });
  }

  // Cancel a task
  Future<void> _cancelTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.cancelTask(widget.task!.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task cancelled'),
          backgroundColor: Colors.orange,
        ),
      );

      // Refresh page
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreating ? 'Create New Task' : 'Task Details'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : widget.isCreating
              ? _buildCreateTaskForm()
              : _buildTaskDetails(),
    );
  }

  // Form for creating a new task
  Widget _buildCreateTaskForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
            onChanged: (_) => _calculateRewardPoints(),
          ),
          const SizedBox(height: 16),

          // Description field
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 200,
            onChanged: (_) => _calculateRewardPoints(),
          ),
          const SizedBox(height: 16),

          // Location dropdown
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              value: _selectedLocation,
              hint: const Text('Select Location'),
              items:
                  _locations.map((String location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLocation = newValue;
                });
              },
              validator:
                  (value) => value == null ? 'Please select a location' : null,
            ),
          ),

          // Category dropdown
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items:
                  _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                  _calculateRewardPoints();
                }
              },
            ),
          ),

          // Deadline date picker
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Deadline',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Display calculated reward points
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reward Points: $_calculatedRewardPoints',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Points are calculated based on task category, deadline urgency, and description length.',
                        style: TextStyle(color: Colors.amber.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Point explanation
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You will earn 5 points for creating this task, and additional points when the task is completed with good feedback!',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Create Task', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // Display task details
  Widget _buildTaskDetails() {
    final task = widget.task!;
    final currentUserId = _auth.currentUser?.uid ?? '';

    // Get user role
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.role;

    final bool isRequester = task.requesterId == currentUserId;
    final bool isProvider = task.providerId == currentUserId;

    // Only runners can accept tasks, not students
    final bool canAccept =
        task.status == 'open' && !isRequester && userRole == 'Runner';

    // Only the provider can mark a task as in transit, and only when it's assigned
    final bool canMarkInTransit = task.status == 'assigned' && isProvider;

    // Only the provider can mark a task as completed, and only when it's in transit
    final bool canComplete = task.status == 'in_transit' && isProvider;

    // Both provider and requester can cancel a task if it's not yet completed
    final bool canCancel =
        (task.status == 'open' ||
            task.status == 'assigned' ||
            task.status == 'in_transit') &&
        (isRequester || isProvider);

    // Rating button logic - can rate only if the task is completed and user is a student
    final bool isCompleted = task.status == 'completed';
    final bool canRate = isCompleted && isRequester && !_hasUserRatedTask;

    // Map visibility logic - show map button if location exists or task has a runner
    final bool canViewMap = task.location.isNotEmpty;

    // Define who to rate - students can only rate runners, not the other way around
    String? userIdToRate;
    String? userNameToRate;

    if (isRequester && task.providerId != null) {
      // Requester (student) rates the provider (runner)
      userIdToRate = task.providerId!;
      userNameToRate = task.providerName ?? 'Runner';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [UIUtils.buildStatusBadge(task.status)],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            task.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Category
          Row(
            children: [
              const Icon(Icons.category, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(task.category, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(task.description),
          const SizedBox(height: 16),

          // Reward points
          const Text(
            'Reward Points',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                '${task.rewardPoints} points',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location
          const Text(
            'Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Text(task.location),
            ],
          ),
          const SizedBox(height: 16),

          // Deadline
          const Text(
            'Deadline',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue),
              const SizedBox(width: 8),
              Text(FormattingUtils.formatDate(task.deadline)),
            ],
          ),
          const SizedBox(height: 16),

          // Requester
          const Text(
            'Requested By',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.purple),
              const SizedBox(width: 8),
              Text(task.requesterName),
            ],
          ),
          const SizedBox(height: 16),

          // Provider (if assigned)
          if (task.providerId != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accepted By',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(task.providerName ?? 'Unknown'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),

          // View on Map button - MODIFIED to include tracking automatically
          if (canViewMap)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _viewOnMap,
                icon:
                    isRequester &&
                            (task.status == 'assigned' ||
                                task.status == 'in_transit') &&
                            task.providerId != null
                        ? const Icon(
                          Icons.person_pin_circle,
                        ) // Show tracking icon for students when runner assigned
                        : const Icon(
                          Icons.map,
                        ), // Show regular map icon otherwise
                label:
                    isRequester &&
                            (task.status == 'assigned' ||
                                task.status == 'in_transit') &&
                            task.providerId != null
                        ? const Text(
                          'View & Track on Map',
                        ) // Change label for tracking
                        : const Text('View on Map'), // Regular label
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isRequester &&
                              (task.status == 'assigned' ||
                                  task.status == 'in_transit') &&
                              task.providerId != null
                          ? Colors.green[50] // Green background for tracking
                          : Colors.blue[50], // Blue background otherwise
                  foregroundColor:
                      isRequester &&
                              (task.status == 'assigned' ||
                                  task.status == 'in_transit') &&
                              task.providerId != null
                          ? Colors.green[800] // Green text for tracking
                          : null, // Default text color otherwise
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Role-specific information
          if (userRole == 'Student' && task.status == 'open')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This task is awaiting a runner to accept it. Only campus runners can accept tasks.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Status explanation for in transit tasks
          if (task.status == 'in_transit')
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_run, color: Colors.teal.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This task is currently in progress! The runner is on their way.',
                      style: TextStyle(color: Colors.teal.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Status explanation for completed tasks
          if (task.status == 'completed')
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This task has been completed successfully!',
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (canAccept)
                ElevatedButton.icon(
                  onPressed: _acceptTask,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Accept Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),

              if (canMarkInTransit)
                ElevatedButton.icon(
                  onPressed: _markInTransit,
                  icon: const Icon(Icons.directions_run),
                  label: const Text('Start Delivery'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),

              if (canComplete)
                ElevatedButton.icon(
                  onPressed: _completeTask,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),

              if (canCancel)
                ElevatedButton.icon(
                  onPressed: _cancelTask,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Rating button (only for completed tasks and students)
          if (canRate && userIdToRate != null && userNameToRate != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    () =>
                        _navigateToRatingScreen(userIdToRate!, userNameToRate!),
                icon: const Icon(Icons.star),
                label: const Text('Rate Runner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          // Rating completed message
          if (isCompleted && isRequester && _hasUserRatedTask)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have already rated this task. Thank you for your feedback!',
                      style: TextStyle(color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Chat button (only available if task is assigned or in transit)
          if ((task.status == 'assigned' || task.status == 'in_transit') &&
              (isRequester || isProvider))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskChatScreen(task: task),
                    ),
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Chat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
