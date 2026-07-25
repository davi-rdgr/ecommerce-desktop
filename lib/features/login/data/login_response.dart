/// Resposta de `POST /auth/admin/login`.
class LoginResponse {
  final String token;
  final String adminName;

  const LoginResponse({required this.token, required this.adminName});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    token: json['token'] as String,
    adminName: json['nome'] as String,
  );
}
