class AuthUser {
  final String token;
  final String usuario;
  final String rol;

  const AuthUser({
    required this.token,
    required this.usuario,
    required this.rol,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      token: json['token']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      rol: json['rol']?.toString() ?? 'Administrador',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'usuario': usuario,
      'rol': rol,
    };
  }
}
