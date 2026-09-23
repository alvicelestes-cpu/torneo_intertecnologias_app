import 'partido.dart';

class PartidoDetalle {
  final Partido partido;
  final PartidoResumen? resumen;

  const PartidoDetalle({
    required this.partido,
    this.resumen,
  });

  factory PartidoDetalle.fromJson(Map<String, dynamic> json) {
    final partidoJson = json['partido'] is Map<String, dynamic>
        ? json['partido'] as Map<String, dynamic>
        : (json['partido'] is Map ? Map<String, dynamic>.from(json['partido']) : json);

    final resumenJson = json['resumen'] is Map<String, dynamic>
        ? json['resumen'] as Map<String, dynamic>
        : (json['resumen'] is Map ? Map<String, dynamic>.from(json['resumen']) : null);

    return PartidoDetalle(
      partido: Partido.fromJson(partidoJson),
      resumen: resumenJson != null ? PartidoResumen.fromJson(resumenJson) : null,
    );
  }
}

class PartidoResumen {
  final List<dynamic> golesLocal;
  final List<dynamic> golesVisitante;
  final List<dynamic> tarjetasLocal;
  final List<dynamic> tarjetasVisitante;

  const PartidoResumen({
    this.golesLocal = const [],
    this.golesVisitante = const [],
    this.tarjetasLocal = const [],
    this.tarjetasVisitante = const [],
  });

  factory PartidoResumen.fromJson(Map<String, dynamic> json) {
    return PartidoResumen(
      golesLocal: json['golesLocal'] is List ? json['golesLocal'] as List : const [],
      golesVisitante: json['golesVisitante'] is List ? json['golesVisitante'] as List : const [],
      tarjetasLocal: json['tarjetasLocal'] is List ? json['tarjetasLocal'] as List : const [],
      tarjetasVisitante: json['tarjetasVisitante'] is List ? json['tarjetasVisitante'] as List : const [],
    );
  }
}
