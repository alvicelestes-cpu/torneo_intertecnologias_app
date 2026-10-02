import 'package:flutter/material.dart';

/// Representa una etiqueta o chip de resumen reglamentario rápido
class ChipRegla {
  final String texto;
  final IconData? icono;

  const ChipRegla({
    required this.texto,
    this.icono,
  });
}

/// Representa una sección oficial del reglamento
class SeccionReglamento {
  final int numero;
  final String titulo;
  final IconData icono;
  final List<String> articulos;
  final bool destacada;
  final String? alertaEspecial;

  const SeccionReglamento({
    required this.numero,
    required this.titulo,
    required this.icono,
    required this.articulos,
    this.destacada = false,
    this.alertaEspecial,
  });
}

/// Representa el reglamento oficial completo de un torneo
class TorneoReglamento {
  final String torneoSlug;
  final String titulo;
  final String subtitulo;
  final String modalidad;
  final List<ChipRegla> chips;
  final List<SeccionReglamento> secciones;

  const TorneoReglamento({
    required this.torneoSlug,
    required this.titulo,
    required this.subtitulo,
    required this.modalidad,
    required this.chips,
    required this.secciones,
  });
}
