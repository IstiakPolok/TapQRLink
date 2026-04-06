class ProfileUpdateResponse {
  final String message;
  final String verify;

  ProfileUpdateResponse({required this.message, required this.verify});

  factory ProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateResponse(
      message: json['message'] as String? ?? 'Unknown message',
      verify: json['verify'] as String? ?? 'Unknown verify status',
    );
  }
}
