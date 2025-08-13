import 'package:equatable/equatable.dart';

class Holiday extends Equatable {
  final String name;
  final DateTime date;
  final String type;
  final String description;

  const Holiday({
    required this.name,
    required this.date,
    required this.type,
    required this.description,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [name, date, type, description];
}
