class ResumenImportacion {
  final bool exito;
  final String mensaje;
  final int torneoId;
  final String torneoNombre;
  final int equiposCreados;
  final int equiposExistentes;
  final int jugadoresRegistrados;
  final int filasProcesadas;
  final List<String> alertas;
  final List<DetalleEquipoImportado> equiposDetalle;

  const ResumenImportacion({
    required this.exito,
    required this.mensaje,
    this.torneoId = 0,
    this.torneoNombre = '',
    this.equiposCreados = 0,
    this.equiposExistentes = 0,
    this.jugadoresRegistrados = 0,
    this.filasProcesadas = 0,
    this.alertas = const [],
    this.equiposDetalle = const [],
  });

  factory ResumenImportacion.fromJson(Map<String, dynamic> json) {
    final alertasList = json['alertas'];
    final equiposList = json['equiposDetalle'];

    return ResumenImportacion(
      exito: json['exito'] == true,
      mensaje: json['mensaje']?.toString() ?? '',
      torneoId: (json['torneoId'] as num?)?.toInt() ?? 0,
      torneoNombre: json['torneoNombre']?.toString() ?? '',
      equiposCreados: (json['equiposCreados'] as num?)?.toInt() ?? 0,
      equiposExistentes: (json['equiposExistentes'] as num?)?.toInt() ?? 0,
      jugadoresRegistrados: (json['jugadoresRegistrados'] as num?)?.toInt() ?? 0,
      filasProcesadas: (json['filasProcesadas'] as num?)?.toInt() ?? 0,
      alertas: alertasList is List
          ? alertasList.map((e) => e.toString()).toList()
          : const [],
      equiposDetalle: equiposList is List
          ? equiposList
              .map((e) => DetalleEquipoImportado.fromJson(
                    e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
    );
  }
}

class DetalleEquipoImportado {
  final int id;
  final String nombre;
  final bool fueCreado;
  final int jugadoresAgregados;

  const DetalleEquipoImportado({
    required this.id,
    required this.nombre,
    required this.fueCreado,
    required this.jugadoresAgregados,
  });

  factory DetalleEquipoImportado.fromJson(Map<String, dynamic> json) {
    return DetalleEquipoImportado(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      fueCreado: json['fueCreado'] == true,
      jugadoresAgregados: (json['jugadoresAgregados'] as num?)?.toInt() ?? 0,
    );
  }
}
