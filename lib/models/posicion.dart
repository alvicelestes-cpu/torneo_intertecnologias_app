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
    };
  }

  String get diferenciaGolTexto => TextUtils.formatGoalDifference(dg);
  String get iniciales => TextUtils.getInitials(equipo, sigla: sigla);
}
