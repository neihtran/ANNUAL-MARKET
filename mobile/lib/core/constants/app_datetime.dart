class AppDateTime {
  static DateTime parseToLocal(dynamic value, {DateTime? fallback}) {
    final fallbackValue = fallback ?? DateTime.now();

    if (value == null) return fallbackValue;
    if (value is DateTime) return value.toLocal();

    final raw = value.toString().trim();
    if (raw.isEmpty) return fallbackValue;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return fallbackValue;

    final hasTimezone = raw.endsWith('Z') ||
        raw.contains(RegExp(r'[+-]\d{2}:?\d{2}4'));

    return hasTimezone ? parsed.toLocal() : parsed;
  }

  static String formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  static String formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }

  static String timeAgo(DateTime value, {DateTime? now}) {
    final current = (now ?? DateTime.now()).toLocal();
    final local = value.toLocal();
    final diff = current.difference(local);

    if (diff.isNegative) return 'Vừa xong';
    if (diff.inSeconds < 60) return '${diff.inSeconds} giây trước';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return formatDateTime(local);
  }
}
