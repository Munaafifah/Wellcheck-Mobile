class LoginRequest {
  final String userId;
  final String password;

  LoginRequest({required this.userId, required this.password});

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "password": password,
      };
}

class LoginResponse {
  final String token;

  LoginResponse({required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(token: json["token"]);
  }
}
