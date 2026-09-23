import '../core/utils/text_utils.dart';

class Jugador {
  final int id;
  final int equipoId;
  final String? equipoNombre;
  final String nombres;
  final String apellidos;
  final int? numeroCamiseta;
  final String? documento;
  final String? fechaNacimiento;
  final String? posicion;
  final String? fotoJugador;
  final String estado;
  final String? observacionAdmin;

  const Jugador({
    required this.id,
    required this.equipoId,
    this.equipoNombre,
    required this.nombres,
    required this.apellidos,
    this.numeroCamiseta,
    this.documento,
    this.fechaNacimiento,
    this.posicion,
    this.fotoJugador,
    this.estado = 'ACTIVO',
    this.observacionAdmin,
  });

  factory Jugador.fromJson(Map<String, dynamic> json) {
    return Jugador(
      id: TextUtils.toInt(json['id']),
      equipoId: TextUtils.toInt(json['equipoId'] ?? json['equipo_id']),
      equipoNombre: json['equipoNombre']?.toString() ?? json['equipo']?.toString(),
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipoId': equipoId,
      if (equipoNombre != null) 'equipoNombre': equipoNombre,
      'nombres': nombres,
      'apellidos': apellidos,
      'numeroCamiseta': numeroCamiseta,
      if (documento != null) 'documento': documento,
      if (fechaNacimiento != null) 'fechaNacimiento': fechaNacimiento,
      if (posicion != null) 'posicion': posicion,
      if (fotoJugador != null) 'fotoJugador': fotoJugador,
      'estado': estado,
      if (observacionAdmin != null) 'observacionAdmin': observacionAdmin,
    };
  }

  String get nombreCompleto => '$nombres $apellidos'.trim();
  String get iniciales => TextUtils.getInitials('$nombres $apellidos');
}
