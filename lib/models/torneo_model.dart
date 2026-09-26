class TorneoModel {
  final int id;
  final int organizacionId;
  final String organizacionNombre;
  final String nombre;
  final String slug;
  final int limiteJugadores;
  final bool tienePuntoInvisible;
  final int topGoleadoresMax;
  final bool activo;

  const TorneoModel({
    required this.id,
    required this.organizacionId,
    required this.organizacionNombre,
    required this.nombre,
    required this.slug,
    this.limiteJugadores = 14,
    this.tienePuntoInvisible = true,
    this.topGoleadoresMax = 10,
    this.activo = true,
  });

  /// Valores predeterminados oficiales del torneo con fallback seguro
  factory TorneoModel.defaults() {
    return const TorneoModel(
      id: 1,
      organizacionId: 1,
      organizacionNombre: 'CUN / Intertecnologías',
      nombre: 'Torneo Intertecnologías 2026',
      slug: 'intertecnologias',
      limiteJugadores: 14,
      tienePuntoInvisible: true,
      topGoleadoresMax: 10,
      activo: true,
    );
  }

  factory TorneoModel.fromJson(Map<String, dynamic> json) {
    return TorneoModel(
      id: (json['id'] as num?)?.toInt() ?? 1,
      organizacionId: (json['organizacionId'] as num?)?.toInt() ?? 1,
      organizacionNombre: json['organizacionNombre']?.toString() ?? 'CUN / Intertecnologías',
      nombre: json['nombre']?.toString() ?? 'Torneo Intertecnologías 2026',
      slug: json['slug']?.toString() ?? 'intertecnologias',
      limiteJugadores: (json['limiteJugadores'] as num?)?.toInt() ?? 14,
      tienePuntoInvisible: json['tienePuntoInvisible'] as bool? ?? true,
      topGoleadoresMax: (json['topGoleadoresMax'] as num?)?.toInt() ?? 10,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizacionId': organizacionId,
      'organizacionNombre': organizacionNombre,
      'nombre': nombre,
      'slug': slug,
      'limiteJugadores': limiteJugadores,
      'tienePuntoInvisible': tienePuntoInvisible,
      'topGoleadoresMax': topGoleadoresMax,
      'activo': activo,
    };
  }

  TorneoModel copyWith({
    int? id,
    int? organizacionId,
    String? organizacionNombre,
    String? nombre,
    String? slug,
    int? limiteJugadores,
    bool? tienePuntoInvisible,
    int? topGoleadoresMax,
    bool? activo,
  }) {
    return TorneoModel(
      id: id ?? this.id,
      organizacionId: organizacionId ?? this.organizacionId,
      organizacionNombre: organizacionNombre ?? this.organizacionNombre,
      nombre: nombre ?? this.nombre,
      slug: slug ?? this.slug,
      limiteJugadores: limiteJugadores ?? this.limiteJugadores,
      tienePuntoInvisible: tienePuntoInvisible ?? this.tienePuntoInvisible,
      topGoleadoresMax: topGoleadoresMax ?? this.topGoleadoresMax,
      activo: activo ?? this.activo,
    );
  }

  @override
  String toString() =>
      'TorneoModel(id: $id, nombre: $nombre, limiteJugadores: $limiteJugadores, tienePuntoInvisible: $tienePuntoInvisible, topGoleadoresMax: $topGoleadoresMax)';
}
