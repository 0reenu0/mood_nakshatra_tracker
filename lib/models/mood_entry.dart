import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 0)
class MoodEntry extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String nakshatra;

  @HiveField(3)
  String mood; // angry/sad/happy/productive

  @HiveField(4)
  String? notes;

  MoodEntry({
    required this.id,
    required this.date,
    required this.nakshatra,
    required this.mood,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'nakshatra': nakshatra,
      'mood': mood,
      'notes': notes,
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      nakshatra: json['nakshatra'] as String,
      mood: json['mood'] as String,
      notes: json['notes'] as String?,
    );
  }
}

