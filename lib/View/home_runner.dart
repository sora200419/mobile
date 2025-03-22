// lib\View\home_runner.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobiletesting/View/profile.dart';
import 'package:mobiletesting/features/task/services/task_service.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:mobiletesting/features/task/model/task_model.dart';

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
            TaskListWidget(taskStream: TaskService().getTasksByStatus("awaiting")),
            TaskListWidget(taskStream: TaskService().getTasksByStatus("inTransit")),
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

// Todo: 改card变好看

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

        List<Task> tasks =
            snapshot.data!.where((task) => task.status == "open").toList();

        if (tasks.isEmpty) {
          return Center(child: Text("No available task"));
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            Task task = tasks[index];
            return Card(
              margin: EdgeInsets.all(10),
              child: ListTile(
                title: Text(task.title),
                subtitle: Text(task.description),
                trailing: Text("Points: ${task.rewardPoints}"),
                onTap: () {
                  // Todo: navigate to detail
                },
              ),
            );
          },
        );
      },
    );
  }
}
