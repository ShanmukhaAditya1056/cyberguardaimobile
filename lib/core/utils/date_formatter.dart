class DateFormatter {
  DateFormatter._();

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return '$m minute${m > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final h = difference.inHours;
      return '$h hour${h > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final d = difference.inDays;
      return '$d day${d > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final w = (difference.inDays / 7).floor();
      return '$w week${w > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final mo = (difference.inDays / 30).floor();
      return '$mo month${mo > 1 ? 's' : ''} ago';
    } else {
      final y = (difference.inDays / 365).floor();
      return '$y year${y > 1 ? 's' : ''} ago';
    }
  }

  static String shortDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  static String fullDate(DateTime dateTime) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  static String timeOnly(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String dateTime(DateTime dt) {
    return '${shortDate(dt)} at ${timeOnly(dt)}';
  }

  static String formatApkSize(int bytes) {
    if (bytes <= 0) return 'Unknown';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  static String formatTimestamp(int milliseconds) {
    return timeAgo(DateTime.fromMillisecondsSinceEpoch(milliseconds));
  }

  static String dayLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[dateTime.weekday - 1];
  }
}
