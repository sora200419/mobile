// lib/View/home_student.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:mobiletesting/features/task/services/task_service.dart';
import 'package:mobiletesting/features/task/views/task_detail_screen.dart';
import 'package:mobiletesting/features/task/views/task_chat_screen.dart';
import 'package:mobiletesting/features/task/views/task_rating_screen.dart';
import 'package:intl/intl.dart';

class HomeStudent extends StatefulWidget {
  const HomeStudent({Key? key}) : super(key: key);

  @override
  State<HomeStudent> createState() => _HomeStudentState();
}

class _HomeStudentState extends State<HomeStudent> {
  final TaskService _taskService = TaskService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Campus Services"),
          actions: [
            // Points display in app bar
            FutureBuilder<int>(
              future: _taskService.getUserPoints(),
              builder: (context, snapshot) {
                int points = snapshot.data ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '$points',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Logout button
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout(context);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), text: "Available"),
              Tab(icon: Icon(Icons.assignment), text: "My Requests"),
              Tab(icon: Icon(Icons.handyman), text: "My Services"),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Points display
            FutureBuilder<int>(
              future: _taskService.getUserPoints(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                int points = snapshot.data ?? 0;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'My Points: $points',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  _buildAvailableTasks(),
                  _buildMyRequestedTasks(),
                  _buildMyAcceptedTasks(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TaskDetailScreen(isCreating: true, task: null),
              ),
            ).then((_) {
              // Refresh data when returning from create screen
              setState(() {});
            });
          },
          child: const Icon(Icons.add),
          tooltip: 'Create new task',
        ),
      ),
    );
  }

  // Build tab for available tasks
  Widget _buildAvailableTasks() {
    return _searchQuery.isEmpty
        ? _buildTaskList(_taskService.getAvailableTasks())
        : _buildTaskList(_taskService.searchTasks(_searchQuery));
  }

  // Build tab for my requested tasks
  Widget _buildMyRequestedTasks() {
    return _buildTaskList(_taskService.getMyTasks());
  }

  // Build tab for my accepted tasks (as provider)
  Widget _buildMyAcceptedTasks() {
    return _buildTaskList(_taskService.getMyAcceptedTasks());
  }

  // Build list of tasks from stream
  Widget _buildTaskList(Stream<List<Task>> tasksStream) {
    return StreamBuilder<List<Task>>(
      stream: tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        List<Task> tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  DefaultTabController.of(context).index == 0
                      ? Icons.search_off
                      : DefaultTabController.of(context).index == 1
                      ? Icons.assignment_outlined
                      : Icons.handyman_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  DefaultTabController.of(context).index == 0
                      ? 'No available tasks found'
                      : DefaultTabController.of(context).index == 1
                      ? 'You haven\'t created any tasks yet'
                      : 'You haven\'t accepted any tasks yet',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DefaultTabController.of(context).index == 0
                      ? 'Check back later or try a different search'
                      : DefaultTabController.of(context).index == 1
                      ? 'Tap the + button to create a new task'
                      : 'Browse available tasks to offer your services',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            Task task = tasks[index];
            return _buildTaskCard(task);
          },
        );
      },
    );
  }

  // Build card for individual task
  Widget _buildTaskCard(Task task) {
    // Choose color based on status
    Color statusColor;
    switch (task.status) {
      case 'open':
        statusColor = Colors.green;
        break;
      case 'assigned':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => TaskDetailScreen(isCreating: false, task: task),
            ),
          ).then((_) {
            // Refresh data when returning from detail screen
            setState(() {});
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      task.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.stars, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${task.rewardPoints} points',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'By ${task.requesterName}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(task.deadline),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              // Action buttons based on status and user role
              if (task.status == 'assigned' &&
                  (task.requesterId == FirebaseAuth.instance.currentUser?.uid ||
                      task.providerId ==
                          FirebaseAuth.instance.currentUser?.uid))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskChatScreen(task: task),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              if (task.status == 'completed' &&
                  (task.requesterId == FirebaseAuth.instance.currentUser?.uid ||
                      task.providerId ==
                          FirebaseAuth.instance.currentUser?.uid) &&
                  task.providerId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // Show the rating screen for the provider
                          String userIdToRate =
                              task.requesterId ==
                                      FirebaseAuth.instance.currentUser?.uid
                                  ? task.providerId!
                                  : task.requesterId;
                          String userNameToRate =
                              task.requesterId ==
                                      FirebaseAuth.instance.currentUser?.uid
                                  ? task.providerName!
                                  : task.requesterName;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => TaskRatingScreen(
                                    task: task,
                                    userIdToRate: userIdToRate,
                                    userNameToRate: userNameToRate,
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.star, size: 16),
                        label: const Text('Rate'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
