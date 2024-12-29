class UserProfile {
  final String? userId;
  final String? password;
  final String? imageBase64; // Add this field for Base64 image

  UserProfile({
    this.userId,
    this.password,
    this.imageBase64,
  });

  // Add fromJson and toJson methods to handle the JSON serialization
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      password: json['password'],
      imageBase64: json['imageBase64'], // Parse imageBase64 from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'password': password,
      'imageBase64': imageBase64, // Add imageBase64 to JSON
    };
  }
}
