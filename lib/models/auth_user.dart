import '../core/utils/text_utils.dart';

class AuthUser {
  final String token;
  final String usuario;
  final String rol;
  final int? campeonatoId;
  final String? campeonato;

  const AuthUser({
    required this.token,
    required this.usuario,
    required this.rol,
    this.campeonatoId,
    this.campeonato,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      token: json['token']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      rol: json['rol']?.toString() ?? 'Administrador',
      campeonatoId: json['campeonatoId'] != null ? TextUtils.toInt(json['campeonatoId']) : null,
      campeonato: json['campeonato']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'usuario': usuario,
      'rol': rol,
      if (campeonatoId != null) 'campeonatoId': campeonatoId,
      if (campeonato != null) 'campeonato': campeonato,
    };
  }
}
