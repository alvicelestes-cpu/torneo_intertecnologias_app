import '../core/utils/text_utils.dart';

class Gol {
  final int id;
  final int? partidoId;
  final int? jugadorId;
  final String jugadorNombre;
  final int? numeroCamiseta;
  final int? equipoId;
  final String equipoNombre;
  final int? minuto;
  final String? observacion;

  const Gol({
    required this.id,
    this.partidoId,
    this.jugadorId,
    required this.jugadorNombre,
    this.numeroCamiseta,
    this.equipoId,
    required this.equipoNombre,
    this.minuto,
    this.observacion,
  });

  factory Gol.fromJson(Map<String, dynamic> json) {
    int? jId;
    String jNombre = 'Jugador';
    int? camiseta;
    final rawJugador = json['jugador'];
    if (rawJugador is Map) {
      jId = rawJugador['id'] != null ? TextUtils.toInt(rawJugador['id']) : null;
      final nom = rawJugador['nombres']?.toString().trim() ?? '';
      final ape = rawJugador['apellidos']?.toString().trim() ?? '';
      final full = '$nom $ape'.trim();
      if (full.isNotEmpty) jNombre = full;
      if (rawJugador['numeroCamiseta'] != null) {
        camiseta = TextUtils.toInt(rawJugador['numeroCamiseta']);
      }
    } else if (rawJugador != null) {
      jNombre = rawJugador.toString();
    }
    if (json['jugadorId'] != null) {
      jId = TextUtils.toInt(json['jugadorId']);
    }

    int? eqId;
    String eqNombre = 'Equipo';
    final rawEquipo = json['equipo'];
    if (rawEquipo is Map) {
      eqId = rawEquipo['id'] != null ? TextUtils.toInt(rawEquipo['id']) : null;
      eqNombre = rawEquipo['nombre']?.toString().trim() ?? eqNombre;
    } else if (rawEquipo != null) {
      eqNombre = rawEquipo.toString();
    }
    if (json['equipoId'] != null) {
      eqId = TextUtils.toInt(json['equipoId']);
    }

    return Gol(
      id: TextUtils.toInt(json['id']),
      partidoId: json['partidoId'] != null ? TextUtils.toInt(json['partidoId']) : null,
      jugadorId: jId,
      jugadorNombre: jNombre,
      numeroCamiseta: camiseta,
      equipoId: eqId,
      equipoNombre: eqNombre,
      minuto: json['minuto'] != null ? TextUtils.toInt(json['minuto']) : null,
      observacion: json['observacion']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (partidoId != null) 'partidoId': partidoId,
      if (jugadorId != null) 'jugadorId': jugadorId,
      if (minuto != null) 'minuto': minuto,
      if (observacion != null) 'observacion': observacion,
    };
  }
}
