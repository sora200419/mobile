// lib/features/gamification/views/achievements_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campuslink/features/gamification/constants/gamification_rules.dart';
import 'package:campuslink/features/gamification/services/gamification_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GamificationService _gamificationService = GamificationService();
  String _selectedFilter = 'All';

  // Filter options
  final List<String> _filterOptions = [
    'All',
    'Earned',
    'Locked',
    'Task',
    'Rating',
    'Community',
    'Streak',
  ];

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body:
          userId.isEmpty
              ? const Center(child: Text('Please log in to view achievements'))
              : Column(
                children: [
                  // Achievement stats
                  _buildAchievementStats(userId),

                  // Filter chips
                  _buildFilterChips(),

                  // Achievement list
                  Expanded(child: _buildAchievementList(userId)),
                ],
              ),
    );
  }

  // Build achievement statistics section
  Widget _buildAchievementStats(String userId) {
    return FutureBuilder<Map<String, int>>(
      future: _getAchievementStats(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        Map<String, int> stats =
            snapshot.data ??
            {'earned': 0, 'total': GamificationRules.ACHIEVEMENTS.length};

        int earned = stats['earned'] ?? 0;
        int total = stats['total'] ?? GamificationRules.ACHIEVEMENTS.length;
        double percentage = earned / total * 100;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    '$earned / $total Achievements Earned',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: earned / total,
                      minHeight: 16,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.amber,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Build filter chips
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _filterOptions.map((filter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Colors.amber.shade100,
                    checkmarkColor: Colors.amber.shade900,
                    labelStyle: TextStyle(
                      color:
                          _selectedFilter == filter
                              ? Colors.amber.shade900
                              : Colors.black,
                      fontWeight:
                          _selectedFilter == filter
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  // Build achievement list
  Widget _buildAchievementList(String userId) {
    return FutureBuilder<List<String>>(
      future: _gamificationService.getUserAchievements(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<String> earnedAchievements = snapshot.data ?? [];

        // Get all achievements from GamificationRules.ACHIEVEMENTS
        List<MapEntry<String, String>> allAchievements =
            GamificationRules.ACHIEVEMENTS.entries.toList();

        // Apply filter
        if (_selectedFilter != 'All') {
          if (_selectedFilter == 'Earned') {
            allAchievements =
                allAchievements
                    .where((entry) => earnedAchievements.contains(entry.key))
                    .toList();
          } else if (_selectedFilter == 'Locked') {
            allAchievements =
                allAchievements
                    .where((entry) => !earnedAchievements.contains(entry.key))
                    .toList();
          } else {
            // Filter by category
            String category = _selectedFilter.toLowerCase();
            allAchievements =
                allAchievements
                    .where(
                      (entry) =>
                          _getCategoryForAchievement(entry.key) == category,
                    )
                    .toList();
          }
        }

        // Sort achievements (earned first, then alphabetically)
        allAchievements.sort((a, b) {
          bool aEarned = earnedAchievements.contains(a.key);
          bool bEarned = earnedAchievements.contains(b.key);

          if (aEarned && !bEarned) return -1;
          if (!aEarned && bEarned) return 1;

          return a.value.compareTo(b.value);
        });

        if (allAchievements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No achievements found for ${_selectedFilter}',
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
          itemCount: allAchievements.length,
          itemBuilder: (context, index) {
            String achievementId = allAchievements[index].key;
            String achievementDesc = allAchievements[index].value;
            bool isEarned = earnedAchievements.contains(achievementId);

            return _buildAchievementCard(
              achievementId: achievementId,
              description: achievementDesc,
              isEarned: isEarned,
              earnedDate:
                  isEarned
                      ? _getAchievementEarnedDate(userId, achievementId)
                      : null,
            );
          },
        );
      },
    );
  }

  // Build individual achievement card
  Widget _buildAchievementCard({
    required String achievementId,
    required String description,
    required bool isEarned,
    Future<DateTime?>? earnedDate,
  }) {
    Color cardColor = isEarned ? Colors.amber.shade50 : Colors.grey.shade100;
    Color borderColor = isEarned ? Colors.amber : Colors.grey.shade300;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isEarned ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Achievement icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isEarned ? Colors.amber : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForAchievement(achievementId),
                color: isEarned ? Colors.white : Colors.grey.shade500,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitleForAchievement(achievementId),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isEarned ? Colors.black : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isEarned ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Points reward
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isEarned
                                  ? Colors.amber.withOpacity(0.2)
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.stars,
                              size: 14,
                              color:
                                  isEarned
                                      ? Colors.amber.shade700
                                      : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${GamificationRules.ACHIEVEMENT_POINTS[achievementId] ?? 0}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isEarned
                                        ? Colors.amber.shade700
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Earned date if available
                      if (isEarned && earnedDate != null)
                        FutureBuilder<DateTime?>(
                          future: earnedDate,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data == null) {
                              return const SizedBox.shrink();
                            }

                            return Text(
                              'Earned ${_formatDate(snapshot.data!)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods

  // Get achievement statistics
  Future<Map<String, int>> _getAchievementStats(String userId) async {
    try {
      QuerySnapshot achievementsSnapshot =
          await FirebaseFirestore.instance
              .collection('achievements')
              .where('userId', isEqualTo: userId)
              .get();

      int earned = achievementsSnapshot.docs.length;
      int total = GamificationRules.ACHIEVEMENTS.length;

      return {'earned': earned, 'total': total};
    } catch (e) {
      print('Error getting achievement stats: $e');
      return {'earned': 0, 'total': GamificationRules.ACHIEVEMENTS.length};
    }
  }

  // Get achievement earned date
  Future<DateTime?> _getAchievementEarnedDate(
    String userId,
    String achievementId,
  ) async {
    try {
      QuerySnapshot achievementSnapshot =
          await FirebaseFirestore.instance
              .collection('achievements')
              .where('userId', isEqualTo: userId)
              .where('achievementId', isEqualTo: achievementId)
              .get();

      if (achievementSnapshot.docs.isEmpty) {
        return null;
      }

      Map<String, dynamic> data =
          achievementSnapshot.docs.first.data() as Map<String, dynamic>;
      return (data['awardedAt'] as Timestamp).toDate();
    } catch (e) {
      print('Error getting achievement earned date: $e');
      return null;
    }
  }

  // Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get category for achievement
  String _getCategoryForAchievement(String achievementId) {
    // Map achievement IDs to categories
    Map<String, String> categories = {
      'task_master': 'task',
      'speedy_delivery': 'task',
      'five_star': 'rating',
      'trusted_partner': 'task',
      'campus_explorer': 'task',
      'early_bird': 'task',
      'bookworm': 'task',
      'tech_savvy': 'task',
      'food_runner': 'task',
      'perfect_week': 'task',
      'community_contributor': 'community',
      'loyal_user': 'streak',
    };

    return categories[achievementId] ?? 'other';
  }

  // Get icon for achievement
  IconData _getIconForAchievement(String achievementId) {
    // Map achievement IDs to icons
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

  // Get title for achievement
  String _getTitleForAchievement(String achievementId) {
    // Map achievement IDs to more user-friendly titles
    Map<String, String> titles = {
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

    return titles[achievementId] ??
        achievementId
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? word[0].toUpperCase() + word.substring(1)
                      : '',
            )
            .join(' ');
  }
}
