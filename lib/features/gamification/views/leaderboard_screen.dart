// lib/features/gamification/views/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campuslink/features/gamification/models/leaderboard_model.dart';
import 'package:campuslink/features/gamification/models/user_progress_model.dart';
import 'package:campuslink/features/gamification/services/gamification_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final GamificationService _gamificationService = GamificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedTimeframe = 'All Time';

  // Timeframe options
  final List<String> _timeframeOptions = [
    'All Time',
    'This Week',
    'This Month',
  ];

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          // User's rank card
          _buildUserRankCard(userId),

          // Timeframe selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Timeframe:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedTimeframe,
                    isExpanded: true,
                    items:
                        _timeframeOptions.map((String timeframe) {
                          return DropdownMenuItem<String>(
                            value: timeframe,
                            child: Text(timeframe),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTimeframe = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Leaderboard list
          Expanded(child: _buildLeaderboardList(userId)),
        ],
      ),
    );
  }

  // Build user's rank card
  Widget _buildUserRankCard(String userId) {
    return FutureBuilder<int>(
      future: _gamificationService.getUserRank(userId),
      builder: (context, rankSnapshot) {
        if (rankSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        int userRank = rankSnapshot.data ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: FutureBuilder<UserProgress>(
            future: _gamificationService.getUserProgress(userId),
            builder: (context, progressSnapshot) {
              if (progressSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              }

              UserProgress? progress = progressSnapshot.data;

              return Column(
                children: [
                  Text(
                    'Your Ranking',
                    style: TextStyle(fontSize: 16, color: Colors.blue.shade100),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Rank
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '#$userRank',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .get(),
                              builder: (context, userSnapshot) {
                                String username = 'You';
                                if (userSnapshot.hasData &&
                                    userSnapshot.data != null) {
                                  Map<String, dynamic> userData =
                                      userSnapshot.data!.data()
                                          as Map<String, dynamic>;
                                  username = userData['name'] ?? 'You';
                                }

                                return Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Level ${progress?.level ?? 1}: ${progress?.levelName ?? 'Newcomer'}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                      // Points
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
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
                              '${progress?.points ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Build leaderboard list
  Widget _buildLeaderboardList(String userId) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: _getLeaderboardData(_selectedTimeframe),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<LeaderboardEntry> leaderboard = snapshot.data ?? [];

        if (leaderboard.isEmpty) {
          return const Center(
            child: Text('No data available for the selected timeframe'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: leaderboard.length,
          itemBuilder: (context, index) {
            LeaderboardEntry entry = leaderboard[index];
            bool isCurrentUser = entry.userId == userId;

            return _buildLeaderboardEntryCard(entry, isCurrentUser, index);
          },
        );
      },
    );
  }

  // Build individual leaderboard entry card
  Widget _buildLeaderboardEntryCard(
    LeaderboardEntry entry,
    bool isCurrentUser,
    int index,
  ) {
    Color cardColor = isCurrentUser ? Colors.blue.shade50 : Colors.transparent;
    double elevation = isCurrentUser ? 2 : 0;

    // Special styling for top 3
    Color? medalColor;
    IconData? medalIcon;

    if (index == 0) {
      medalColor = Colors.amber; // Gold
      medalIcon = Icons.emoji_events;
    } else if (index == 1) {
      medalColor = Colors.grey.shade300; // Silver
      medalIcon = Icons.emoji_events;
    } else if (index == 2) {
      medalColor = Colors.brown.shade300; // Bronze
      medalIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isCurrentUser
                ? BorderSide(color: Colors.blue.shade300, width: 2)
                : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading:
            medalIcon != null
                ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: medalColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(medalIcon, color: Colors.white),
                )
                : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#${entry.rank}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
        title: Text(
          entry.username,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          'Level ${entry.level}',
          style: TextStyle(
            color: isCurrentUser ? Colors.blue.shade700 : Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.blue.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars,
                size: 16,
                color: isCurrentUser ? Colors.blue.shade800 : Colors.amber,
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.points}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.blue.shade800 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get leaderboard data based on timeframe
  Future<List<LeaderboardEntry>> _getLeaderboardData(String timeframe) async {
    try {
      DateTime? startDate;

      // Determine start date based on timeframe
      if (timeframe == 'This Week') {
        // Get the start of current week (Sunday)
        DateTime now = DateTime.now();
        startDate = now.subtract(Duration(days: now.weekday % 7));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
      } else if (timeframe == 'This Month') {
        // Get the start of current month
        DateTime now = DateTime.now();
        startDate = DateTime(now.year, now.month, 1);
      }

      if (timeframe == 'All Time') {
        // Get all-time leaderboard
        return _gamificationService.getLeaderboard(limit: 25);
      } else if (startDate != null) {
        // Get timeframe-specific leaderboard from user activities
        QuerySnapshot activitiesSnapshot =
            await FirebaseFirestore.instance
                .collection('user_activities')
                .where('timestamp', isGreaterThanOrEqualTo: startDate)
                .where('type', isEqualTo: 'points_earned')
                .get();

        // Aggregate points by user
        Map<String, int> userPoints = {};

        for (var doc in activitiesSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String userId = data['userId'] ?? '';
          int points = data['points'] ?? 0;

          if (userId.isNotEmpty) {
            userPoints[userId] = (userPoints[userId] ?? 0) + points;
          }
        }

        // Convert to leaderboard entries
        List<LeaderboardEntry> leaderboard = [];
        int rank = 1;

        // Sort users by points
        var sortedUsers =
            userPoints.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        // Get user details and create leaderboard entries
        for (var entry in sortedUsers) {
          String userId = entry.key;
          int points = entry.value;

          DocumentSnapshot userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;

            leaderboard.add(
              LeaderboardEntry(
                userId: userId,
                rank: rank,
                username: userData['name'] ?? 'Unknown',
                points: points,
                level: userData['level'] ?? 1,
              ),
            );

            rank++;

            // Limit to top 25
            if (leaderboard.length >= 25) break;
          }
        }

        return leaderboard;
      }

      return [];
    } catch (e) {
      print('Error getting leaderboard data: $e');
      return [];
    }
  }
}
