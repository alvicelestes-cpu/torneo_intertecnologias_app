import '../core/utils/text_utils.dart';

class Posicion {
  final int posicion;
  final int? equipoId;
  final String equipo;
  final String sigla;
  final String? logo;
  final int pj;
  final int pg;
  final int pe;
  final int pp;
  final int gf;
  final int gc;
  final int dg;
  final int pts;
  final bool puntoInvisible;
  final int? posicionPrimeraFase;

  const Posicion({
    required this.posicion,
    this.equipoId,
    required this.equipo,
    required this.sigla,
    this.logo,
    required this.pj,
    required this.pg,
    required this.pe,
    required this.pp,
    required this.gf,
    required this.gc,
    required this.dg,
    required this.pts,
    this.puntoInvisible = false,
    this.posicionPrimeraFase,
  });

  factory Posicion.fromJson(Map<String, dynamic> json) {
    final equipo = json['equipo']?.toString().trim() ?? 'Sin equipo';
    final sigla = json['sigla']?.toString().trim() ?? '';
    String? logo = json['logo']?.toString().trim() ?? json['logoEquipo']?.toString().trim();
    if (logo == null || logo.isEmpty || logo == 'string' || logo == 'null') {
      final upperNombre = equipo.toUpperCase();
      final upperSigla = sigla.toUpperCase();
      if (upperNombre.contains('RACING') || upperSigla == 'TRF' || upperSigla == 'TR') {
        logo = 'assets/logos/tienda_racing.png';
      } else {
        logo = null;
      }
    }

    return Posicion(
      posicion: TextUtils.toInt(json['posicion']),
      equipoId: json['equipoId'] != null ? TextUtils.toInt(json['equipoId']) : null,
      equipo: equipo,
      sigla: sigla,
      logo: logo,
      pj: TextUtils.toInt(json['pj']),
      pg: TextUtils.toInt(json['pg']),
      pe: TextUtils.toInt(json['pe']),
      pp: TextUtils.toInt(json['pp']),
      gf: TextUtils.toInt(json['gf']),
      gc: TextUtils.toInt(json['gc']),
      dg: TextUtils.toInt(json['dg']),
      pts: TextUtils.toInt(json['pts'] ?? json['puntos']),
      puntoInvisible: json['puntoInvisible'] == true,
      posicionPrimeraFase: json['posicionPrimeraFase'] != null
          ? TextUtils.toInt(json['posicionPrimeraFase'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posicion': posicion,
      if (equipoId != null) 'equipoId': equipoId,
      'equipo': equipo,
      'sigla': sigla,
      if (logo != null) 'logo': logo,
      'pj': pj,
      'pg': pg,
      'pe': pe,
      'pp': pp,
      'gf': gf,
      'gc': gc,
      'dg': dg,
      'pts': pts,
      'puntoInvisible': puntoInvisible,
      if (posicionPrimeraFase != null) 'posicionPrimeraFase': posicionPrimeraFase,
    };
  }

  String get diferenciaGolTexto => TextUtils.formatGoalDifference(dg);
  String get iniciales => TextUtils.getInitials(equipo, sigla: sigla);
}

/// Respuesta estructurada con la clasificación desagregada por fases y cuadrangulares
class PosicionesFases {
  final List<Posicion> primeraFase;
  final bool existeSegundaRonda;
  final List<Posicion> grupoA;
  final List<Posicion> grupoB;

  const PosicionesFases({
    required this.primeraFase,
    required this.existeSegundaRonda,
    required this.grupoA,
    required this.grupoB,
  });

  factory PosicionesFases.fromJson(Map<String, dynamic> json) {
    final rawPF = json['primeraFase'];
    final rawGA = json['grupoA'];
    final rawGB = json['grupoB'];

    return PosicionesFases(
      primeraFase: (rawPF is List)
          ? rawPF.map((e) => Posicion.fromJson(Map<String, dynamic>.from(e))).toList()
          : <Posicion>[],
      existeSegundaRonda: json['existeSegundaRonda'] == true,
      grupoA: (rawGA is List)
          ? rawGA.map((e) => Posicion.fromJson(Map<String, dynamic>.from(e))).toList()
          : <Posicion>[],
      grupoB: (rawGB is List)
          ? rawGB.map((e) => Posicion.fromJson(Map<String, dynamic>.from(e))).toList()
          : <Posicion>[],
    );
  }
}
