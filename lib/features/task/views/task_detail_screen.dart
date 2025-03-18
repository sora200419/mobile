// lib/features/task/views/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:mobiletesting/features/task/services/task_service.dart';
import 'package:mobiletesting/features/task/views/task_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobiletesting/services/auth_provider.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for creating a new task
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _rewardPointsController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedCategory = 'Other';

  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();

    // If we're editing a task, populate the fields
    if (!widget.isCreating && widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _locationController.text = widget.task!.location;
      _rewardPointsController.text = widget.task!.rewardPoints.toString();
      _selectedDate = widget.task!.deadline;
      _selectedCategory = widget.task!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _rewardPointsController.dispose();
    super.dispose();
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
    }
  }

  // Create a new task
  Future<void> _createTask() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _rewardPointsController.text.isEmpty) {
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

      // Create task object
      Task newTask = Task(
        title: _titleController.text,
        description: _descriptionController.text,
        requesterId: user.uid,
        requesterName: userName,
        location: _locationController.text,
        rewardPoints: int.parse(_rewardPointsController.text),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task marked as in transit'),
          backgroundColor: Colors.blue,
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

  // Complete a task
  Future<void> _completeTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.completeTask(widget.task!.id!);

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
          ),
          const SizedBox(height: 16),

          // Location field
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 16),

          // Reward points field
          TextField(
            controller: _rewardPointsController,
            decoration: const InputDecoration(
              labelText: 'Reward Points',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.stars),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Category dropdown
          DropdownButtonFormField<String>(
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
              setState(() {
                _selectedCategory = newValue!;
              });
            },
          ),
          const SizedBox(height: 16),

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
          const SizedBox(height: 32),

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_buildStatusBadge(task.status)],
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
              Text(DateFormat('dd/MM/yyyy').format(task.deadline)),
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

          // Action buttons
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

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'open':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'assigned':
        color = Colors.orange;
        icon = Icons.person;
        break;
      case 'in_transit':
        color = Colors.teal;
        icon = Icons.directions_run;
        break;
      case 'completed':
        color = Colors.blue;
        icon = Icons.done_all;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
