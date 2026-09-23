import '../core/utils/text_utils.dart';
import 'partido.dart';

class Jornada {
  final int numero;
  final int cantidadPartidos;
  final int partidosFinalizados;
  final int partidosProgramados;
  final int partidosCancelados;
  final int partidosConFecha;
  final int partidosSinFecha;
  final String estado;
  final List<Partido> partidos;

  const Jornada({
    required this.numero,
    this.cantidadPartidos = 0,
    this.partidosFinalizados = 0,
    this.partidosProgramados = 0,
    this.partidosCancelados = 0,
    this.partidosConFecha = 0,
    this.partidosSinFecha = 0,
    this.estado = 'PROGRAMADA',
    this.partidos = const [],
  });

  factory Jornada.fromJson(Map<String, dynamic> json) {
    final rawPartidos = json['partidos'];
    final listaPartidos = <Partido>[];
    if (rawPartidos is List) {
      for (final p in rawPartidos) {
        if (p is Map<String, dynamic>) {
          listaPartidos.add(Partido.fromJson(p));
        } else if (p is Map) {
          listaPartidos.add(Partido.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }

    final num = TextUtils.toInt(json['jornada'] ?? json['numeroJornada'] ?? json['numero']);
    final totalPartidos = json['cantidadPartidos'] != null
        ? TextUtils.toInt(json['cantidadPartidos'])
        : listaPartidos.length;

    return Jornada(
      numero: num,
      cantidadPartidos: totalPartidos,
      partidosFinalizados: TextUtils.toInt(json['partidosFinalizados']),
      partidosProgramados: TextUtils.toInt(json['partidosProgramados']),
      partidosCancelados: TextUtils.toInt(json['partidosCancelados']),
      partidosConFecha: TextUtils.toInt(json['partidosConFecha']),
      partidosSinFecha: TextUtils.toInt(json['partidosSinFecha']),
      estado: json['estado']?.toString().trim() ?? 'PROGRAMADA',
      partidos: listaPartidos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jornada': numero,
      'cantidadPartidos': cantidadPartidos,
      'partidosFinalizados': partidosFinalizados,
      'partidosProgramados': partidosProgramados,
      'partidosCancelados': partidosCancelados,
      'partidosConFecha': partidosConFecha,
      'partidosSinFecha': partidosSinFecha,
      'estado': estado,
      'partidos': partidos.map((p) => p.toJson()).toList(),
    };
  }
}

class JornadasResponse {
  final int cantidadJornadas;
  final List<Jornada> jornadas;

  const JornadasResponse({
    required this.cantidadJornadas,
    required this.jornadas,
  });

  factory JornadasResponse.fromJson(Map<String, dynamic> json) {
    final rawJornadas = json['jornadas'];
    final lista = <Jornada>[];
    if (rawJornadas is List) {
      for (final j in rawJornadas) {
        if (j is Map<String, dynamic>) {
          lista.add(Jornada.fromJson(j));
        } else if (j is Map) {
          lista.add(Jornada.fromJson(Map<String, dynamic>.from(j)));
        }
      }
    }

    final total = json['cantidadJornadas'] != null
        ? TextUtils.toInt(json['cantidadJornadas'])
        : lista.length;

    return JornadasResponse(
      cantidadJornadas: total,
      jornadas: lista,
    );
  }
}
