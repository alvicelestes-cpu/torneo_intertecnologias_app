import 'dart:math';

import 'package:flutter/material.dart';

import '../models/equipo.dart';
import '../services/torneo_config_service.dart';
import 'team_logo_avatar.dart';

class PublicTeamCard extends StatelessWidget {
  static int get maxPlantilla => TorneoConfigService().limiteJugadores;
  final Equipo equipo;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCarnets;
  final VoidCallback? onDelete;

  const PublicTeamCard({
    super.key,
    required this.equipo,
    this.onTap,
    this.onEdit,
    this.onCarnets,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = equipo.color;
    final maxPlantilla = PublicTeamCard.maxPlantilla;
    final cant = equipo.cantidadJugadores;
    final porcentaje = min(1.0, cant / maxPlantilla);

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
                  // Fila de Avatar + Nombre + Sigla + Chevron / Editar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Escudo oficial del equipo (o fallback de iniciales y color del club)
                      TeamLogoAvatar(
                        logoUrl: equipo.logo,
                        teamName: equipo.nombre,
                        sigla: equipo.sigla,
                        teamColor: teamColor,
                        size: 44,
                        isCircle: true,
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
                      if (onEdit != null) ...[
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                          tooltip: 'Editar escudo y equipo',
                          onPressed: onEdit,
                        ),
                        if (onDelete != null) const SizedBox(width: 4),
                      ],
                      if (onDelete != null)
                        IconButton(
                          key: Key('btn_eliminar_equipo_${equipo.id}'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                          tooltip: 'Eliminar equipo',
                          onPressed: onDelete,
                        )
                      else if (onEdit == null)
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Capacidad: "$cant/14 jugadores" a la izquierda y porcentaje "XX%" a la derecha
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

                  // Botón inferior: "Ver jugadores", "🪪 Carnets" y "Escudo" si es admin
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          SizedBox(
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
                              icon: const Icon(Icons.person, size: 16),
                              label: const Text(
                                'Ver jugadores',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                          if (onCarnets != null) ...[
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                key: Key('btn_carnets_equipo_${equipo.id}'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0F766E),
                                  side: const BorderSide(color: Color(0xFF99F6E4)),
                                  backgroundColor: const Color(0xFFF0FDFA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: onCarnets,
                                icon: const Icon(Icons.badge_outlined, size: 16),
                                label: const Text(
                                  '🪪 Carnets',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (onEdit != null) ...[
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                key: Key('btn_escudo_equipo_${equipo.id}'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0D233A),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: onEdit,
                                icon: const Icon(Icons.shield_outlined, size: 16),
                                label: const Text(
                                  'Escudo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (onDelete != null) ...[
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                key: Key('btn_eliminar_equipo_bottom_${equipo.id}'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: onDelete,
                                icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                                label: const Text(
                                  'Eliminar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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
