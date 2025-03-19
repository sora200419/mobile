import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:mobiletesting/features/chat/direct_messaging_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Auth
import 'package:mobiletesting/services/auth_provider.dart';

// Task related imports
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:mobiletesting/features/task/services/task_service.dart';
import 'package:mobiletesting/features/task/services/rating_service.dart';
import 'package:mobiletesting/features/task/views/task_detail_screen.dart';
import 'package:mobiletesting/features/task/views/task_chat_screen.dart';
import 'package:mobiletesting/features/task/views/task_rating_screen.dart';

// Gamification imports
import 'package:mobiletesting/features/gamification/services/gamification_service.dart';
import 'package:mobiletesting/features/gamification/views/achievements_screen.dart';
import 'package:mobiletesting/features/gamification/views/leaderboard_screen.dart';
import 'package:mobiletesting/features/gamification/views/rewards_screen.dart';
import 'package:mobiletesting/features/gamification/views/gamification_profile_screen.dart';

import 'dart:async';

class HomeStudent extends StatefulWidget {
  const HomeStudent({Key? key}) : super(key: key);

  @override
  State<HomeStudent> createState() => _HomeStudentState();
}

class _HomeStudentState extends State<HomeStudent>
    with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final RatingService _ratingService = RatingService();
  final GamificationService _gamificationService = GamificationService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  bool _isGamificationPanelExpanded = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
    ); // Added a tab for Messages

    // Record user login for streak tracking
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _gamificationService.recordUserLogin(user.uid);
    }

    // Listen for search changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _performSearch();
      });
    });
  }

  // Method to perform search across all task types
  void _performSearch() {
    setState(() {
      _isSearching = _searchQuery.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Provider.of<AuthProvider>(context, listen: false).logout(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: "Available"),
            Tab(icon: Icon(Icons.assignment), text: "My Requests"),
            Tab(icon: Icon(Icons.handyman), text: "My Services"),
            Tab(
              icon: Icon(Icons.chat),
              text: "Messages",
            ), // New tab for messages
          ],
        ),
      ),
      body: Column(
        children: [
          // Gamification Panel (Collapsible)
          _buildGamificationPanel(),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search services, chats, users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _isSearching = false;
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableTasks(),
                _buildMyRequestedTasks(),
                _buildMyAcceptedTasks(),
                _buildMessagesTab(), // New tab for direct messaging
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // If on messages tab, create new message
          if (_tabController.index == 3) {
            _showNewMessageDialog();
          } else {
            // Otherwise create new task
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
          }
        },
        child: Icon(_tabController.index == 3 ? Icons.chat : Icons.add),
        tooltip: _tabController.index == 3 ? 'New Message' : 'Create new task',
      ),
    );
  }

  // Gamification Panel
  Widget _buildGamificationPanel() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header with toggle button
          InkWell(
            onTap: () {
              setState(() {
                _isGamificationPanelExpanded = !_isGamificationPanelExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Campus Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    _isGamificationPanelExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible content
          if (_isGamificationPanelExpanded) ...[
            const Divider(height: 1),

            // User level and progress
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: FutureBuilder<UserProgress>(
                future: _gamificationService.getUserProgress(
                  FirebaseAuth.instance.currentUser?.uid ?? '',
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading profile: ${snapshot.error}'),
                    );
                  }

                  final progress =
                      snapshot.data ??
                      UserProgress(
                        userId: '',
                        points: 0,
                        level: 1,
                        levelName: 'Newcomer',
                        progressToNextLevel: 0.0,
                        pointsToNextLevel: 50,
                        rank: 0,
                      );

                  return Column(
                    children: [
                      Row(
                        children: [
                          // Level badge
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _getLevelColor(progress.level),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${progress.level}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Level info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progress.levelName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rank #${progress.rank > 0 ? progress.rank : '---'}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),

                          // Points
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${progress.points}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progress to next level',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${progress.pointsToNextLevel} points needed',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress.progressToNextLevel,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getLevelColor(progress.level),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Gamification navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 6.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGamificationButton(
                    icon: Icons.emoji_events,
                    label: 'Achievements',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AchievementsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildGamificationButton(
                    icon: Icons.leaderboard,
                    label: 'Leaderboard',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeaderboardScreen(),
                        ),
                      );
                    },
                  ),
                  _buildGamificationButton(
                    icon: Icons.card_giftcard,
                    label: 'Rewards',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RewardsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildGamificationButton(
                    icon: Icons.person,
                    label: 'Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const GamificationProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGamificationButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Build tab for available tasks
  Widget _buildAvailableTasks() {
    if (_isSearching) {
      return _buildSearchResults();
    }

    return _buildTaskList(_taskService.getAvailableTasks());
  }

  // Build tab for my requested tasks
  Widget _buildMyRequestedTasks() {
    if (_isSearching) {
      return _buildSearchResults();
    }

    return _buildTaskList(_taskService.getMyTasks());
  }

  // Build tab for my accepted tasks (as provider)
  Widget _buildMyAcceptedTasks() {
    if (_isSearching) {
      return _buildSearchResults();
    }

    return _buildTaskList(_taskService.getMyAcceptedTasks());
  }

  // Build the messages tab
  Widget _buildMessagesTab() {
    if (_isSearching) {
      return _buildChatSearchResults();
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('chats')
              .where(
                'participants',
                arrayContains: FirebaseAuth.instance.currentUser?.uid ?? '',
              )
              .orderBy('lastMessageTime', descending: true)
              .snapshots(),
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

        final chatRooms = snapshot.data?.docs ?? [];

        if (chatRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start a conversation with another user',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _showNewMessageDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final chatData = chatRooms[index].data() as Map<String, dynamic>;
            final lastMessage =
                chatData['lastMessage'] as String? ?? 'No messages yet';
            final lastMessageTime =
                (chatData['lastMessageTime'] as Timestamp?)?.toDate() ??
                DateTime.now();
            final participants = List<String>.from(
              chatData['participants'] ?? [],
            );
            final otherUserId = participants.firstWhere(
              (id) => id != FirebaseAuth.instance.currentUser?.uid,
              orElse: () => 'Unknown User',
            );
            final taskId = chatData['taskId'] as String?;

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .get(),
              builder: (context, userSnapshot) {
                String userName = 'Unknown User';
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  userName = userData?['name'] ?? 'Unknown User';
                }

                // Get the task details if it's a task-related chat
                Widget taskInfo = const SizedBox.shrink();
                if (taskId != null) {
                  taskInfo = FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(taskId)
                            .get(),
                    builder: (context, taskSnapshot) {
                      if (taskSnapshot.hasData && taskSnapshot.data!.exists) {
                        final taskData =
                            taskSnapshot.data!.data() as Map<String, dynamic>?;
                        final taskTitle = taskData?['title'] ?? 'Unknown Task';
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Task: $taskTitle',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    title: Text(userName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        taskInfo,
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatChatTime(lastMessageTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (taskId != null) {
                        // Navigate to task chat
                        _navigateToTaskChat(taskId);
                      } else {
                        // Navigate to direct message chat
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DirectMessageScreen(
                                  otherUserId: otherUserId,
                                  otherUserName: userName,
                                ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Format chat time to show only what's needed
  String _formatChatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays > 0) {
      return DateFormat('dd/MM/yy').format(time);
    } else {
      return DateFormat('HH:mm').format(time);
    }
  }

  // Navigate to task chat
  void _navigateToTaskChat(String taskId) async {
    try {
      DocumentSnapshot taskDoc =
          await FirebaseFirestore.instance
              .collection('tasks')
              .doc(taskId)
              .get();
      if (taskDoc.exists) {
        Task task = Task.fromFirestore(taskDoc);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskChatScreen(task: task)),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task no longer exists')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Show dialog to start a new conversation
  void _showNewMessageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Message'),
          content: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Text('Error loading users');
              }

              final users = snapshot.data?.docs ?? [];
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;

              // Filter out current user
              final otherUsers =
                  users.where((doc) => doc.id != currentUserId).toList();

              if (otherUsers.isEmpty) {
                return const Text('No users available to message');
              }

              return SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: otherUsers.length,
                  itemBuilder: (context, index) {
                    final userData =
                        otherUsers[index].data() as Map<String, dynamic>;
                    final userName = userData['name'] ?? 'Unknown User';
                    final userRole = userData['role'] ?? 'Unknown Role';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      title: Text(userName),
                      subtitle: Text(userRole),
                      onTap: () {
                        Navigator.pop(context); // Close dialog

                        // Navigate to direct message screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DirectMessageScreen(
                                  otherUserId: otherUsers[index].id,
                                  otherUserName: userName,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Build search results for messages
  Widget _buildChatSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: _searchQuery)
              .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data?.docs ?? [];
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        // Filter out current user
        final filteredUsers =
            users.where((doc) => doc.id != currentUserId).toList();

        if (filteredUsers.isEmpty) {
          return const Center(
            child: Text('No users found matching your search'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userData =
                filteredUsers[index].data() as Map<String, dynamic>;
            final userName = userData['name'] ?? 'Unknown User';
            final userRole = userData['role'] ?? '';

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
                title: Text(userName),
                subtitle: Text(userRole),
                trailing: const Icon(Icons.chat),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => DirectMessageScreen(
                            otherUserId: filteredUsers[index].id,
                            otherUserName: userName,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Build search results for tasks
  Widget _buildSearchResults() {
    // Search in available tasks
    Stream<List<Task>> availableTasksStream = _taskService.searchTasks(
      _searchQuery,
    );

    // Search in my tasks
    Stream<List<Task>> myTasksStream = _taskService.getMyTasks().map(
      (tasks) =>
          tasks
              .where(
                (task) =>
                    task.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    task.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    task.category.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList(),
    );

    // Search in accepted tasks
    Stream<List<Task>> acceptedTasksStream = _taskService
        .getMyAcceptedTasks()
        .map(
          (tasks) =>
              tasks
                  .where(
                    (task) =>
                        task.title.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        task.description.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        task.category.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                  )
                  .toList(),
        );

    // Combine all streams into one
    return StreamBuilder<List<List<Task>>>(
      stream: StreamZip([
        availableTasksStream,
        myTasksStream,
        acceptedTasksStream,
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<Task> allTasks = [];
        if (snapshot.hasData) {
          for (var taskList in snapshot.data!) {
            allTasks.addAll(taskList);
          }
        }

        // Remove duplicates by task ID
        allTasks = allTasks.fold<List<Task>>([], (previous, element) {
          if (!previous.any((task) => task.id == element.id)) {
            previous.add(element);
          }
          return previous;
        });

        if (allTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No tasks found matching "$_searchQuery"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allTasks.length,
          itemBuilder: (context, index) {
            return _buildTaskCard(allTasks[index]);
          },
        );
      },
    );
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
          // Check for Firestore index error
          String errorMessage = snapshot.error.toString();
          bool isFirestoreIndexError =
              errorMessage.contains('failed-precondition') &&
              errorMessage.contains('requires an index');

          if (isFirestoreIndexError) {
            // Extract the URL from the error message if possible
            String indexUrl = '';
            RegExp urlRegExp = RegExp(
              r'https://console\.firebase\.google\.com/[^\s]+',
            );
            Match? match = urlRegExp.firstMatch(errorMessage);
            if (match != null) {
              indexUrl = match.group(0)!;
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Database Index Required',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This feature requires an additional database index to be created.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Create Required Index'),
                      onPressed: () async {
                        if (indexUrl.isNotEmpty) {
                          final Uri url = Uri.parse(indexUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not extract index URL from error message',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'After creating the index, return to this screen and refresh.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Regular error display
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
                  _tabController.index == 0
                      ? Icons.search_off
                      : _tabController.index == 1
                      ? Icons.assignment_outlined
                      : Icons.handyman_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _tabController.index == 0
                      ? 'No available tasks found'
                      : _tabController.index == 1
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
                  _tabController.index == 0
                      ? 'Check back later or try a different search'
                      : _tabController.index == 1
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
    // Get user role
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.role;

    // Choose color based on status
    Color statusColor;
    IconData statusIcon;
    switch (task.status) {
      case 'open':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'assigned':
        statusColor = Colors.orange;
        statusIcon = Icons.person;
        break;
      case 'in_transit':
        statusColor = Colors.teal;
        statusIcon = Icons.directions_run;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          task.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

              // Role-specific message
              if (task.status == 'open' &&
                  userRole == 'Student' &&
                  task.requesterId != FirebaseAuth.instance.currentUser?.uid)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Only runners can accept tasks',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // In transit status message
              if (task.status == 'in_transit' &&
                  (task.requesterId == FirebaseAuth.instance.currentUser?.uid ||
                      task.providerId ==
                          FirebaseAuth.instance.currentUser?.uid))
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_run,
                        size: 14,
                        color: Colors.teal.shade700,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Runner is on the way',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Action buttons based on status and user role
              if ((task.status == 'assigned' || task.status == 'in_transit') &&
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
                FutureBuilder<Rating?>(
                  future: _ratingService.getUserRatingForTask(task.id!),
                  builder: (context, snapshot) {
                    bool hasRated = snapshot.hasData && snapshot.data != null;
                    Rating? rating = snapshot.data;

                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          hasRated
                              ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Rated ${rating?.rating.toStringAsFixed(1)} ★',
                                      style: TextStyle(
                                        color: Colors.amber.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ElevatedButton.icon(
                                onPressed: () {
                                  // Show the rating screen for the provider
                                  String userIdToRate =
                                      task.requesterId ==
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid
                                          ? task.providerId!
                                          : task.requesterId;
                                  String userNameToRate =
                                      task.requesterId ==
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid
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
                                  ).then((_) {
                                    // Refresh state when returning from rating screen
                                    setState(() {});
                                  });
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
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get color based on user level
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

// StreamZip class to combine multiple streams
class StreamZip<T> extends Stream<List<T>> {
  final List<Stream<T>> streams;

  StreamZip(this.streams);

  @override
  StreamSubscription<List<T>> listen(
    void Function(List<T> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    List<T?> values = List<T?>.filled(streams.length, null);
    int completed = 0;
    final subscriptions = <StreamSubscription>[];

    for (var i = 0; i < streams.length; i++) {
      subscriptions.add(
        streams[i].listen(
          (value) {
            values[i] = value;
            onData?.call(values.whereType<T>().toList());
          },
          onError: onError,
          onDone: () {
            completed++;
            if (completed == streams.length) {
              onDone?.call();
            }
          },
          cancelOnError: cancelOnError,
        ),
      );
    }

    return _StreamZipSubscription(subscriptions);
  }
}

class _StreamZipSubscription<T> implements StreamSubscription<List<T>> {
  final List<StreamSubscription> subscriptions;

  _StreamZipSubscription(this.subscriptions);

  @override
  Future<void> cancel() async {
    for (var subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  @override
  void onData(void Function(List<T> p1)? handleData) {
    // Not used
  }

  @override
  void onDone(void Function()? handleDone) {
    // Not used
  }

  @override
  void onError(Function? handleError) {
    // Not used
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    for (var subscription in subscriptions) {
      subscription.pause(resumeSignal);
    }
  }

  @override
  void resume() {
    for (var subscription in subscriptions) {
      subscription.resume();
    }
  }

  @override
  bool get isPaused => subscriptions.first.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    return subscriptions.first.asFuture(futureValue as dynamic);
  }
}
