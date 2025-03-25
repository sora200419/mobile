// lib/View/home_student.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:mobiletesting/features/gamification/models/user_progress_model.dart';
import 'package:mobiletesting/features/marketplace/views/add_product_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:mobiletesting/features/task/views/task_detail_screen.dart';
import 'package:mobiletesting/features/gamification/services/gamification_service.dart';
import 'package:mobiletesting/features/community/views/create_post_screen.dart';

// Import the tab widgets
import 'package:mobiletesting/tabs/tasks_tab.dart';
import 'package:mobiletesting/tabs/marketplace_tab.dart';
import 'package:mobiletesting/tabs/community_tab.dart';
import 'package:mobiletesting/tabs/messages_tab.dart';
import 'package:mobiletesting/tabs/profile_tab.dart';

class HomeStudent extends StatefulWidget {
  const HomeStudent({Key? key}) : super(key: key);

  @override
  State<HomeStudent> createState() => _HomeStudentState();
}

class _HomeStudentState extends State<HomeStudent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GamificationService _gamificationService = GamificationService();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Record user login when opening the app
    if (_auth.currentUser != null) {
      _gamificationService.recordUserLogin(_auth.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String username = authProvider.username ?? "Student";

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App header with greeting and profile photo
            _buildHeader(username),

            // Main content area
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: const [
                  // Tasks Tab
                  TasksTab(),

                  // Marketplace Tab
                  MarketplaceTab(),

                  // Community Tab
                  CommunityTab(),

                  // Messages Tab
                  MessagesTab(),

                  // Profile Tab
                  ProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton:
          _shouldShowFAB() ? _buildFloatingActionButton() : null,
    );
  }

  // Custom app header with greeting and profile
  Widget _buildHeader(String username) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi $username,",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "let's start exploring.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          FutureBuilder<UserProgress>(
            future: _gamificationService.getUserProgress(
              _auth.currentUser?.uid ?? '',
            ),
            builder: (context, snapshot) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = 4; // Switch to profile tab
                  });
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: _getLevelColor(snapshot.data?.level ?? 1),
                  child: Text(
                    "${snapshot.data?.level ?? 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Floating action button for creating new content
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // Different actions based on current tab
        switch (_currentIndex) {
          case 0: // Tasks tab
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TaskDetailScreen(isCreating: true, task: null),
              ),
            ).then((_) => setState(() {}));
            break;
          case 1: // Marketplace tab
            // Create new marketplace listing
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddProductScreen()),
            );
            break;
          case 2: // Community tab
            // UPDATED: Create new community post
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePostScreen()),
            ).then((_) => setState(() {}));
            break;
        }
      },
      backgroundColor: Colors.deepPurple,
      child: const Icon(Icons.add),
    );
  }

  // Determine if FAB should be shown based on current tab
  bool _shouldShowFAB() {
    // Only show FAB on Tasks, Marketplace, and Community tabs
    return _currentIndex <= 2;
  }

  // Get level color
  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.green;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.orange;
      case 6:
        return Colors.red;
      case 7:
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }
}
