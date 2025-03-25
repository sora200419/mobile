// lib\View\home_runner.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/View/profile.dart';
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
            TaskListWidget(taskStream: TaskService().getTasksByStatus("open")),
            TaskListWidget(
              taskStream: TaskService().getTasksByStatus("assigned"),
            ),
            TaskListWidget(
              taskStream: TaskService().getTasksByStatus("in_transit"),
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

  TaskListWidget({required this.taskStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: taskStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        List<Task> tasks = snapshot.data!;

        if (tasks.isEmpty) {
          return Center(child: Text("No tasks"));
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            Task task = tasks[index];
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
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFECF0ED),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.green,
                                width: 1,
                              ), // 绿色边框
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  task.status.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
