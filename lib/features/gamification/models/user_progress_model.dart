class UserProgress {
  final String userId;
  final int points;
  final int level;
  final String levelName;
  final double progressToNextLevel;
  final int pointsToNextLevel;
  final int rank;

  UserProgress({
    required this.userId,
    required this.points,
    required this.level,
    required this.levelName,
    required this.progressToNextLevel,
    required this.pointsToNextLevel,
    required this.rank,
  });
}
