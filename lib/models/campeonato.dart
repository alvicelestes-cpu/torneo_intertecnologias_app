import '../core/utils/date_utils.dart';
import '../core/utils/text_utils.dart';

class Campeonato {
  final int id;
  final String nombre;
  final String slug;
  final String? logo;
  final String? organizador;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final String? plan;
  final bool activo;
  final bool publicado;
  final int totalEquipos;
  final int totalPartidos;

  const Campeonato({
    required this.id,
    required this.nombre,
    required this.slug,
    this.logo,
    this.organizador,
    this.fechaInicio,
    this.fechaFin,
    this.estado = 'ACTIVO',
    this.plan,
    this.activo = true,
    this.publicado = true,
    this.totalEquipos = 0,
    this.totalPartidos = 0,
  });

  factory Campeonato.fromJson(Map<String, dynamic> json) {
    return Campeonato(
      id: TextUtils.toInt(json['id']),
      nombre: json['nombre']?.toString().trim() ?? 'Campeonato sin nombre',
      slug: json['slug']?.toString().trim() ?? '',
      logo: json['logo']?.toString().trim(),
      organizador: json['organizador']?.toString().trim(),
      fechaInicio: AppDateUtils.tryParse(json['fechaInicio']),
      fechaFin: AppDateUtils.tryParse(json['fechaFin']),
      estado: json['estado']?.toString().trim() ?? 'ACTIVO',
      plan: json['plan']?.toString().trim(),
      activo: json['activo'] == true || json['activo'] == 1 || json['activo'] == 'true',
      publicado: json['publicado'] == true || json['publicado'] == 1 || json['publicado'] == 'true',
      totalEquipos: TextUtils.toInt(json['totalEquipos']),
      totalPartidos: TextUtils.toInt(json['totalPartidos']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'slug': slug,
      if (logo != null) 'logo': logo,
      if (organizador != null) 'organizador': organizador,
      if (fechaInicio != null) 'fechaInicio': fechaInicio!.toIso8601String(),
      if (fechaFin != null) 'fechaFin': fechaFin!.toIso8601String(),
      'estado': estado,
      if (plan != null) 'plan': plan,
      'activo': activo,
      'publicado': publicado,
      'totalEquipos': totalEquipos,
      'totalPartidos': totalPartidos,
    };
  }

  String get iniciales => TextUtils.getInitials(nombre);
  bool get estaActivo => activo && estado.toUpperCase() == 'ACTIVO';
  bool get estaPublicado => estaActivo && publicado;

  Campeonato copyWith({
    int? id,
    String? nombre,
    String? slug,
    String? logo,
    String? organizador,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
    String? plan,
    bool? activo,
    bool? publicado,
    int? totalEquipos,
    int? totalPartidos,
  }) {
    return Campeonato(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      slug: slug ?? this.slug,
      logo: logo ?? this.logo,
      organizador: organizador ?? this.organizador,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      plan: plan ?? this.plan,
      activo: activo ?? this.activo,
      publicado: publicado ?? this.publicado,
      totalEquipos: totalEquipos ?? this.totalEquipos,
      totalPartidos: totalPartidos ?? this.totalPartidos,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Campeonato && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
