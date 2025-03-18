import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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
import 'package:mobiletesting/features/gamification/constants/gamification_rules.dart';
import 'package:mobiletesting/features/gamification/views/achievements_screen.dart';
import 'package:mobiletesting/features/gamification/views/leaderboard_screen.dart';
import 'package:mobiletesting/features/gamification/views/rewards_screen.dart';
import 'package:mobiletesting/features/gamification/views/gamification_profile_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Record user login for streak tracking
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _gamificationService.recordUserLogin(user.uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Gamification Panel (Collapsible)
            _buildGamificationPanel(),

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
                FutureBuilder<bool>(
                  future: _ratingService.hasUserRatedTask(task.id!),
                  builder: (context, snapshot) {
                    bool hasRated = snapshot.data ?? false;

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
                                      'Already Rated',
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
