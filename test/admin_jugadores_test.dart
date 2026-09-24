import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:torneo_intertecnologias_app/core/network/api_client.dart';
import 'package:torneo_intertecnologias_app/core/utils/image_utils.dart';
import 'package:torneo_intertecnologias_app/models/jugador.dart';
import 'package:torneo_intertecnologias_app/services/jugadores_service.dart';

void main() {
  group('Jugador Model - Corrección Visual de Equipo y Mapa', () {
    test('Parsea correctamente equipo anidado como Map sin imprimir mapa crudo', () {
      final json = {
        'id': 165,
        'nombres': 'Carlos',
        'apellidos': 'Valderrama',
        'equipoId': 5,
        'equipo': {
          'id': 5,
          'nombre': 'TIENDA RACING FC',
          'sigla': 'TRF',
          'colorPrincipal': '#003366',
        },
        'fechaNacimiento': '1985-05-10',
        'estado': 'ACTIVO',
      };

      final jugador = Jugador.fromJson(json);

      expect(jugador.id, 165);
      expect(jugador.equipoId, 5);
      expect(jugador.equipoNombre, 'TIENDA RACING FC');
      expect(jugador.equipoSigla, 'TRF');
      expect(jugador.equipoColor, '#003366');
      expect(jugador.equipoNombre!.contains('{'), isFalse);
    });

    test('Descarta equipoNombre si es un mapa serializado como texto', () {
      final json = {
        'id': 166,
        'nombres': 'James',
        'apellidos': 'Rodriguez',
        'equipoId': 3,
        'equipoNombre': '{id: 3, nombre: DEPORTIVO ELITE, sigla: DEL}',
        'fechaNacimiento': '1991-07-12',
      };

      final jugador = Jugador.fromJson(json);

      expect(jugador.equipoNombre, isNull);
    });

    test('Parsea equipo plano cuando equipoNombre viene como texto limpio', () {
      final json = {
        'id': 167,
        'nombres': 'Radamel',
        'apellidos': 'Falcao',
        'equipoId': 2,
        'equipoNombre': 'CEMENTEROS FC',
        'equipoSigla': 'CEM',
        'fechaNacimiento': '1986-02-10',
      };

      final jugador = Jugador.fromJson(json);

      expect(jugador.equipoNombre, 'CEMENTEROS FC');
      expect(jugador.equipoSigla, 'CEM');
    });
  });

  group('ImageUtils - Soporte de Data URI Base64 y Blob', () {
    test('Preserva data URI en Base64 sin anteponer baseUrl', () {
      const dataUri = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...';
      final resolved = ImageUtils.resolveUrl(dataUri);
      expect(resolved, dataUri);
    });

    test('Preserva URLs blob sin anteponer baseUrl', () {
      const blobUrl = 'blob:http://localhost:5000/guid-1234';
      final resolved = ImageUtils.resolveUrl(blobUrl);
      expect(resolved, blobUrl);
    });

    test('Resuelve rutas relativas con baseUrl', () {
      const relative = '/uploads/jugadores/foto.jpg';
      final resolved = ImageUtils.resolveUrl(relative);
      expect(resolved, startsWith('http'));
      expect(resolved, endsWith(relative));
    });
  });

  group('JugadoresService - createJugador', () {
    test('createJugador envía POST y retorna Jugador creado', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.contains('/api/jugadores')) {
          final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          expect(requestBody['nombres'], 'Juan');
          expect(requestBody['apellidos'], 'Perez');
          expect(requestBody['equipoId'], 4);

          return http.Response(
            jsonEncode({
              'mensaje': 'Jugador creado correctamente.',
              'jugador': {
                'id': 200,
                'equipoId': 4,
                'equipo': 'LOS MISMOS FC',
                'nombres': 'Juan',
                'apellidos': 'Perez',
                'numeroCamiseta': 10,
                'fechaNacimiento': '1995-04-12',
                'estado': 'ACTIVO',
                'fotoJugador': '/uploads/jugadores/new.jpg',
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final service = JugadoresService(apiClient: apiClient);

      final nuevoJugador = await service.createJugador({
        'equipoId': 4,
        'nombres': 'Juan',
        'apellidos': 'Perez',
        'numeroCamiseta': 10,
        'fechaNacimiento': '1995-04-12',
      });

      expect(nuevoJugador.id, 200);
      expect(nuevoJugador.nombres, 'Juan');
      expect(nuevoJugador.apellidos, 'Perez');
      expect(nuevoJugador.numeroCamiseta, 10);
      expect(nuevoJugador.fotoJugador, '/uploads/jugadores/new.jpg');
    });
  });
}
