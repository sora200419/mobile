// lib/View/runner_profile.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:mobiletesting/features/gamification/models/user_progress_model.dart';
import 'package:provider/provider.dart';
import 'package:mobiletesting/features/gamification/services/gamification_service.dart';
import 'package:mobiletesting/features/gamification/views/achievements_screen.dart';
import 'package:mobiletesting/features/gamification/views/leaderboard_screen.dart';
import 'package:mobiletesting/features/gamification/views/rewards_screen.dart';
import 'package:mobiletesting/utils/ui_utils.dart'; // Assuming UIUtils for level color
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/services/auth_provider.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final GamificationService _gamificationService = GamificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser != null) {
      _gamificationService.recordUserLogin(_auth.currentUser!.uid);
    }
  }

  Future<UserProgress?> _getUserProgress() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      return await _gamificationService.getUserProgress(userId);
    }
    return null;
  }

  Future<int> _getCompletedTasksCount(String userId) async {
    try {
      QuerySnapshot taskSnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('providerId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .get();
      return taskSnapshot.docs.length;
    } catch (e) {
      print('Error getting completed tasks count: $e');
      return 0;
    }
  }

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

      Map<String, dynamic> data = streakDoc.data() as Map<String, dynamic>;
      return data['currentStreak'] ?? 0;
    } catch (e) {
      print('Error getting current login streak: $e');
      return 0;
    }
  }

  Future<double> _getAverageRating(String userId) async {
    try {
      QuerySnapshot ratingSnapshot =
          await FirebaseFirestore.instance
              .collection('user_activities')
              .where('userId', isEqualTo: userId)
              .where('type', isEqualTo: 'rating_given')
              .get();

      if (ratingSnapshot.docs.isEmpty) return 0.0;

      double totalRating = 0;
      for (var doc in ratingSnapshot.docs) {
        totalRating += (doc.data() as Map<String, dynamic>)['rating'] ?? 0.0;
      }

      return totalRating / ratingSnapshot.docs.length;
    } catch (e) {
      print('Error getting average rating: $e');
      return 0.0;
    }
  }

  Future<int> _getAchievementsCount(String userId) async {
    return (await _gamificationService.getUserAchievements(userId)).length;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with level info
          FutureBuilder<UserProgress?>(
            future: _getUserProgress(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: Text('Failed to load profile')),
                );
              }

              UserProgress progress = snapshot.data!;

              return _buildCompactProfileHeader(progress);
            },
          ),

          // Your Stats section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Stats',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // Stats cards in grid
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
                      statFuture: _getCompletedTasksCount(
                        _auth.currentUser?.uid ?? '',
                      ),
                    ),
                    _buildStatCard(
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                      title: 'Login Streak',
                      statFuture: _getCurrentLoginStreak(
                        _auth.currentUser?.uid ?? '',
                      ),
                    ),
                    _buildStatCard(
                      icon: Icons.star,
                      color: Colors.amber,
                      title: 'Rating',
                      statFuture: _getAverageRating(
                        _auth.currentUser?.uid ?? '',
                      ),
                      isRating: true,
                    ),
                    _buildStatCard(
                      icon: Icons.emoji_events,
                      color: Colors.purple,
                      title: 'Achievements',
                      statFuture: _getAchievementsCount(
                        _auth.currentUser?.uid ?? '',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Recent achievements section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Achievements',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildRecentAchievements(_auth.currentUser?.uid ?? ''),
              ],
            ),
          ),

          // Gamification tabs
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _buildGamificationNavigation(context),
          ),

          // Account section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).logout(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.red),
                        const SizedBox(width: 10),
                        const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom padding
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Compact profile header with user level and progress
  Widget _buildCompactProfileHeader(UserProgress progress) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level circle with number
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red,
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
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.levelName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rank #${progress.rank}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Points display
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${progress.points}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.pointsToNextLevel} points needed',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '${progress.points}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.progressToNextLevel,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Build a single stat card
  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required Future<dynamic> statFuture,
    bool isRating = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          FutureBuilder<dynamic>(
            future: statFuture,
            builder: (context, snapshot) {
              String value = snapshot.data?.toString() ?? '0';
              if (isRating && snapshot.hasData) {
                value = (snapshot.data as double).toStringAsFixed(1);
              }
              return Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Recent Achievements section
  Widget _buildRecentAchievements(String userId) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              'No achievements yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Complete tasks and challenges to earn achievements',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Gamification navigation buttons
  Widget _buildGamificationNavigation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavButton(
          context,
          'Achievements',
          const AchievementsScreen(),
          Icons.emoji_events,
        ),
        _buildNavButton(
          context,
          'Leaderboard',
          const LeaderboardScreen(),
          Icons.leaderboard,
        ),
        _buildNavButton(
          context,
          'Rewards',
          const RewardsScreen(),
          Icons.card_giftcard,
        ),
        _buildNavButton(
          context,
          'Account',
          Container(),
          Icons.person,
        ),
      ],
    );
  }

  // Navigation button widget
  Widget _buildNavButton(
    BuildContext context,
    String title,
    Widget screen,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        if (screen is! Container) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
