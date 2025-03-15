// lib/View/home_student.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/providers/auth_provider.dart';
import 'package:mobiletesting/view/tabs/chat_tab.dart';
import 'package:mobiletesting/view/tabs/community_tab.dart';
import 'package:mobiletesting/view/tabs/marketplace_tab.dart';
import 'package:mobiletesting/view/tabs/profile_tab.dart';
import 'package:mobiletesting/view/tabs/task_tab.dart'; // Import TaskTab
import 'package:provider/provider.dart';

class HomeStudent extends StatefulWidget {
  const HomeStudent({Key? key}) : super(key: key);

  @override
  State<HomeStudent> createState() => _HomeStudentState();
}

class _HomeStudentState extends State<HomeStudent> {
  // No initState or _fetchTasks needed here.  TaskTab will handle it.

  Future<void> _handleLogout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout(context);
  }

  @override
  Widget build(BuildContext context) {
    // No MultiProvider here.  TasksProvider is provided via the named route.
    return Consumer<AuthProvider>(
      // Keep the Consumer for AuthProvider
      builder:
          (context, authProvider, child) => DefaultTabController(
            length: 5, // Total number of tabs
            child: Scaffold(
              appBar: AppBar(
                title: Text('Student Home'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: _handleLogout,
                    tooltip: 'Logout',
                  ),
                ],
                bottom: TabBar(
                  isScrollable: true, // Important for many tabs
                  tabs: [
                    Tab(icon: Icon(Icons.task_alt), text: "My Tasks"),
                    Tab(icon: Icon(Icons.group), text: "Community"),
                    Tab(icon: Icon(Icons.person), text: "Profile"),
                    Tab(icon: Icon(Icons.store), text: "Marketplace"),
                    Tab(icon: Icon(Icons.chat), text: "Chat"),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  TaskTab(), // Use the TaskTab widget!
                  CommunityTab(),
                  ProfileTab(),
                  MarketplaceTab(),
                  ChatTab(),
                ],
              ),
            ),
          ),
    );
  }
}
