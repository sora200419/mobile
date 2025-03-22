// lib\features\gamefication\constants\gamification_rules.dart

class GamificationRules {
  // Points for task creation and management
  static const int POINTS_CREATE_TASK = 5;
  static const int POINTS_COMPLETE_TASK_PROVIDER = 10;
  static const int POINTS_COMPLETE_TASK_REQUESTER = 3;
  static const int POINTS_IN_TRANSIT = 3;
  static const int POINTS_GOOD_RATING = 2; // For ratings >= 4

  // Time-based bonuses
  static const int POINTS_EARLY_COMPLETION =
      5; // Completing task ahead of schedule
  static const int POINTS_QUICK_ACCEPTANCE =
      2; // Accepting task within 30 mins of posting

  // Streak bonuses
  static const int POINTS_DAILY_LOGIN = 1;
  static const int POINTS_WEEKLY_LOGIN = 5;
  static const int POINTS_MONTHLY_LOGIN = 20;

  // Task variety and volume bonuses
  static const int POINTS_FIRST_TASK_OF_DAY = 2;
  static const int POINTS_FIVE_TASKS_SAME_CATEGORY = 10;
  static const int POINTS_PERFECT_WEEK =
      15; // All accepted task completed successfully

  // Community engagement
  static const int POINT_COMMUNITY_POST = 1;
  static const int POINT_COMMUNITY_COMMENT = 1;
  static const int POINT_HELPFUL_CONTENT_VOTED = 3;

  // level thresholds
  static const Map<int, int> LEVEL_THRESHOLDS = {
    1: 0, // Newcomer
    2: 50, // Helper
    3: 150, // Campus Ally
    4: 300, // Campus Star
    5: 500, // Campus Hero
    6: 750, // Campus Legend
    7: 1200, // Campus Icon
  };

  // Level names
  static String getLevelName(int level) {
    switch (level) {
      case 1:
        return "Newcomer";
      case 2:
        return "Helper";
      case 3:
        return "Campus Ally";
      case 4:
        return "Campus Star";
      case 5:
        return "Campus Hero";
      case 6:
        return "Campus Legend";
      case 7:
        return "Campus Icon";
      default:
        return "Unknown";
    }
  }

  // Achievement definitions
  static const Map<String, String> ACHIEVEMENTS = {
    'task_master': 'Complete 10 tasks',
    'speedy_delivery': 'Complete 5 tasks ahead of schedule',
    'five_star': 'Receive 5 five-star ratings',
    'trusted_partner': 'Complete tasks for 10 different requesters',
    'campus_explorer': 'Complete tasks in 5 different campus locations',
    'early_bird': 'Accept 5 tasks within 10 minutes of posting',
    'bookworm': 'Complete 5 textbook delivery tasks',
    'tech_savvy': 'Complete 5 tech support tasks',
    'food_runner': 'Complete 5 food delivery tasks',
    'perfect_week': 'Complete all accepted tasks in a week',
    'community_contributor': 'Make 10 helpful posts or comments',
    'loyal_user': 'Login for 30 consecutive days',
  };

  // Points awarded for completing achievements
  static const Map<String, int> ACHIEVEMENT_POINTS = {
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

  // Weekly challenge bonus points
  static const int WEEKLY_CHALLENGE_COMPLETION = 25;

  // Seasonal event bonus points
  static const int SEASONAL_EVENT_PARTICIPATION = 10;
  static const int SEASONAL_EVENT_COMPLETION = 30;

  // Leaderboard rewards
  static const Map<int, int> WEEKLY_LEADERBOARD_REWARDS = {
    1: 50, // 1st place
    2: 30, // 2nd place
    3: 20, // 3rd place
    4: 15, // 4th place
    5: 10, // 5th place
  };
}
