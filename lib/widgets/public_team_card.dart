import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/equipo.dart';
import 'team_logo_avatar.dart';

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
    const maxPlantilla = 20;
    final cant = equipo.cantidadJugadores;
    final porcentaje = min(1.0, cant / maxPlantilla);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: teamColor.withAlpha(90),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BARRA SUPERIOR VIBRANTE CON COLOR REAL DEL EQUIPO
            Container(
              height: 5,
              color: teamColor,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // LOGO CON BORDE DEL COLOR DEL EQUIPO
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: teamColor,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: teamColor.withAlpha(40),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TeamLogoAvatar(
                          logoUrl: equipo.logo,
                          teamName: equipo.nombre,
                          sigla: equipo.sigla,
                          size: 46,
                          borderRadius: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // NOMBRE + SIGLA
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipo.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16.5,
                                color: Color(0xFF0D233A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (equipo.sigla.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: teamColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: teamColor.withAlpha(120),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  equipo.sigla,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: teamColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.blueGrey.shade300,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 9),

                  // SECCIÓN DE PLANTILLA CON FLEX Y BADGE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.groups,
                              size: 18,
                              color: teamColor,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '$cant ${cant == 1 ? 'jugador' : 'jugadores'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$cant / $maxPlantilla',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: teamColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: teamColor.withAlpha(80), width: 0.8),
                            ),
                            child: Text(
                              '${(porcentaje * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: teamColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // BARRA DE PROGRESO DE PLANTILLA DESTACADA
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: porcentaje,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(teamColor),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // BOTÓN DE ACCIÓN
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: teamColor,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onTap,
                      icon: const Icon(Icons.people_alt_outlined, size: 17),
                      label: const Text(
                        'Ver jugadores',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
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
