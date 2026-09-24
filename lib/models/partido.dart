import '../core/utils/text_utils.dart';
import 'gol.dart';
import 'tarjeta.dart';

class Partido {
  final int id;
  final int? equipoLocalId;
  final String equipoLocalNombre;
  final String? equipoLocalSigla;
  final String? equipoLocalLogo;

  final int? equipoVisitanteId;
  final String equipoVisitanteNombre;
  final String? equipoVisitanteSigla;
  final String? equipoVisitanteLogo;

  final int? golesLocal;
  final int? golesVisitante;
  final String estado;
  final String? fase;
  final int? jornada;
  final String? fechaHora;
  final String? cancha;
  final String? llave;
  final String? observaciones;
  final List<Gol> goles;
  final List<Tarjeta> tarjetas;

  const Partido({
    required this.id,
    this.equipoLocalId,
    required this.equipoLocalNombre,
    this.equipoLocalSigla,
    this.equipoLocalLogo,
    this.equipoVisitanteId,
    required this.equipoVisitanteNombre,
    this.equipoVisitanteSigla,
    this.equipoVisitanteLogo,
    this.golesLocal,
    this.golesVisitante,
    this.estado = 'PROGRAMADO',
    this.fase,
    this.jornada,
    this.fechaHora,
    this.cancha,
    this.llave,
    this.observaciones,
    this.goles = const [],
    this.tarjetas = const [],
  });

  factory Partido.fromJson(Map<String, dynamic> json) {
    // Parser flexible para equipo local
    int? localId;
    String localNombre = 'Equipo local';
    String? localSigla;
    String? localLogo;

    final rawLocal = json['equipoLocal'] ?? json['equipo_local'];
    if (rawLocal is Map) {
      localId = rawLocal['id'] != null ? TextUtils.toInt(rawLocal['id']) : null;
      localNombre = rawLocal['nombre']?.toString().trim() ?? localNombre;
      localSigla = rawLocal['sigla']?.toString().trim();
      localLogo = rawLocal['logo']?.toString().trim();
    } else if (rawLocal != null) {
      localNombre = rawLocal.toString().trim();
    }
    if (json['equipoLocalNombre'] != null) {
      localNombre = json['equipoLocalNombre'].toString().trim();
    }
    if (json['equipoLocalSigla'] != null) {
      localSigla = json['equipoLocalSigla'].toString().trim();
    }
    if (json['equipoLocalLogo'] != null) {
      localLogo = json['equipoLocalLogo'].toString().trim();
    }
    if (json['equipoLocalId'] != null) {
      localId = TextUtils.toInt(json['equipoLocalId']);
    }

    // Parser flexible para equipo visitante
    int? visitanteId;
    String visitanteNombre = 'Equipo visitante';
    String? visitanteSigla;
    String? visitanteLogo;

    final rawVisitante = json['equipoVisitante'] ?? json['equipo_visitante'];
    if (rawVisitante is Map) {
      visitanteId = rawVisitante['id'] != null ? TextUtils.toInt(rawVisitante['id']) : null;
      visitanteNombre = rawVisitante['nombre']?.toString().trim() ?? visitanteNombre;
      visitanteSigla = rawVisitante['sigla']?.toString().trim();
      visitanteLogo = rawVisitante['logo']?.toString().trim();
    } else if (rawVisitante != null) {
      visitanteNombre = rawVisitante.toString().trim();
    }
    if (json['equipoVisitanteNombre'] != null) {
      visitanteNombre = json['equipoVisitanteNombre'].toString().trim();
    }
    if (json['equipoVisitanteSigla'] != null) {
      visitanteSigla = json['equipoVisitanteSigla'].toString().trim();
    }
    if (json['equipoVisitanteLogo'] != null) {
      visitanteLogo = json['equipoVisitanteLogo'].toString().trim();
    }
    if (json['equipoVisitanteId'] != null) {
      visitanteId = TextUtils.toInt(json['equipoVisitanteId']);
    }

    if (localLogo == null || localLogo.isEmpty || localLogo == 'string' || localLogo == 'null') {
      final upperNombre = localNombre.toUpperCase();
      final upperSigla = localSigla?.toUpperCase() ?? '';
      if (upperNombre.contains('RACING') || upperSigla == 'TRF' || upperSigla == 'TR') {
        localLogo = 'assets/logos/tienda_racing.png';
      }
    }

    if (visitanteLogo == null || visitanteLogo.isEmpty || visitanteLogo == 'string' || visitanteLogo == 'null') {
      final upperNombre = visitanteNombre.toUpperCase();
      final upperSigla = visitanteSigla?.toUpperCase() ?? '';
      if (upperNombre.contains('RACING') || upperSigla == 'TRF' || upperSigla == 'TR') {
        visitanteLogo = 'assets/logos/tienda_racing.png';
      }
    }

    final rawGoles = json['goles'];
    List<Gol> parsedGoles = const [];
    if (rawGoles is List) {
      parsedGoles = rawGoles
          .whereType<Map>()
          .map((g) => Gol.fromJson(Map<String, dynamic>.from(g)))
          .toList();
    }

    final rawTarjetas = json['tarjetas'];
    List<Tarjeta> parsedTarjetas = const [];
    if (rawTarjetas is List) {
      parsedTarjetas = rawTarjetas
          .whereType<Map>()
          .map((t) => Tarjeta.fromJson(Map<String, dynamic>.from(t)))
          .toList();
    }

    return Partido(
      id: TextUtils.toInt(json['id']),
      equipoLocalId: localId,
      equipoLocalNombre: localNombre,
      equipoLocalSigla: localSigla,
      equipoLocalLogo: localLogo,
      equipoVisitanteId: visitanteId,
      equipoVisitanteNombre: visitanteNombre,
      equipoVisitanteSigla: visitanteSigla,
      equipoVisitanteLogo: visitanteLogo,
      golesLocal: json['golesLocal'] != null ? TextUtils.toInt(json['golesLocal']) : null,
      golesVisitante: json['golesVisitante'] != null ? TextUtils.toInt(json['golesVisitante']) : null,
      estado: json['estado']?.toString().trim() ?? 'PROGRAMADO',
      fase: json['fase']?.toString().trim(),
      jornada: json['jornada'] != null ? TextUtils.toInt(json['jornada']) : null,
      fechaHora: json['fechaHora']?.toString() ?? json['fecha_hora']?.toString(),
      cancha: json['cancha']?.toString().trim(),
      llave: json['llave']?.toString().trim(),
      observaciones: json['observaciones']?.toString().trim(),
      goles: parsedGoles,
      tarjetas: parsedTarjetas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipoLocalId': equipoLocalId,
      'equipoLocal': equipoLocalNombre,
      'equipoVisitanteId': equipoVisitanteId,
      'equipoVisitante': equipoVisitanteNombre,
      'golesLocal': golesLocal,
      'golesVisitante': golesVisitante,
      'estado': estado,
      if (fase != null) 'fase': fase,
      if (jornada != null) 'jornada': jornada,
      if (fechaHora != null) 'fechaHora': fechaHora,
      if (cancha != null) 'cancha': cancha,
      if (llave != null) 'llave': llave,
      if (observaciones != null) 'observaciones': observaciones,
      if (goles.isNotEmpty) 'goles': goles.map((g) => g.toJson()).toList(),
      if (tarjetas.isNotEmpty) 'tarjetas': tarjetas.map((t) => t.toJson()).toList(),
    };
  }

  Partido copyWith({
    int? id,
    int? equipoLocalId,
    String? equipoLocalNombre,
    String? equipoLocalSigla,
    String? equipoLocalLogo,
    int? equipoVisitanteId,
    String? equipoVisitanteNombre,
    String? equipoVisitanteSigla,
    String? equipoVisitanteLogo,
    int? golesLocal,
    int? golesVisitante,
    String? estado,
    String? fase,
    int? jornada,
    String? fechaHora,
    String? cancha,
    String? llave,
    String? observaciones,
    List<Gol>? goles,
    List<Tarjeta>? tarjetas,
  }) {
    return Partido(
      id: id ?? this.id,
      equipoLocalId: equipoLocalId ?? this.equipoLocalId,
      equipoLocalNombre: equipoLocalNombre ?? this.equipoLocalNombre,
      equipoLocalSigla: equipoLocalSigla ?? this.equipoLocalSigla,
      equipoLocalLogo: equipoLocalLogo ?? this.equipoLocalLogo,
      equipoVisitanteId: equipoVisitanteId ?? this.equipoVisitanteId,
      equipoVisitanteNombre: equipoVisitanteNombre ?? this.equipoVisitanteNombre,
      equipoVisitanteSigla: equipoVisitanteSigla ?? this.equipoVisitanteSigla,
      equipoVisitanteLogo: equipoVisitanteLogo ?? this.equipoVisitanteLogo,
      golesLocal: golesLocal ?? this.golesLocal,
      golesVisitante: golesVisitante ?? this.golesVisitante,
      estado: estado ?? this.estado,
      fase: fase ?? this.fase,
      jornada: jornada ?? this.jornada,
      fechaHora: fechaHora ?? this.fechaHora,
      cancha: cancha ?? this.cancha,
      llave: llave ?? this.llave,
      observaciones: observaciones ?? this.observaciones,
      goles: goles ?? this.goles,
      tarjetas: tarjetas ?? this.tarjetas,
    );
  }

  String get marcador {
    if (golesLocal == null || golesVisitante == null) return '-';
    return '$golesLocal - $golesVisitante';
  }

  bool get esFinalizado => estado.toUpperCase() == 'FINALIZADO';
  bool get esEnCurso => estado.toUpperCase() == 'EN_CURSO';
  bool get esProgramado => estado.toUpperCase() == 'PROGRAMADO';
}
