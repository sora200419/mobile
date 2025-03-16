// lib\View\home_runner.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobiletesting/View/profile.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:provider/provider.dart';

class HomeRunner extends StatefulWidget {
  @override
  _HomeRunnerState createState() => _HomeRunnerState();
}

class _HomeRunnerState extends State<HomeRunner> {

  int _selectedIndex = 0;

  void _onItemTapped(int index){
    if(index == 1){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen()),
      );
    }
    // todo: add support.dart and setting.dart
  }

  @override
  Widget  build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tab
      child: Scaffold(
        appBar: AppBar(
          title: Text("Runner"),
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
              // Tab(icon: Icon(Icons.check_circle), text: "Completed"),
            ],
          ),
        ),
        body: TabBarView(children: [CompletedTab()]),
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

class CompletedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Completed Orders"));
  }
}