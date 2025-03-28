import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:mobiletesting/features/gamification/services/gamification_service.dart';
import 'package:mobiletesting/features/gamification/views/achievements_screen.dart';
import 'package:mobiletesting/features/gamification/views/leaderboard_screen.dart';
import 'package:mobiletesting/features/gamification/views/rewards_screen.dart';
import 'package:mobiletesting/features/gamification/models/user_progress_model.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final GamificationService _gamificationService = GamificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser != null) {
      _gamificationService.recordUserLogin(_auth.currentUser!.uid);
      // Explicitly check for achievements on profile load
      _forceAchievementCheck();
    }
  }

  Future<void> _forceAchievementCheck() async {
    if (_auth.currentUser != null) {
      await _gamificationService.checkForAchievements(_auth.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = _auth.currentUser?.uid ?? '';

    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
          onRefresh: _forceAchievementCheck,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User level and progress
                FutureBuilder<UserProgress>(
                  future: _gamificationService.getUserProgress(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    UserProgress progress =
                        snapshot.data ??
                        UserProgress(
                          userId: userId,
                          points: 0,
                          level: 1,
                          levelName: 'Newcomer',
                          progressToNextLevel: 0.0,
                          pointsToNextLevel: 50,
                          rank: 0,
                        );

                    return _buildProfileHeader(progress);
                  },
                ),

                // User stats
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Stats',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats grid
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard(
                            icon: Icons.check_circle,
                            color: Colors.green,
                            title: 'Tasks Completed',
                            statFuture: _getCompletedTasksCount(userId),
                          ),
                          _buildStatCard(
                            icon: Icons.local_fire_department,
                            color: Colors.orange,
                            title: 'Login Streak',
                            statFuture: _getCurrentLoginStreak(userId),
                          ),
                          _buildStatCard(
                            icon: Icons.star,
                            color: Colors.amber,
                            title: 'Rating',
                            statFuture: _getAverageRating(userId),
                            isRating: true,
                          ),
                          _buildStatCard(
                            icon: Icons.emoji_events,
                            color: Colors.purple,
                            title: 'Achievements',
                            statFuture: _getAchievementsCount(userId),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Achievements section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Achievements',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const AchievementsScreen(),
                                ),
                              );
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRecentAchievements(userId),
                    ],
                  ),
                ),

                // Navigation tabs
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: _buildGamificationNavigation(context),
                ),

                // Account section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).logout(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom padding
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
  }

  // Build profile header with user level
  Widget _buildProfileHeader(UserProgress progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Level circle
              Container(
                width: 60,
                height: 60,
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
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // User level info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.levelName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rank #${progress.rank}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Points display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.points}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${progress.pointsToNextLevel} points needed for next level',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.progressToNextLevel,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getLevelColor(progress.level),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Get color based on level
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

  // Build a stat card
  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required Future<dynamic> statFuture,
    bool isRating = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<dynamic>(
              future: statFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                String value = snapshot.data?.toString() ?? '0';
                if (isRating && snapshot.hasData) {
                  value = (snapshot.data as double).toStringAsFixed(1);
                }

                return Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build Recent Achievements widget
  Widget _buildRecentAchievements(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('achievements')
              .where('userId', isEqualTo: userId)
              .orderBy('awardedAt', descending: true)
              .limit(3)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        var achievements = snapshot.data?.docs ?? [];
        if (achievements.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No achievements yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete tasks and challenges to earn achievements',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  FutureBuilder<int>(
                    future: _getCompletedTasksCount(userId),
                    builder: (context, taskSnapshot) {
                      int completedTasks = taskSnapshot.data ?? 0;
                      double progress =
                          completedTasks / 10; // 10 tasks for task_master

                      // Only show progress and text if less than or equal to 10 tasks
                      if (completedTasks <= 10) {
                        return Column(
                          children: [
                            Text(
                              'Task Master: $completedTasks/10 completed',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress > 1.0 ? 1.0 : progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (completedTasks < 10)
                              Text(
                                'Complete ${10 - completedTasks} more tasks to unlock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        );
                      }

                      // If more than 10 tasks, return an empty widget
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children:
              achievements.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                String achievementId = data['achievementId'] ?? '';
                DateTime awardedAt = (data['awardedAt'] as Timestamp).toDate();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(
                        _getIconForAchievement(achievementId),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(_getAchievementName(achievementId)),
                    subtitle: Text(
                      'Earned on ${awardedAt.day}/${awardedAt.month}/${awardedAt.year}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${_getAchievementPoints(achievementId)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  // Build gamification navigation
  Widget _buildGamificationNavigation(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(
            context,
            Icons.emoji_events,
            'Achievements',
            const AchievementsScreen(),
          ),
          _buildNavButton(
            context,
            Icons.leaderboard,
            'Leaderboard',
            const LeaderboardScreen(),
          ),
          _buildNavButton(
            context,
            Icons.card_giftcard,
            'Rewards',
            const RewardsScreen(),
          ),
        ],
      ),
    );
  }

  // Single navigation button
  Widget _buildNavButton(
    BuildContext context,
    IconData icon,
    String label,
    Widget screen,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.deepPurple),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.deepPurple),
            ),
          ],
        ),
      ),
    );
  }

  // Icon for achievements
  IconData _getIconForAchievement(String achievementId) {
    Map<String, IconData> icons = {
      'task_master': Icons.assignment_turned_in,
      'speedy_delivery': Icons.speed,
      'five_star': Icons.star,
      'trusted_partner': Icons.handshake,
      'campus_explorer': Icons.explore,
      'early_bird': Icons.alarm,
      'bookworm': Icons.menu_book,
      'tech_savvy': Icons.computer,
      'food_runner': Icons.fastfood,
      'perfect_week': Icons.calendar_today,
      'community_contributor': Icons.people,
      'loyal_user': Icons.favorite,
    };

    return icons[achievementId] ?? Icons.emoji_events;
  }

  // Achievement name
  String _getAchievementName(String achievementId) {
    Map<String, String> achievements = {
      'task_master': 'Task Master',
      'speedy_delivery': 'Speedy Delivery',
      'five_star': 'Five Star Service',
      'trusted_partner': 'Trusted Partner',
      'campus_explorer': 'Campus Explorer',
      'early_bird': 'Early Bird',
      'bookworm': 'Bookworm',
      'tech_savvy': 'Tech Savvy',
      'food_runner': 'Food Runner',
      'perfect_week': 'Perfect Week',
      'community_contributor': 'Community Contributor',
      'loyal_user': 'Loyal User',
    };

    return achievements[achievementId] ?? 'Achievement';
  }

  // Points for achievement
  int _getAchievementPoints(String achievementId) {
    Map<String, int> points = {
      'task_master': 20,
      'speedy_delivery': 25,
      'five_star': 30,
      'trusted_partner': 30,
      'campus_explorer': 25,
      'early_bird': 20,
      'bookworm': 15,
      'tech_savvy': 15,
      'food_runner': 15,
      'perfect_week': 40,
      'community_contributor': 20,
      'loyal_user': 50,
    };

    return points[achievementId] ?? 0;
  }

  // Get completed tasks count
  Future<int> _getCompletedTasksCount(String userId) async {
    try {
      QuerySnapshot completedTasksSnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('providerId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .get();

      return completedTasksSnapshot.docs.length;
    } catch (e) {
      print('Error getting completed tasks count: $e');
      return 0;
    }
  }

  // Get login streak
  Future<int> _getCurrentLoginStreak(String userId) async {
    try {
      DocumentSnapshot streakDoc =
          await FirebaseFirestore.instance
              .collection('streaks')
              .doc(userId)
              .get();

      if (!streakDoc.exists) {
        return 0;
      }

      Map<String, dynamic> streakData =
          streakDoc.data() as Map<String, dynamic>;
      return streakData['currentStreak'] ?? 0;
    } catch (e) {
      print('Error getting login streak: $e');
      return 0;
    }
  }

  // Get average rating
  Future<double> _getAverageRating(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userDoc.exists) {
        return 0.0;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      double averageRating = (userData['averageRating'] ?? 0.0).toDouble();

      return averageRating;
    } catch (e) {
      print('Error getting average rating: $e');
      return 0.0;
    }
  }

  // Get achievements count
  Future<int> _getAchievementsCount(String userId) async {
    try {
      QuerySnapshot achievementsSnapshot =
          await FirebaseFirestore.instance
              .collection('achievements')
              .where('userId', isEqualTo: userId)
              .get();

      return achievementsSnapshot.docs.length;
    } catch (e) {
      print('Error getting achievements count: $e');
      return 0;
    }
  }
}
