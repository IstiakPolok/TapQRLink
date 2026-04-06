import 'dart:convert';

class ProfileUpdateRequest {
  final String aboutMe;
  final String city;
  final String country;
  final String education;
  final String bodyFrame;
  final String smoke;
  final String drink;
  final String familyType;
  final String marriageTimeline;
  final List<String> interests;
  final List<String> languages;
  final List<String> familyOrigin;
  final List<String> datingGoal;
  final String name;
  final String dateOfBirth;
  final String profession;
  final String gender;
  final String height;
  final String religion;
  final String maritalStatus;

  ProfileUpdateRequest({
    required this.aboutMe,
    required this.city,
    required this.country,
    required this.education,
    required this.bodyFrame,
    required this.smoke,
    required this.drink,
    required this.familyType,
    required this.marriageTimeline,
    required this.interests,
    required this.languages,
    required this.familyOrigin,
    required this.datingGoal,
    required this.name,
    required this.dateOfBirth,
    required this.profession,
    required this.gender,
    required this.height,
    required this.religion,
    required this.maritalStatus,
  });

  factory ProfileUpdateRequest.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateRequest(
      aboutMe: json['about_me'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      education: json['education'] as String? ?? '',
      bodyFrame: json['body_frame'] as String? ?? '',
      smoke: json['smoke'] as String? ?? '',
      drink: json['drink'] as String? ?? '',
      familyType: json['family_type'] as String? ?? '',
      marriageTimeline: json['marraige_timeline'] as String? ?? '',
      interests:
          (json['interests'] is String
                  ? jsonDecode(json['interests'] as String)
                  : json['interests'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      languages:
          (json['languages'] is String
                  ? jsonDecode(json['languages'] as String)
                  : json['languages'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      familyOrigin:
          (json['family_origin'] is String
                  ? jsonDecode(json['family_origin'] as String)
                  : json['family_origin'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      datingGoal:
          (json['dating_goal'] is String
                  ? jsonDecode(json['dating_goal'] as String)
                  : json['dating_goal'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      name: json['name'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      height: json['height'] as String? ?? '',
      religion: json['religion'] as String? ?? '',
      maritalStatus: json['marital_status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'about_me': aboutMe,
      'city': city,
      'country': country,
      'education': education,
      'body_frame': bodyFrame,
      'smoke': smoke,
      'drink': drink,
      'family_type': familyType,
      'marraige_timeline': marriageTimeline,
      'interests': interests,
      'languages': languages,
      'family_origin': familyOrigin,
      'dating_goal': datingGoal,
      'name': name,
      'date_of_birth': dateOfBirth,
      'profession': profession,
      'gender': gender,
      'height': height,
      'religion': religion,
      'marital_status': maritalStatus,
    };
  }
}
