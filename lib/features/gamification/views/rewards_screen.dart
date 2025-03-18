// lib/features/gamification/views/rewards_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobiletesting/features/gamification/models/reward_model.dart';
import 'package:mobiletesting/features/gamification/services/gamification_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GamificationService _gamificationService = GamificationService();

  late TabController _tabController;
  String _selectedCategory = 'All';

  // Reward categories
  final List<String> _categories = [
    'All',
    'Campus',
    'Discount',
    'Priority',
    'Premium',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Store'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Available Rewards'), Tab(text: 'My Rewards')],
        ),
      ),
      body:
          userId.isEmpty
              ? const Center(child: Text('Please log in to view rewards'))
              : Column(
                children: [
                  // Points display
                  _buildPointsDisplay(userId),

                  // Category filter
                  if (_tabController.index == 0) _buildCategoryFilter(),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAvailableRewards(userId),
                        _buildMyRewards(userId),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  // Build points display
  Widget _buildPointsDisplay(String userId) {
    return FutureBuilder<UserProgress>(
      future: _gamificationService.getUserProgress(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        UserProgress? progress = snapshot.data;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Your Balance:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${progress?.points ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build category filter
  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children:
            _categories.map((category) {
              bool isSelected = _selectedCategory == category;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    }
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue.shade900 : Colors.black,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // Build available rewards tab
  Widget _buildAvailableRewards(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('rewards')
              .where('isAvailable', isEqualTo: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var rewards = snapshot.data?.docs ?? [];

        // Filter by category if needed
        if (_selectedCategory != 'All') {
          rewards =
              rewards.where((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return data['rewardType'] == _selectedCategory.toLowerCase();
              }).toList();
        }

        if (rewards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No rewards available for $_selectedCategory',
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

        return FutureBuilder<UserProgress>(
          future: _gamificationService.getUserProgress(userId),
          builder: (context, progressSnapshot) {
            int userPoints = progressSnapshot.data?.points ?? 0;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                DocumentSnapshot doc = rewards[index];
                Reward reward = Reward.fromFirestore(doc);
                bool canAfford = userPoints >= reward.pointsCost;

                return _buildRewardCard(
                  reward: reward,
                  canAfford: canAfford,
                  userPoints: userPoints,
                );
              },
            );
          },
        );
      },
    );
  }

  // Build my rewards tab
  Widget _buildMyRewards(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('user_rewards')
              .where('userId', isEqualTo: userId)
              .orderBy('redeemedAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var userRewards = snapshot.data?.docs ?? [];

        if (userRewards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'You haven\'t redeemed any rewards yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Earn points and get amazing rewards!',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  child: const Text('Browse Available Rewards'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: userRewards.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = userRewards[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            String rewardId = data['rewardId'] ?? '';
            DateTime redeemedAt = (data['redeemedAt'] as Timestamp).toDate();
            String rewardCode = data['rewardCode'] ?? '';
            bool isUsed = data['isUsed'] ?? false;

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('rewards').doc(rewardId).get(),
              builder: (context, rewardSnapshot) {
                if (!rewardSnapshot.hasData) {
                  return const Card(
                    child: ListTile(title: Text('Loading reward details...')),
                  );
                }

                Reward? reward;
                if (rewardSnapshot.data!.exists) {
                  reward = Reward.fromFirestore(rewardSnapshot.data!);
                }

                return _buildRedeemedRewardCard(
                  reward: reward,
                  redeemedAt: redeemedAt,
                  rewardCode: rewardCode,
                  isUsed: isUsed,
                );
              },
            );
          },
        );
      },
    );
  }

  // Build reward card
  Widget _buildRewardCard({
    required Reward reward,
    required bool canAfford,
    required int userPoints,
  }) {
    Color cardColor = canAfford ? Colors.white : Colors.grey.shade100;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              reward.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: canAfford ? Colors.black : Colors.grey.shade700,
              ),
            ),
            subtitle: Text(
              _capitalizeFirstLetter(reward.rewardType),
              style: TextStyle(
                color: _getColorForRewardType(reward.rewardType),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: canAfford ? Colors.blue.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars,
                    size: 16,
                    color: canAfford ? Colors.amber : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${reward.pointsCost}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canAfford ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.description,
                  style: TextStyle(
                    color: canAfford ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Points needed if can't afford
                    if (!canAfford)
                      Text(
                        'Need ${reward.pointsCost - userPoints} more points',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),

                    // Redeem button
                    ElevatedButton(
                      onPressed:
                          canAfford
                              ? () => _showRedeemConfirmationDialog(reward)
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        canAfford ? 'Redeem Now' : 'Not Enough Points',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build redeemed reward card
  Widget _buildRedeemedRewardCard({
    required Reward? reward,
    required DateTime redeemedAt,
    required String rewardCode,
    required bool isUsed,
  }) {
    if (reward == null) {
      return const Card(
        margin: EdgeInsets.only(bottom: 16),
        child: ListTile(
          title: Text('Reward no longer available'),
          subtitle: Text('This reward has been removed from the system'),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isUsed ? Colors.grey.shade100 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text(
                  reward.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isUsed ? Colors.grey.shade700 : Colors.black,
                    decoration: isUsed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isUsed)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'USED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              'Redeemed on ${_formatDate(redeemedAt)}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isUsed ? Colors.grey.shade200 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars,
                    size: 16,
                    color: isUsed ? Colors.grey : Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${reward.pointsCost}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUsed ? Colors.grey : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.description,
                  style: TextStyle(
                    color: isUsed ? Colors.grey.shade600 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Redemption code
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUsed ? Colors.grey.shade200 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isUsed ? Colors.grey.shade300 : Colors.amber.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Redemption Code:',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isUsed
                                  ? Colors.grey.shade700
                                  : Colors.amber.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rewardCode,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color:
                                  isUsed
                                      ? Colors.grey.shade700
                                      : Colors.amber.shade900,
                            ),
                          ),
                          if (!isUsed)
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              color: Colors.amber.shade900,
                              onPressed: () {
                                // Copy code to clipboard
                                _copyToClipboard(rewardCode);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Mark as used button
                if (!isUsed)
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _markRewardAsUsed(reward.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Mark as Used'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show redeem confirmation dialog
  void _showRedeemConfirmationDialog(Reward reward) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Redemption'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to redeem "${reward.title}"?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will deduct ${reward.pointsCost} points from your balance.',
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _redeemReward(reward);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Redeem a reward
  Future<void> _redeemReward(Reward reward) async {
    try {
      String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      // Get user points
      UserProgress progress = await _gamificationService.getUserProgress(
        userId,
      );

      // Check if user has enough points
      if (progress.points < reward.pointsCost) {
        _showErrorSnackBar('Not enough points to redeem this reward');
        return;
      }

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      // Deduct points from user
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'points': FieldValue.increment(-reward.pointsCost),
      });

      // Generate a unique code if needed
      String rewardCode =
          reward.rewardCode.isNotEmpty
              ? reward.rewardCode
              : _generateRewardCode();

      // Create user reward record
      DocumentReference userRewardRef =
          _firestore.collection('user_rewards').doc();
      batch.set(userRewardRef, {
        'userId': userId,
        'rewardId': reward.id,
        'redeemedAt': DateTime.now(),
        'rewardCode': rewardCode,
        'isUsed': false,
        'pointsCost': reward.pointsCost,
      });

      // Record activity
      DocumentReference activityRef =
          _firestore.collection('user_activities').doc();
      batch.set(activityRef, {
        'userId': userId,
        'type': 'redeem_reward',
        'description': 'Redeemed ${reward.title}',
        'points': -reward.pointsCost,
        'timestamp': DateTime.now(),
      });

      // Commit the batch
      await batch.commit();

      // Show success message
      _showSuccessSnackBar('Successfully redeemed ${reward.title}');

      // Switch to My Rewards tab
      _tabController.animateTo(1);
    } catch (e) {
      print('Error redeeming reward: $e');
      _showErrorSnackBar('Failed to redeem reward. Please try again.');
    }
  }

  // Mark a reward as used
  Future<void> _markRewardAsUsed(String rewardId) async {
    try {
      String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      // Find the user reward
      QuerySnapshot userRewardSnapshot =
          await _firestore
              .collection('user_rewards')
              .where('userId', isEqualTo: userId)
              .where('rewardId', isEqualTo: rewardId)
              .where('isUsed', isEqualTo: false)
              .get();

      if (userRewardSnapshot.docs.isEmpty) {
        _showErrorSnackBar('Could not find the reward to mark as used');
        return;
      }

      // Update the reward
      DocumentReference userRewardRef = userRewardSnapshot.docs.first.reference;
      await userRewardRef.update({'isUsed': true, 'usedAt': DateTime.now()});

      _showSuccessSnackBar('Reward marked as used');
    } catch (e) {
      print('Error marking reward as used: $e');
      _showErrorSnackBar('Failed to mark reward as used. Please try again.');
    }
  }

  // Helper methods

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Copy text to clipboard
  void _copyToClipboard(String text) {
    //Clipboard.setData(ClipboardData(text: text)); --only a mock
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Code copied to clipboard')));
  }

  // Generate a random reward code
  String _generateRewardCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      8,
      (index) => chars[DateTime.now().millisecondsSinceEpoch % chars.length],
    ).join();
  }

  // Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  // Get color for reward type
  Color _getColorForRewardType(String rewardType) {
    switch (rewardType.toLowerCase()) {
      case 'discount':
        return Colors.green.shade700;
      case 'priority':
        return Colors.orange.shade700;
      case 'premium':
        return Colors.purple.shade700;
      case 'campus':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
