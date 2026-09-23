import '../core/utils/date_utils.dart';
import '../core/utils/text_utils.dart';

class Jugador {
  final int id;
  final int equipoId;
  final String? equipoNombre;
  final String? equipoSigla;
  final String? equipoColor;
  final String nombres;
  final String apellidos;
  final int? numeroCamiseta;
  final String? documento;
  final String? fechaNacimiento;
  final String? posicion;
  final String? fotoJugador;
  final String estado;
  final String? observacionAdmin;
  final int goles;
  final int amarillas;
  final int rojas;

  const Jugador({
    required this.id,
    required this.equipoId,
    this.equipoNombre,
    this.equipoSigla,
    this.equipoColor,
    required this.nombres,
    required this.apellidos,
    this.numeroCamiseta,
    this.documento,
    this.fechaNacimiento,
    this.posicion,
    this.fotoJugador,
    this.estado = 'ACTIVO',
    this.observacionAdmin,
    this.goles = 0,
    this.amarillas = 0,
    this.rojas = 0,
  });

  factory Jugador.fromJson(Map<String, dynamic> json) {
    return Jugador(
      id: TextUtils.toInt(json['id']),
      equipoId: TextUtils.toInt(json['equipoId'] ?? json['equipo_id']),
      equipoNombre: json['equipoNombre']?.toString() ?? json['equipo']?.toString(),
      equipoSigla: json['equipoSigla']?.toString().trim() ??
          json['siglaEquipo']?.toString().trim() ??
          json['sigla']?.toString().trim(),
      equipoColor: json['equipoColor']?.toString().trim() ??
          json['colorPrincipal']?.toString().trim() ??
          json['color']?.toString().trim(),
      nombres: json['nombres']?.toString().trim() ?? '',
      apellidos: json['apellidos']?.toString().trim() ?? '',
      numeroCamiseta: json['numeroCamiseta'] != null
          ? TextUtils.toInt(json['numeroCamiseta'])
          : (json['numero_camiseta'] != null ? TextUtils.toInt(json['numero_camiseta']) : null),
      documento: json['documento']?.toString().trim(),
      fechaNacimiento: json['fechaNacimiento']?.toString() ?? json['fecha_nacimiento']?.toString(),
      posicion: json['posicion']?.toString().trim(),
      fotoJugador: json['fotoJugador']?.toString().trim() ?? json['foto_jugador']?.toString().trim(),
      estado: json['estado']?.toString().trim() ?? 'ACTIVO',
      observacionAdmin: json['observacionAdmin']?.toString().trim() ?? json['observacion_admin']?.toString().trim(),
      goles: TextUtils.toInt(json['goles'] ?? json['totalGoles'] ?? 0),
      amarillas: TextUtils.toInt(json['amarillas'] ?? 0),
      rojas: TextUtils.toInt(json['rojas'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipoId': equipoId,
      if (equipoNombre != null) 'equipoNombre': equipoNombre,
      if (equipoSigla != null) 'equipoSigla': equipoSigla,
      if (equipoColor != null) 'equipoColor': equipoColor,
      'nombres': nombres,
      'apellidos': apellidos,
      'numeroCamiseta': numeroCamiseta,
      if (documento != null) 'documento': documento,
      if (fechaNacimiento != null) 'fechaNacimiento': fechaNacimiento,
      if (posicion != null) 'posicion': posicion,
      if (fotoJugador != null) 'fotoJugador': fotoJugador,
      'estado': estado,
      if (observacionAdmin != null) 'observacionAdmin': observacionAdmin,
      'goles': goles,
      'amarillas': amarillas,
      'rojas': rojas,
    };
  }

  Jugador copyWith({
    int? id,
    int? equipoId,
    String? equipoNombre,
    String? equipoSigla,
    String? equipoColor,
    String? nombres,
    String? apellidos,
    int? numeroCamiseta,
    String? documento,
    String? fechaNacimiento,
    String? posicion,
    String? fotoJugador,
    String? estado,
    String? observacionAdmin,
    int? goles,
    int? amarillas,
    int? rojas,
  }) {
    return Jugador(
      id: id ?? this.id,
      equipoId: equipoId ?? this.equipoId,
      equipoNombre: equipoNombre ?? this.equipoNombre,
      equipoSigla: equipoSigla ?? this.equipoSigla,
      equipoColor: equipoColor ?? this.equipoColor,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      numeroCamiseta: numeroCamiseta ?? this.numeroCamiseta,
      documento: documento ?? this.documento,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      posicion: posicion ?? this.posicion,
      fotoJugador: fotoJugador ?? this.fotoJugador,
      estado: estado ?? this.estado,
      observacionAdmin: observacionAdmin ?? this.observacionAdmin,
      goles: goles ?? this.goles,
      amarillas: amarillas ?? this.amarillas,
      rojas: rojas ?? this.rojas,
    );
  }

  int? get edad => AppDateUtils.calculateAge(fechaNacimiento);
  String get nombreCompleto => '$nombres $apellidos'.trim();
  String get iniciales => TextUtils.getInitials('$nombres $apellidos');
}
