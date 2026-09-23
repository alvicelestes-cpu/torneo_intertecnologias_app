import 'dart:math';

import 'package:flutter/material.dart';

import '../models/equipo.dart';

class PublicTeamCard extends StatelessWidget {
  final Equipo equipo;
  final VoidCallback? onTap;

  const PublicTeamCard({
    super.key,
    required this.equipo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = equipo.color;
    const maxPlantilla = 23;
    final cant = equipo.cantidadJugadores;
    final porcentaje = min(1.0, cant / maxPlantilla);

    // Obtener iniciales para el avatar circular
    String iniciales = equipo.sigla.trim();
    if (iniciales.isEmpty) {
      final partes = equipo.nombre.trim().split(RegExp(r'\s+'));
      if (partes.length >= 2) {
        iniciales = '${partes[0][0]}${partes[1][0]}'.toUpperCase();
      } else if (equipo.nombre.isNotEmpty) {
        iniciales = equipo.nombre.substring(0, min(2, equipo.nombre.length)).toUpperCase();
      } else {
        iniciales = 'EQ';
      }
    } else if (iniciales.length > 3) {
      iniciales = iniciales.substring(0, 2).toUpperCase();
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Borde superior distintivo con el color del equipo
            Container(
              height: 5,
              color: teamColor,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fila de Avatar + Nombre + Sigla + Chevron
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar circular con iniciales/sigla del equipo
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: teamColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: teamColor.withAlpha(50),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          iniciales,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nombre del club y badge de sigla
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipo.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xFF0D233A),
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (equipo.sigla.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: teamColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: teamColor.withAlpha(90),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  equipo.sigla,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: teamColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Capacidad: "X/23 jugadores" a la izquierda y porcentaje "XX%" a la derecha
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$cant/$maxPlantilla jugadores',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(porcentaje * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Barra de progreso horizontal con el color principal del club
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: porcentaje,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(teamColor),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botón inferior ancho "Ver jugadores" con icono de usuario
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF6FF),
                        foregroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: onTap,
                      icon: const Icon(Icons.person, size: 17),
                      label: const Text(
                        'Ver jugadores',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
