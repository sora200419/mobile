// lib\View\home_runner.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:mobiletesting/View/profile.dart';
import 'package:mobiletesting/View/status_tag.dart';
import 'package:mobiletesting/features/task/services/task_service.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:mobiletesting/View/task_details.dart';

class HomeRunner extends StatefulWidget {
  @override
  _HomeRunnerState createState() => _HomeRunnerState();
}

class _HomeRunnerState extends State<HomeRunner> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  int _userPoints = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoadingPoints = true;

  @override
  void initState() {
    super.initState();
    _fetchUserPoints();
  }

  Future<void> _fetchUserPoints() async {
    setState(() {
      _isLoadingPoints = true;
    });
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userSnapshot.exists && userSnapshot.data() != null) {
          setState(() {
            _userPoints =
                (userSnapshot.data() as Map<String, dynamic>)['points'] ?? 0;
            _isLoadingPoints = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoadingPoints = false;
          print('Error fetching user points: $e');
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen()),
      );
    }
    // todo: add support.dart and setting.dart
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tab
      child: Scaffold(
        appBar: AppBar(
          title: Text("CampusLink"),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout(context);
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.hourglass_empty), text: "Pending"),
              Tab(icon: Icon(Icons.move_to_inbox), text: "Awaiting Pickup"),
              Tab(icon: Icon(Icons.directions_walk), text: "In Transit"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search services...',
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.orange[200]!, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.yellow,
                        ),
                        Icon(Icons.star, color: Colors.white, size: 18),
                      ],
                    ),
                    SizedBox(width: 8),
                    Text(
                      'My Points: $_userPoints',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  TaskListWidget(
                    taskStream: TaskService().getAvailableTasks(),
                    searchQuery: _searchQuery,
                  ),
                  TaskListWidget(
                    taskStream: TaskService().getTasksForRunnerByStatus(
                      "assigned",
                    ),
                    searchQuery: _searchQuery,
                  ),
                  TaskListWidget(
                    taskStream: TaskService().getTasksForRunnerByStatus(
                      "in_transit",
                    ),
                    searchQuery: _searchQuery,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

class TaskListWidget extends StatelessWidget {
  final Stream<List<Task>> taskStream;
  final String searchQuery;

  TaskListWidget({required this.taskStream, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: taskStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        List<Task> tasks = snapshot.data!;

        List<Task> filteredTasks =
            tasks.where((task) {
              final lowerCaseQuery = searchQuery.toLowerCase();
              return task.title.toLowerCase().contains(lowerCaseQuery) ||
                  task.description.toLowerCase().contains(lowerCaseQuery) ||
                  (task.category.toLowerCase().contains(lowerCaseQuery));
            }).toList();

        if (filteredTasks.isEmpty) {
          return Center(child: Text("No tasks found"));
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            Task task = filteredTasks[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailsPage(task: task),
                  ),
                );
              },
              child: Card(
                margin: EdgeInsets.all(8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          StatusTag(status: task.status),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        task.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            task.location,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Spacer(),
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            "${task.rewardPoints} points",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
