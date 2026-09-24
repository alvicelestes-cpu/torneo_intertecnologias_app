import 'gol.dart';
import 'partido.dart';
import 'tarjeta.dart';

class PartidoDetalle {
  final Partido partido;
  final PartidoResumen? resumen;
  final List<Gol> goles;
  final List<Tarjeta> tarjetas;

  const PartidoDetalle({
    required this.partido,
    this.resumen,
    this.goles = const [],
    this.tarjetas = const [],
  });

  factory PartidoDetalle.fromJson(Map<String, dynamic> json) {
    final rawPartido = json['partido'];
    final Map<String, dynamic> partidoMap = rawPartido is Map
        ? Map<String, dynamic>.from(rawPartido)
        : Map<String, dynamic>.from(json);

    // Propagar goles y tarjetas desde el nivel raíz si están disponibles
    if (json['goles'] is List && partidoMap['goles'] == null) {
      partidoMap['goles'] = json['goles'];
    }
    if (json['tarjetas'] is List && partidoMap['tarjetas'] == null) {
      partidoMap['tarjetas'] = json['tarjetas'];
    }

    final parsedPartido = Partido.fromJson(partidoMap);

    final rawResumen = json['resumen'];
    final resumen = rawResumen is Map ? PartidoResumen.fromJson(Map<String, dynamic>.from(rawResumen)) : null;

    return PartidoDetalle(
      partido: parsedPartido,
      resumen: resumen,
      goles: parsedPartido.goles,
      tarjetas: parsedPartido.tarjetas,
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
