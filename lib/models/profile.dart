import 'package:hive/hive.dart';

part 'profile.g.dart';

@HiveType(typeId: 1)
class Profile extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String gender; // Male, Female, Other, Prefer not to say

  @HiveField(2)
  DateTime birthdate;

  @HiveField(3)
  DateTime? birthTime; // Optional

  @HiveField(4)
  String city;

  @HiveField(5)
  String country;

  Profile({
    required this.username,
    required this.gender,
    required this.birthdate,
    this.birthTime,
    required this.city,
    required this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'gender': gender,
      'birthdate': birthdate.toIso8601String(),
      'birthTime': birthTime?.toIso8601String(),
      'city': city,
      'country': country,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      username: json['username'] as String,
      gender: json['gender'] as String,
      birthdate: DateTime.parse(json['birthdate'] as String),
      birthTime: json['birthTime'] != null
          ? DateTime.parse(json['birthTime'] as String)
          : null,
      city: json['city'] as String,
      country: json['country'] as String,
    );
  }
}

