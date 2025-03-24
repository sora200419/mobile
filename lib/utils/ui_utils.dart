import 'package:flutter/material.dart';

class UIUtils {
  // Get color based on level
  static Color getLevelColor(int level) {
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

  // Get icon for achievement
  static IconData getIconForAchievement(String achievementId) {
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

  // Build status badge for tasks
  static Widget buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'open':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'assigned':
        color = Colors.orange;
        icon = Icons.person;
        break;
      case 'in_transit':
        color = Colors.teal;
        icon = Icons.directions_run;
        break;
      case 'completed':
        color = Colors.blue;
        icon = Icons.done_all;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Get color for reward type
  static Color getColorForRewardType(String rewardType) {
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
