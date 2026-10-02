import 'package:flutter/material.dart';
import '../models/reglamento_model.dart';

/// Servicio y catálogo extensible de reglamentos oficiales por torneo
class ReglamentoService {
  static final ReglamentoService _instance = ReglamentoService._internal();
  factory ReglamentoService() => _instance;
  ReglamentoService._internal();

  /// Registro de reglamentos por slug oficial del torneo
  static final Map<String, TorneoReglamento> _registry = {
    // 1. Torneo Banquita Los Altos (slug actual: torneo-demo)
    'torneo-demo': const TorneoReglamento(
      torneoSlug: 'torneo-demo',
      titulo: 'Reglamento Oficial',
      subtitulo: 'Torneo Banquita Los Altos',
      modalidad: 'Banquita 4 vs 4',
      chips: [
        ChipRegla(texto: '4 vs 4', icono: Icons.groups),
        ChipRegla(texto: 'Sin Arquero', icono: Icons.person_off),
        ChipRegla(texto: '2 tiempos de 15 min', icono: Icons.timer),
        ChipRegla(texto: 'Balón de Microfútbol', icono: Icons.sports_soccer),
        ChipRegla(texto: '3 Penales', icono: Icons.crisis_alert),
      ],
      secciones: [
        SeccionReglamento(
          numero: 1,
          titulo: 'Participantes',
          icono: Icons.groups,
          articulos: [
            '4 jugadores por equipo en cancha.',
            'No hay arquero.',
            'Suplentes ilimitados.',
            'Cambios ilimitados.',
          ],
        ),
        SeccionReglamento(
          numero: 2,
          titulo: 'Cancha',
          icono: Icons.crop_landscape,
          articulos: [
            '20 metros de largo x 10 metros de ancho.',
            'Líneas bien delimitadas.',
          ],
        ),
        SeccionReglamento(
          numero: 3,
          titulo: 'Porterías',
          icono: Icons.sports_soccer,
          articulos: [
            '90 cm de alto x 70 cm de ancho.',
            'Pueden variar ligeramente según el torneo.',
          ],
        ),
        SeccionReglamento(
          numero: 4,
          titulo: 'Balón',
          icono: Icons.sports_volleyball,
          articulos: [
            'Balón de microfútbol.',
          ],
        ),
        SeccionReglamento(
          numero: 5,
          titulo: 'Duración del Partido',
          icono: Icons.timer,
          articulos: [
            '2 tiempos de 15 minutos.',
            'Descanso de 5 minutos.',
          ],
        ),
        SeccionReglamento(
          numero: 6,
          titulo: 'Área o "Bomba"',
          icono: Icons.warning_amber_rounded,
          destacada: true,
          alertaEspecial:
              'Prohibida la permanencia y defender apoyándose de portería o redes. Mano deliberada en el área sanciona penal.',
          articulos: [
            'No se puede permanecer dentro del área.',
            'No se puede apoyar en la portería.',
            'No se permite defender apoyándose de las redes.',
            'Los goles marcados desde dentro del área no son válidos.',
            'Si un jugador toca deliberadamente el balón dentro de esa zona para evitar un gol, se sancionará con penal.',
          ],
        ),
        SeccionReglamento(
          numero: 7,
          titulo: 'Saque Lateral',
          icono: Icons.arrow_forward,
          articulos: [
            'Se realiza con el pie.',
          ],
        ),
        SeccionReglamento(
          numero: 8,
          titulo: 'Faltas',
          icono: Icons.front_hand,
          articulos: [
            'Se aplica reglamento de microfútbol.',
            'El torneo puede implementar faltas acumulativas y tiro libre directo.',
          ],
        ),
        SeccionReglamento(
          numero: 9,
          titulo: 'Penal o "Pena Máxima"',
          icono: Icons.crisis_alert,
          articulos: [
            'Se cobra desde el punto medio de la cancha.',
            'Sin arquero.',
          ],
        ),
        SeccionReglamento(
          numero: 10,
          titulo: 'Tarjetas',
          icono: Icons.style,
          articulos: [
            'Amarilla y roja según gravedad de la falta.',
          ],
        ),
        SeccionReglamento(
          numero: 11,
          titulo: 'Empate en Fase Eliminatoria',
          icono: Icons.balance,
          articulos: [
            'Se define mediante 3 cobros de penal.',
          ],
        ),
        SeccionReglamento(
          numero: 12,
          titulo: 'Puntuación en Fase de Grupos',
          icono: Icons.table_chart,
          articulos: [
            'Victoria: 3 puntos.',
            'Empate: 1 punto.',
            'Derrota: 0 puntos.',
          ],
        ),
        SeccionReglamento(
          numero: 13,
          titulo: 'Desempates en Fase de Grupos',
          icono: Icons.format_list_numbered,
          articulos: [
            '1. Mayor número de puntos.',
            '2. Diferencia de goles.',
            '3. Mayor número de goles a favor.',
            '4. Enfrentamiento directo.',
            '5. Sorteo.',
          ],
        ),
        SeccionReglamento(
          numero: 14,
          titulo: 'W.O. / No Presentación',
          icono: Icons.cancel_presentation,
          destacada: true,
          alertaEspecial:
              'Derrota por marcador de 3-0 y posible retiro/exclusión definitiva del torneo.',
          articulos: [
            'Equipo que no se presente pierde 3-0.',
            'Puede ser retirado del torneo.',
          ],
        ),
        SeccionReglamento(
          numero: 15,
          titulo: 'Disposiciones Finales',
          icono: Icons.gavel,
          articulos: [
            'El comité organizador resolverá situaciones no contempladas.',
            'El comportamiento dentro y fuera de la cancha es responsabilidad de los equipos.',
            'La participación implica aceptación total del reglamento.',
          ],
        ),
      ],
    ),
  };

  /// Verifica si existe un reglamento registrado para el slug del torneo
  bool tieneReglamento(String? slug) {
    if (slug == null || slug.trim().isEmpty) return false;
    final normalized = slug.trim().toLowerCase();
    return _registry.containsKey(normalized);
  }

  /// Retorna el reglamento oficial registrado para el slug especificado.
  /// Si el torneo no tiene reglamento registrado, retorna null (nunca fallback a otro torneo).
  TorneoReglamento? getReglamentoPorSlug(String? slug) {
    if (slug == null || slug.trim().isEmpty) return null;
    final normalized = slug.trim().toLowerCase();
    return _registry[normalized];
  }
}
