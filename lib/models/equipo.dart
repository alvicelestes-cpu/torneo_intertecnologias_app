import '../core/utils/text_utils.dart';

class Equipo {
  final int id;
  final String nombre;
  final String sigla;
  final String? logo;
  final bool activo;
  final String? fechaCreacion;

  const Equipo({
    required this.id,
    required this.nombre,
    required this.sigla,
    this.logo,
    this.activo = true,
    this.fechaCreacion,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      id: TextUtils.toInt(json['id']),
      nombre: json['nombre']?.toString().trim() ?? 'Sin nombre',
      sigla: json['sigla']?.toString().trim() ?? '',
      logo: json['logo']?.toString().trim(),
      activo: json['activo'] == true || json['activo'] == 1 || json['activo'] == null,
      fechaCreacion: json['fechaCreacion']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'sigla': sigla,
      if (logo != null) 'logo': logo,
      'activo': activo,
      if (fechaCreacion != null) 'fechaCreacion': fechaCreacion,
    };
  }

  String get iniciales => TextUtils.getInitials(nombre, sigla: sigla);
}
