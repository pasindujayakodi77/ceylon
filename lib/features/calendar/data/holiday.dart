// FILE: lib/features/calendar/data/holiday.dart

class Holiday {
  final DateTime date;
  final String name;
  final String type;

  const Holiday({required this.date, required this.name, required this.type});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: DateTime.parse(json['date'] as String),
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0], // Keep only date part
      'name': name,
      'type': type,
    };
  }

  /// Returns formatted date string (e.g., "January 14, 2025")
  String get formattedDate {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  /// Check if holiday is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if holiday is upcoming (in the future)
  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final holidayDate = DateTime(date.year, date.month, date.day);
    return holidayDate.isAfter(today);
  }

  @override
  String toString() {
    return 'Holiday(name: $name, date: $date, type: $type)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Holiday &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          name == other.name &&
          type == other.type;

  @override
  int get hashCode => Object.hash(date, name, type);
}
