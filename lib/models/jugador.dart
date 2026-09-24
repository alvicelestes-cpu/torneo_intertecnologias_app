import '../core/utils/date_utils.dart';
import '../core/utils/text_utils.dart';

class Jugador {
  final int id;
  final int equipoId;
  final String? equipoNombre;
  final String? equipoSigla;
  final String? equipoColor;
  final String? equipoLogo;
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
    this.equipoLogo,
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
    Map<String, dynamic>? equipoMap;
    if (json['equipo'] is Map) {
      equipoMap = Map<String, dynamic>.from(json['equipo'] as Map);
    }

    final parsedEquipoId = TextUtils.toInt(
      json['equipoId'] ?? json['equipo_id'] ?? equipoMap?['id'] ?? equipoMap?['Id'],
    );

    String? parsedEquipoNombre = json['equipoNombre']?.toString().trim();
    if (parsedEquipoNombre == null || parsedEquipoNombre.isEmpty) {
      if (equipoMap != null) {
        parsedEquipoNombre = (equipoMap['nombre'] ?? equipoMap['Nombre'])?.toString().trim();
      } else if (json['equipo'] != null && json['equipo'] is! Map) {
        final val = json['equipo'].toString().trim();
        if (!val.startsWith('{')) {
          parsedEquipoNombre = val;
        }
      }
    }
    if (parsedEquipoNombre != null && parsedEquipoNombre.startsWith('{')) {
      parsedEquipoNombre = null;
    }

    final parsedEquipoSigla = json['equipoSigla']?.toString().trim() ??
        json['siglaEquipo']?.toString().trim() ??
        json['sigla']?.toString().trim() ??
        equipoMap?['sigla']?.toString().trim() ??
        equipoMap?['Sigla']?.toString().trim();

    final parsedEquipoColor = json['equipoColor']?.toString().trim() ??
        json['colorPrincipal']?.toString().trim() ??
        json['color']?.toString().trim() ??
        equipoMap?['colorPrincipal']?.toString().trim() ??
        equipoMap?['ColorPrincipal']?.toString().trim() ??
        equipoMap?['color']?.toString().trim();

    String? parsedEquipoLogo = json['equipoLogo']?.toString().trim() ??
        json['logoEquipo']?.toString().trim() ??
        json['logo']?.toString().trim() ??
        equipoMap?['logo']?.toString().trim() ??
        equipoMap?['Logo']?.toString().trim();

    if (parsedEquipoLogo == null || parsedEquipoLogo.isEmpty || parsedEquipoLogo == 'string' || parsedEquipoLogo == 'null') {
      final upperNombre = (parsedEquipoNombre ?? '').toUpperCase();
      final upperSigla = (parsedEquipoSigla ?? '').toUpperCase();
      if (upperNombre.contains('RACING') || upperSigla == 'TRF' || upperSigla == 'TR') {
        parsedEquipoLogo = 'assets/logos/tienda_racing.png';
      } else {
        parsedEquipoLogo = null;
      }
    }

    return Jugador(
      id: TextUtils.toInt(json['id']),
      equipoId: parsedEquipoId,
      equipoNombre: parsedEquipoNombre,
      equipoSigla: parsedEquipoSigla,
      equipoColor: parsedEquipoColor,
      equipoLogo: parsedEquipoLogo,
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
      if (equipoLogo != null) 'equipoLogo': equipoLogo,
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
    String? equipoLogo,
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
      equipoLogo: equipoLogo ?? this.equipoLogo,
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
