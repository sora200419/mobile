class FormattingUtils {
  // Format date in standard format
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Format timestamp for chat messages
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  // Format time from minutes
  static String formatTimeFromMinutes(double minutes) {
    if (minutes < 1) return 'less than a minute';
    if (minutes < 60) return '${minutes.round()} mins';

    int hours = (minutes / 60).floor();
    int mins = (minutes % 60).round();
    return '$hours h ${mins > 0 ? '$mins mins' : ''}';
  }
}
