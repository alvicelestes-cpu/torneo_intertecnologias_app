class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  // Campeonatos (Multitorneo)
  static const String campeonatos = '$baseUrl/api/campeonatos';
  static String campeonatoDetalle(int campeonatoId) =>
      '$baseUrl/api/campeonatos/$campeonatoId';

  // Torneo Resumen
  static const String torneoResumen = '$baseUrl/api/torneo';

  // Auth
  static const String login = '$baseUrl/api/auth/login';

  // Equipos
  static const String equipos = '$baseUrl/api/equipos';
  static String equipoJugadores(int equipoId) =>
      '$baseUrl/api/equipos/$equipoId/jugadores';

  // Jugadores
  static const String jugadores = '$baseUrl/api/jugadores';
  static String jugadorDetalle(int jugadorId) =>
      '$baseUrl/api/jugadores/$jugadorId';

  // Partidos
  static const String partidos = '$baseUrl/api/partidos';
  static String partidoDetalle(int partidoId) =>
      '$baseUrl/api/partidos/$partidoId';
  static String partidoResultado(int partidoId) =>
      '$baseUrl/api/partidos/$partidoId/resultado';
  static String partidoReabrir(int partidoId) =>
      '$baseUrl/api/partidos/$partidoId/reabrir';

  // Goles
  static const String goles = '$baseUrl/api/goles';
  static String golesPartido(int partidoId) =>
      '$baseUrl/api/goles/partido/$partidoId';
  static String golDetalle(int golId) => '$baseUrl/api/goles/$golId';

  // Tarjetas
  static const String tarjetas = '$baseUrl/api/tarjetas';
  static String tarjetasPartido(int partidoId) =>
      '$baseUrl/api/tarjetas/partido/$partidoId';
  static String tarjetaDetalle(int tarjetaId) =>
      '$baseUrl/api/tarjetas/$tarjetaId';

  // Jornadas
  static const String jornadas = '$baseUrl/api/jornadas';
  static String jornadaDetalle(int numeroJornada) =>
      '$baseUrl/api/jornadas/$numeroJornada';

  // Estadísticas & Tablas
  static const String posiciones = '$baseUrl/api/posiciones';
  static const String goleadores = '$baseUrl/api/goleadores';
  static const String estadisticas = '$baseUrl/api/estadisticas';

  // Headers por defecto con soporte multitorneo
  static Map<String, String> defaultHeaders({String? token, int? campeonatoId}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (campeonatoId != null && campeonatoId > 0) {
      headers['X-Campeonato-Id'] = campeonatoId.toString();
    }
    return headers;
  }
}
