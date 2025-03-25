class LeaderboardEntry {
  final String userId;
  final int rank;
  final String username;
  final int points;
  final int level;

  LeaderboardEntry({
    required this.userId,
    required this.rank,
    required this.username,
    required this.points,
    required this.level,
  });
}
