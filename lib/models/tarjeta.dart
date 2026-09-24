import '../core/utils/text_utils.dart';

class Tarjeta {
  final int id;
  final int? partidoId;
  final int? jugadorId;
  final String jugadorNombre;
  final int? numeroCamiseta;
  final int? equipoId;
  final String equipoNombre;
  final String tipo; // 'AMARILLA' | 'ROJA'
  final int? minuto;
  final String? motivo;

  const Tarjeta({
    required this.id,
    this.partidoId,
    this.jugadorId,
    required this.jugadorNombre,
    this.numeroCamiseta,
    this.equipoId,
    required this.equipoNombre,
    required this.tipo,
    this.minuto,
    this.motivo,
  });

  String get nombreJugador => jugadorNombre;
  String get tipoTarjeta => tipo;
  String? get observacion => motivo;

  factory Tarjeta.fromJson(Map<String, dynamic> json) {
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
    if (json['nombreJugador'] != null && json['nombreJugador'].toString().trim().isNotEmpty) {
      jNombre = json['nombreJugador'].toString().trim();
    } else if (json['jugadorNombre'] != null && json['jugadorNombre'].toString().trim().isNotEmpty) {
      jNombre = json['jugadorNombre'].toString().trim();
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
    if (json['equipoNombre'] != null && json['equipoNombre'].toString().trim().isNotEmpty) {
      eqNombre = json['equipoNombre'].toString().trim();
    }
    if (json['equipoId'] != null) {
      eqId = TextUtils.toInt(json['equipoId']);
    }

    final rawTipo = json['tipoTarjeta'] ?? json['tipo'];
    final tipoStr = rawTipo?.toString().trim().toUpperCase() ?? 'AMARILLA';
    final obs = (json['observacion'] ?? json['motivo'])?.toString().trim();

    return Tarjeta(
      id: TextUtils.toInt(json['id']),
      partidoId: json['partidoId'] != null ? TextUtils.toInt(json['partidoId']) : null,
      jugadorId: jId,
      jugadorNombre: jNombre,
      numeroCamiseta: camiseta,
      equipoId: eqId,
      equipoNombre: eqNombre,
      tipo: tipoStr,
      minuto: json['minuto'] != null ? TextUtils.toInt(json['minuto']) : null,
      motivo: obs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (partidoId != null) 'partidoId': partidoId,
      if (jugadorId != null) 'jugadorId': jugadorId,
      'tipo': tipo,
      if (minuto != null) 'minuto': minuto,
      if (motivo != null) 'motivo': motivo,
    };
  }

  bool get esRoja => tipo == 'ROJA';
  bool get esAmarilla => tipo == 'AMARILLA';
}
