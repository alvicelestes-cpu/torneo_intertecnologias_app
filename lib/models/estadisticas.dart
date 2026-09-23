import '../core/utils/text_utils.dart';

class EstadisticasTorneo {
  final EquipoEstadistica? vallaMenosVencida;
  final EquipoEstadistica? equipoMasGoleador;
  final EquipoEstadistica? mejorDiferenciaGol;
  final EquipoEstadistica? menosAmarillas;
  final EquipoEstadistica? menosRojas;
  final GoleadorEstadistica? goleador;
  final List<EquipoFairPlay> fairPlay;

  const EstadisticasTorneo({
    this.vallaMenosVencida,
    this.equipoMasGoleador,
    this.mejorDiferenciaGol,
    this.menosAmarillas,
    this.menosRojas,
    this.goleador,
    this.fairPlay = const [],
  });

  factory EstadisticasTorneo.fromJson(Map<String, dynamic> json) {
    EquipoEstadistica? parseEquipo(dynamic val) {
      if (val is Map<String, dynamic>) return EquipoEstadistica.fromJson(val);
      if (val is Map) return EquipoEstadistica.fromJson(Map<String, dynamic>.from(val));
      return null;
    }

    GoleadorEstadistica? parseGoleador(dynamic val) {
      if (val is Map<String, dynamic>) return GoleadorEstadistica.fromJson(val);
      if (val is Map) return GoleadorEstadistica.fromJson(Map<String, dynamic>.from(val));
      return null;
    }

    final rawFp = json['fairPlay'];
    final fpList = <EquipoFairPlay>[];
    if (rawFp is List) {
      for (final item in rawFp) {
        if (item is Map<String, dynamic>) {
          fpList.add(EquipoFairPlay.fromJson(item));
        } else if (item is Map) {
          fpList.add(EquipoFairPlay.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return EstadisticasTorneo(
      vallaMenosVencida: parseEquipo(json['vallaMenosVencida']),
      equipoMasGoleador: parseEquipo(json['equipoMasGoleador']),
      mejorDiferenciaGol: parseEquipo(json['mejorDiferenciaGol']),
      menosAmarillas: parseEquipo(json['menosAmarillas']),
      menosRojas: parseEquipo(json['menosRojas']),
      goleador: parseGoleador(json['goleador']),
      fairPlay: fpList,
    );
  }
}

class EquipoEstadistica {
  final String nombre;
  final String sigla;
  final int partidosJugados;
  final int golesFavor;
  final int golesContra;
  final int diferenciaGol;
  final int amarillas;
  final int rojas;

  const EquipoEstadistica({
    required this.nombre,
    required this.sigla,
    this.partidosJugados = 0,
    this.golesFavor = 0,
    this.golesContra = 0,
    this.diferenciaGol = 0,
    this.amarillas = 0,
    this.rojas = 0,
  });

  factory EquipoEstadistica.fromJson(Map<String, dynamic> json) {
    return EquipoEstadistica(
      nombre: json['nombre']?.toString().trim() ?? 'Sin equipo',
      sigla: json['sigla']?.toString().trim() ?? '',
      partidosJugados: TextUtils.toInt(json['partidosJugados']),
      golesFavor: TextUtils.toInt(json['golesFavor']),
      golesContra: TextUtils.toInt(json['golesContra']),
      diferenciaGol: TextUtils.toInt(json['diferenciaGol']),
      amarillas: TextUtils.toInt(json['amarillas']),
      rojas: TextUtils.toInt(json['rojas']),
    );
  }
}

class GoleadorEstadistica {
  final String nombres;
  final String apellidos;
  final String equipoNombre;
  final int goles;
  final String? fotoJugador;

  const GoleadorEstadistica({
    required this.nombres,
    required this.apellidos,
    required this.equipoNombre,
    this.goles = 0,
    this.fotoJugador,
  });

  factory GoleadorEstadistica.fromJson(Map<String, dynamic> json) {
    return GoleadorEstadistica(
      nombres: json['nombres']?.toString().trim() ?? '',
      apellidos: json['apellidos']?.toString().trim() ?? '',
      equipoNombre: json['equipoNombre']?.toString().trim() ?? 'Sin equipo',
      goles: TextUtils.toInt(json['goles']),
      fotoJugador: json['fotoJugador']?.toString().trim(),
    );
  }

  String get nombreCompleto => '$nombres $apellidos'.trim();
}

class EquipoFairPlay {
  final String nombre;
  final int partidosJugados;
  final int amarillas;
  final int rojas;
  final int puntosFairPlay;

  const EquipoFairPlay({
    required this.nombre,
    this.partidosJugados = 0,
    this.amarillas = 0,
    this.rojas = 0,
    this.puntosFairPlay = 0,
  });

  factory EquipoFairPlay.fromJson(Map<String, dynamic> json) {
    return EquipoFairPlay(
      nombre: json['nombre']?.toString().trim() ?? 'Sin equipo',
      partidosJugados: TextUtils.toInt(json['partidosJugados']),
      amarillas: TextUtils.toInt(json['amarillas']),
      rojas: TextUtils.toInt(json['rojas']),
      puntosFairPlay: TextUtils.toInt(json['puntosFairPlay']),
    );
  }
}
