class User {
  final String id;
  final String name;
  final String contact;
  final String role;
  final String userId;

  User({
    required this.id,
    required this.name,
    required this.contact,
    required this.role,
    required this.userId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      contact: json['contact'] ?? '',
      role: json['role'] ?? '',
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'contact': contact,
      'role': role,
      'userId': userId,
    };
  }
}
