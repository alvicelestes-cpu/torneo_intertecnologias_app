import '../core/utils/text_utils.dart';

class Goleador {
  final int? posicion;
  final int jugadorId;
  final String nombres;
  final String apellidos;
  final int? equipoId;
  final String equipo;
  final int goles;
  final String? fotoJugador;

  const Goleador({
    this.posicion,
    required this.jugadorId,
    required this.nombres,
    required this.apellidos,
    this.equipoId,
    required this.equipo,
    required this.goles,
    this.fotoJugador,
  });

  factory Goleador.fromJson(Map<String, dynamic> json) {
    return Goleador(
      posicion: json['posicion'] != null ? TextUtils.toInt(json['posicion']) : null,
      jugadorId: TextUtils.toInt(json['jugadorId'] ?? json['jugador_id']),
      nombres: json['nombres']?.toString().trim() ?? '',
      apellidos: json['apellidos']?.toString().trim() ?? '',
      equipoId: json['equipoId'] != null ? TextUtils.toInt(json['equipoId']) : null,
      equipo: json['equipo']?.toString().trim() ??
          json['equipoNombre']?.toString().trim() ??
          'Sin equipo',
      goles: TextUtils.toInt(json['goles']),
      fotoJugador: json['fotoJugador']?.toString().trim() ?? json['foto_jugador']?.toString().trim(),
    );
  }

  Goleador copyWith({
    int? posicion,
    int? jugadorId,
    String? nombres,
    String? apellidos,
    int? equipoId,
    String? equipo,
    int? goles,
    String? fotoJugador,
  }) {
    return Goleador(
      posicion: posicion ?? this.posicion,
      jugadorId: jugadorId ?? this.jugadorId,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      equipoId: equipoId ?? this.equipoId,
      equipo: equipo ?? this.equipo,
      goles: goles ?? this.goles,
      fotoJugador: fotoJugador ?? this.fotoJugador,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (posicion != null) 'posicion': posicion,
      'jugadorId': jugadorId,
      'nombres': nombres,
      'apellidos': apellidos,
      if (equipoId != null) 'equipoId': equipoId,
      'equipo': equipo,
      'goles': goles,
      if (fotoJugador != null) 'fotoJugador': fotoJugador,
    };
  }

  String get nombreCompleto {
    final full = '$nombres $apellidos'.trim();
    return full.isNotEmpty ? full : 'Jugador';
  }

  String get iniciales => TextUtils.getInitials(nombreCompleto);
}
