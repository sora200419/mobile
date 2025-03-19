// lib/features/gamification/views/gamification_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/features/gamification/constants/gamification_rules.dart';
import 'package:mobiletesting/features/gamification/services/gamification_service.dart';
import 'package:mobiletesting/features/gamification/views/achievements_screen.dart';
import 'package:mobiletesting/features/gamification/views/leaderboard_screen.dart';
import 'package:mobiletesting/features/gamification/views/rewards_screen.dart';

class GamificationProfileScreen extends StatefulWidget {
  const GamificationProfileScreen({Key? key}) : super(key: key);

  @override
  State<GamificationProfileScreen> createState() =>
      _GamificationProfileScreenState();
}

class _GamificationProfileScreenState extends State<GamificationProfileScreen> {
  final GamificationService _gamificationService = GamificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Record user login when visiting profile
    if (_auth.currentUser != null) {
      _gamificationService.recordUserLogin(_auth.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My Campus Profile')),
      body:
          userId.isEmpty
              ? const Center(child: Text('Please log in to view your profile'))
              : FutureBuilder<UserProgress>(
                future: _gamificationService.getUserProgress(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  UserProgress progress = snapshot.data!;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Level and points overview card
                          _buildLevelCard(progress),

                          const SizedBox(height: 24),

                          // Quick stats
                          _buildStatsSection(userId),

                          const SizedBox(height: 24),

                          // Recent achievements
                          _buildRecentAchievementsSection(userId),

                          const SizedBox(height: 24),

                          // Navigation cards
                          _buildNavigationCards(context),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  // Build level card with progress
  Widget _buildLevelCard(UserProgress progress) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Level badge and title
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.levelName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rank #${progress.rank}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
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

            const SizedBox(height: 20),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progress to next level'),
                    Text(
                      '${progress.pointsToNextLevel} points needed',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.progressToNextLevel,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getLevelColor(progress.level),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build stats section with task counts and streaks
  Widget _buildStatsSection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Stats',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle,
                color: Colors.green,
                title: 'Tasks Completed',
                statFuture: _getCompletedTasksCount(userId),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department,
                color: Colors.orange,
                title: 'Login Streak',
                statFuture: _getCurrentLoginStreak(userId),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                color: Colors.amber,
                title: 'Average Rating',
                statFuture: _getAverageRating(userId),
                isRating: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.emoji_events,
                color: Colors.purple,
                title: 'Achievements',
                statFuture: _getAchievementsCount(userId),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build a single stat card
  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required Future<String> statFuture,
    bool isRating = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: statFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                return Text(
                  snapshot.data ?? '0',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
            ),
            if (isRating)
              const Text(
                '(out of 5)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  // Build recent achievements section
  Widget _buildRecentAchievementsSection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Achievements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AchievementsScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('achievements')
                  .where('userId', isEqualTo: userId)
                  .orderBy('awardedAt', descending: true)
                  .limit(3)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error loading achievements'));
            }

            var achievements = snapshot.data?.docs ?? [];

            if (achievements.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete tasks and challenges to earn achievements',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children:
                  achievements.map((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    String achievementId = data['achievementId'] ?? '';
                    DateTime awardedAt =
                        (data['awardedAt'] as Timestamp).toDate();

                    String achievementName =
                        GamificationRules.ACHIEVEMENTS[achievementId] ??
                        'Achievement';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.emoji_events, color: Colors.white),
                        ),
                        title: Text(achievementName),
                        subtitle: Text(
                          'Earned on ${_formatDate(awardedAt)}',
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
                            '+${GamificationRules.ACHIEVEMENT_POINTS[achievementId] ?? 0}',
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
        ),
      ],
    );
  }

  // Build navigation cards for other gamification screens
  Widget _buildNavigationCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore More',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNavCard(
                context,
                icon: Icons.leaderboard,
                title: 'Leaderboard',
                subtitle: 'See how you rank',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LeaderboardScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavCard(
                context,
                icon: Icons.card_giftcard,
                title: 'Rewards',
                subtitle: 'Redeem your points',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RewardsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build a navigation card
  Widget _buildNavCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods to fetch stats

  // Get completed tasks count
  Future<String> _getCompletedTasksCount(String userId) async {
    try {
      QuerySnapshot completedTasksSnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('providerId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .get();

      return completedTasksSnapshot.docs.length.toString();
    } catch (e) {
      print('Error getting completed tasks count: $e');
      return '0';
    }
  }

  // Get current login streak
  Future<String> _getCurrentLoginStreak(String userId) async {
    try {
      DocumentSnapshot streakDoc =
          await FirebaseFirestore.instance
              .collection('streaks')
              .doc(userId)
              .get();

      if (!streakDoc.exists) {
        return '0';
      }

      Map<String, dynamic> streakData =
          streakDoc.data() as Map<String, dynamic>;
      return (streakData['currentStreak'] ?? 0).toString();
    } catch (e) {
      print('Error getting login streak: $e');
      return '0';
    }
  }

  // Get average rating
  Future<String> _getAverageRating(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userDoc.exists) {
        return '0.0';
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      double averageRating = (userData['averageRating'] ?? 0.0).toDouble();

      return averageRating.toStringAsFixed(1);
    } catch (e) {
      print('Error getting average rating: $e');
      return '0.0';
    }
  }

  // Get achievements count
  Future<String> _getAchievementsCount(String userId) async {
    try {
      QuerySnapshot achievementsSnapshot =
          await FirebaseFirestore.instance
              .collection('achievements')
              .where('userId', isEqualTo: userId)
              .get();

      return achievementsSnapshot.docs.length.toString();
    } catch (e) {
      print('Error getting achievements count: $e');
      return '0';
    }
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper method to get level color
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
