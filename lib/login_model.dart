class User {
  final String username;
  final String name;
  final String role;

  User({
    required this.username, 
    required this.name, 
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      name: json['name'] ?? json['username'], // fallback to username if name is not provided
      role: json['role']?.trim() ?? '', // trim to handle extra spaces
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'name': name,
      'role': role,
    };
  }
}