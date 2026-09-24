import 'package:flutter/painting.dart';

import '../core/utils/text_utils.dart';

class Equipo {
  final int id;
  final String nombre;
  final String sigla;
  final String? logo;
  final String? colorPrincipal;
  final int cantidadJugadores;
  final bool activo;
  final String? fechaCreacion;

  const Equipo({
    required this.id,
    required this.nombre,
    required this.sigla,
    this.logo,
    this.colorPrincipal,
    this.cantidadJugadores = 0,
    this.activo = true,
    this.fechaCreacion,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    final nombre = json['nombre']?.toString().trim() ?? 'Sin nombre';
    final sigla = json['sigla']?.toString().trim() ?? '';
    String? logo = json['logo']?.toString().trim();
    if (logo == null || logo.isEmpty || logo == 'string' || logo == 'null') {
      final upperNombre = nombre.toUpperCase();
      final upperSigla = sigla.toUpperCase();
      if (upperNombre.contains('RACING') || upperSigla == 'TRF' || upperSigla == 'TR') {
        logo = 'assets/logos/tienda_racing.png';
      } else {
        logo = null;
      }
    }

    return Equipo(
      id: TextUtils.toInt(json['id']),
      nombre: nombre,
      sigla: sigla,
      logo: logo,
      colorPrincipal: json['colorPrincipal']?.toString().trim() ??
          json['color_principal']?.toString().trim() ??
          json['color']?.toString().trim(),
      cantidadJugadores: TextUtils.toInt(
        json['cantidadJugadores'] ?? json['totalJugadores'] ?? 0,
      ),
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
      if (colorPrincipal != null) 'colorPrincipal': colorPrincipal,
      'cantidadJugadores': cantidadJugadores,
      'activo': activo,
      if (fechaCreacion != null) 'fechaCreacion': fechaCreacion,
    };
  }

  Equipo copyWith({
    int? id,
    String? nombre,
    String? sigla,
    String? logo,
    String? colorPrincipal,
    int? cantidadJugadores,
    bool? activo,
    String? fechaCreacion,
  }) {
    return Equipo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      sigla: sigla ?? this.sigla,
      logo: logo ?? this.logo,
      colorPrincipal: colorPrincipal ?? this.colorPrincipal,
      cantidadJugadores: cantidadJugadores ?? this.cantidadJugadores,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  Color get color => TextUtils.parseColor(colorPrincipal);

  String get iniciales => TextUtils.getInitials(nombre, sigla: sigla);
}
