import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torneo_intertecnologias_app/core/network/api_client.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/models/auth_user.dart';
import 'package:torneo_intertecnologias_app/models/campeonato.dart';

class MockHttpClient extends http.BaseClient {
  Uri? lastUri;
  Map<String, String>? lastHeaders;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastHeaders = request.headers;
    if (request is http.Request) {
      lastBody = request.body;
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode('{}')),
      200,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SessionManager().clearSession();
  });

  group('SessionManager Roles y Aislamiento', () {
    test('SUPERADMIN puede cambiar de campeonato libremente', () {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'super-token',
        usuario: 'superadmin',
        rol: 'SUPERADMIN',
        campeonatoId: 1,
      ));

      expect(session.isSuperAdmin, isTrue);
      expect(session.isAdmin, isFalse);
      expect(session.canChangeCampeonato, isTrue);

      session.selectCampeonatoById(2);
      expect(session.selectedCampeonatoId, equals(2));

      session.selectCampeonato(const Campeonato(
        id: 3,
        nombre: 'Torneo 3',
        slug: 'torneo-3',
      ));
      expect(session.selectedCampeonatoId, equals(3));
    });

    test('ADMIN queda restringido a su propio campeonato asignado y no puede cambiar', () {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'admin-token',
        usuario: 'admin_local',
        rol: 'ADMIN',
        campeonatoId: 2,
        campeonato: 'Torneo de Prueba 2027',
      ));

      expect(session.isSuperAdmin, isFalse);
      expect(session.isAdmin, isTrue);
      expect(session.canChangeCampeonato, isFalse);
      expect(session.selectedCampeonatoId, equals(2));

      // Intento de cambio no permitido
      session.selectCampeonatoById(1);
      expect(session.selectedCampeonatoId, equals(2));

      session.selectCampeonato(const Campeonato(
        id: 1,
        nombre: 'Torneo 1',
        slug: 'torneo-1',
      ));
      expect(session.selectedCampeonatoId, equals(2));
    });

    test('setCampeonatos selecciona primer activo si el guardado ya no existe o está inactivo', () {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'super-token',
        usuario: 'superadmin',
        rol: 'SUPERADMIN',
        campeonatoId: 99,
      ));

      final lista = [
        const Campeonato(id: 1, nombre: 'Activo 1', slug: 'act-1', activo: true, estado: 'ACTIVO'),
        const Campeonato(id: 2, nombre: 'Inactivo', slug: 'inact', activo: false, estado: 'INACTIVO'),
      ];

      session.setCampeonatos(lista);
      // Torneo 99 no existe en la lista, debe fallback al primero activo
      expect(session.selectedCampeonatoId, equals(1));
    });
  });

  group('ApiClient Propagación de campeonatoId', () {
    late MockHttpClient mockClient;
    late ApiClient apiClient;

    setUp(() {
      mockClient = MockHttpClient();
      apiClient = ApiClient(client: mockClient);
      SessionManager().selectCampeonatoById(2);
    });

    test('Anexa campeonatoId a endpoints de campeonato', () async {
      await apiClient.get('https://backend.app/api/equipos');
      expect(mockClient.lastUri?.queryParameters['campeonatoId'], equals('2'));

      await apiClient.get('https://backend.app/api/jugadores');
      expect(mockClient.lastUri?.queryParameters['campeonatoId'], equals('2'));

      await apiClient.get('https://backend.app/api/partidos');
      expect(mockClient.lastUri?.queryParameters['campeonatoId'], equals('2'));

      await apiClient.get('https://backend.app/api/jornadas');
      expect(mockClient.lastUri?.queryParameters['campeonatoId'], equals('2'));

      await apiClient.get('https://backend.app/api/posiciones');
      expect(mockClient.lastUri?.queryParameters['campeonatoId'], equals('2'));

      await apiClient.get('https://backend.app/api/estadisticas');
      expect(mockClient.lastUri?.queryParameters['campeonatoId'], equals('2'));

      await apiClient.get('https://backend.app/api/goles');
      expect(mockClient.lastUri?.queryParameters['campeonatoId'], equals('2'));

      await apiClient.get('https://backend.app/api/tarjetas');
      expect(mockClient.lastUri?.queryParameters['campeonatoId'], equals('2'));

      await apiClient.get('https://backend.app/api/goleadores');
      expect(mockClient.lastUri?.queryParameters['campeonatoId'], equals('2'));

      await apiClient.get('https://backend.app/api/torneo');
      expect(mockClient.lastUri?.queryParameters['campeonatoId'], equals('2'));
    });

    test('NO anexa campeonatoId a endpoints globales como auth y campeonatos', () async {
      await apiClient.post('https://backend.app/api/auth/login');
      expect(mockClient.lastUri?.queryParameters.containsKey('campeonatoId'), isFalse);

      await apiClient.get('https://backend.app/api/campeonatos');
      expect(mockClient.lastUri?.queryParameters.containsKey('campeonatoId'), isFalse);

      await apiClient.get('https://backend.app/api/campeonatos/1');
      expect(mockClient.lastUri?.queryParameters.containsKey('campeonatoId'), isFalse);
    });

    test('NO duplica campeonatoId si ya viene en la URL', () async {
      await apiClient.get('https://backend.app/api/posiciones?campeonatoId=1');
      expect(mockClient.lastUri?.queryParameters['campeonatoId'], equals('1'));
    });
  });
}
