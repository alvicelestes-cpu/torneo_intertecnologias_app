import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_intertecnologias_app/core/utils/date_utils.dart';
import 'package:torneo_intertecnologias_app/core/utils/text_utils.dart';
import 'package:torneo_intertecnologias_app/models/equipo.dart';
import 'package:torneo_intertecnologias_app/models/goleador.dart';
import 'package:torneo_intertecnologias_app/models/jugador.dart';

void main() {
  group('AppDateUtils - Cálculo de edad', () {
    test('Calcula la edad correctamente para fecha pasada', () {
      final now = DateTime.now();
      final birthYear = now.year - 24;
      final birthMonth = now.month;
      final birthDay = now.day > 1 ? now.day - 1 : 1;
      final fechaStr = '$birthYear-${birthMonth.toString().padLeft(2, '0')}-${birthDay.toString().padLeft(2, '0')}';

      final age = AppDateUtils.calculateAge(fechaStr);
      expect(age, equals(24));
    });

    test('Devuelve null para fechas nulas o vacías', () {
      expect(AppDateUtils.calculateAge(null), isNull);
      expect(AppDateUtils.calculateAge(''), isNull);
      expect(AppDateUtils.calculateAge('fecha-invalida'), isNull);
    });
  });

  group('TextUtils - Parseo de colores de equipo', () {
    test('Parsea colores en formato hexadecimal con y sin #', () {
      final c1 = TextUtils.parseColor('#FF0000');
      expect(c1, equals(const Color(0xFFFF0000)));

      final c2 = TextUtils.parseColor('00FF00');
      expect(c2, equals(const Color(0xFF00FF00)));

      final cDefault = TextUtils.parseColor(null);
      expect(cDefault, equals(const Color(0xFF1976D2)));
    });
  });

  group('Modelo Equipo - Atributos deportivos', () {
    test('Parsea colorPrincipal y cantidadJugadores desde json', () {
      final equipo = Equipo.fromJson({
        'id': 10,
        'nombre': 'Halcones FC',
        'sigla': 'HFC',
        'colorPrincipal': '#FF5722',
        'cantidadJugadores': 18,
      });

      expect(equipo.id, equals(10));
      expect(equipo.nombre, equals('Halcones FC'));
      expect(equipo.sigla, equals('HFC'));
      expect(equipo.colorPrincipal, equals('#FF5722'));
      expect(equipo.color, equals(const Color(0xFFFF5722)));
      expect(equipo.cantidadJugadores, equals(18));
    });

    test('copyWith preserva y actualiza cantidadJugadores', () {
      const original = Equipo(
        id: 1,
        nombre: 'Leones',
        sigla: 'LEO',
        cantidadJugadores: 5,
      );

      final updated = original.copyWith(cantidadJugadores: 15);
      expect(updated.cantidadJugadores, equals(15));
      expect(updated.nombre, equals('Leones'));
    });
  });

  group('Modelo Jugador - Ficha y estadísticas deportivas', () {
    test('Parsea goles, tarjetas y calcula edad', () {
      final jugador = Jugador.fromJson({
        'id': 42,
        'equipoId': 5,
        'nombres': 'Carlos',
        'apellidos': 'Gómez',
        'fechaNacimiento': '2000-01-15',
        'goles': 7,
        'amarillas': 2,
        'rojas': 1,
      });

      expect(jugador.id, equals(42));
      expect(jugador.nombreCompleto, equals('Carlos Gómez'));
      expect(jugador.goles, equals(7));
      expect(jugador.amarillas, equals(2));
      expect(jugador.rojas, equals(1));
      expect(jugador.edad, isNotNull);
      expect(jugador.edad! >= 24, isTrue);
    });

    test('copyWith actualiza goles y tarjetas correctamente', () {
      const j = Jugador(
        id: 1,
        equipoId: 2,
        nombres: 'Andrés',
        apellidos: 'Pérez',
      );

      final updated = j.copyWith(goles: 3, amarillas: 1, rojas: 0);
      expect(updated.goles, equals(3));
      expect(updated.amarillas, equals(1));
      expect(updated.rojas, equals(0));
    });
  });

  group('Modelo Goleador - Clasificación y atributos deportivos', () {
    test('Parsea siglaEquipo y numeroCamiseta correctamente', () {
      final g = Goleador.fromJson({
        'posicion': 1,
        'jugadorId': 101,
        'nombres': 'Mateo',
        'apellidos': 'Silva',
        'equipo': 'Tigres',
        'siglaEquipo': 'TIG',
        'numeroCamiseta': 9,
        'goles': 12,
      });

      expect(g.posicion, equals(1));
      expect(g.jugadorId, equals(101));
      expect(g.nombreCompleto, equals('Mateo Silva'));
      expect(g.siglaEquipo, equals('TIG'));
      expect(g.numeroCamiseta, equals(9));
      expect(g.goles, equals(12));
    });

    test('copyWith preserva y actualiza foto y sigla', () {
      const g = Goleador(
        posicion: 2,
        jugadorId: 102,
        nombres: 'Lucas',
        apellidos: 'Díaz',
        equipo: 'Águilas',
        goles: 8,
      );

      final updated = g.copyWith(
        siglaEquipo: 'AGU',
        numeroCamiseta: 10,
        fotoJugador: 'https://example.com/foto.jpg',
      );

      expect(updated.siglaEquipo, equals('AGU'));
      expect(updated.numeroCamiseta, equals(10));
      expect(updated.fotoJugador, equals('https://example.com/foto.jpg'));
      expect(updated.goles, equals(8));
    });
  });
}

