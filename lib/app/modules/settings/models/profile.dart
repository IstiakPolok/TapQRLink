class ProfileModel {
  final String firstName;
  final String lastName;
  final String email;
  final String bio;
  final String mobileNumber;
  final String profilePicture;

  ProfileModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.bio,
    required this.mobileNumber,
    required this.profilePicture,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'bio': bio,
      'mobile_number': mobileNumber,
      'profile_picture': profilePicture,
    };
  }
}

class ProfileUpdateRequest {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? bio;
  final String? mobileNumber;
  final String? profilePicture;

  ProfileUpdateRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.bio,
    this.mobileNumber,
    this.profilePicture,
  });

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (bio != null) 'bio': bio,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      if (profilePicture != null) 'profile_picture': profilePicture,
    };
  }
}
