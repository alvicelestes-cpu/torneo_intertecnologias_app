import 'package:flutter/material.dart';

import '../core/utils/date_utils.dart';
import '../models/partido.dart';
import 'status_chip.dart';
import 'team_logo_avatar.dart';

class PublicPartidoRow extends StatelessWidget {
  final int index;
  final Partido partido;
  final VoidCallback? onTap;

  const PublicPartidoRow({
    super.key,
    required this.index,
    required this.partido,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fechaHora = AppDateUtils.formatDateTime(
      partido.fechaHora,
      defaultText: 'Fecha por definir',
    );

    final isFinalizado = partido.estado.toUpperCase().trim() == 'FINALIZADO';
    final marcadorTexto = partido.marcador.isNotEmpty && partido.marcador != '-'
        ? partido.marcador
        : (isFinalizado && partido.golesLocal != null && partido.golesVisitante != null
            ? '${partido.golesLocal} - ${partido.golesVisitante}'
            : 'VS');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: index.isOdd ? Colors.white : const Color(0xFFFBFDFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 520;

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // # de partido
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D233A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Equipo Local
                      Expanded(
                        child: Row(
                          children: [
                            TeamLogoAvatar(
                              logoUrl: partido.equipoLocalLogo,
                              teamName: partido.equipoLocalNombre,
                              sigla: partido.equipoLocalSigla,
                              size: 24,
                              borderRadius: 6,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                partido.equipoLocalNombre,
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

                      // Pastilla marcador azul oscuro
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D233A),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          marcadorTexto,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      // Equipo Visitante
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                partido.equipoVisitanteNombre,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            TeamLogoAvatar(
                              logoUrl: partido.equipoVisitanteLogo,
                              teamName: partido.equipoVisitanteNombre,
                              sigla: partido.equipoVisitanteSigla,
                              size: 24,
                              borderRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Fila secundaria: Fecha/hora y estado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 13, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                fechaHora,
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (partido.cancha != null && partido.cancha!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          partido.cancha!,
                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                        ),
                      ],
                      const SizedBox(width: 8),
                      StatusChip(
                        status: partido.estado,
                        fontSize: 10,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      ),
                    ],
                  ),
                ],
              );
            }

            // Diseño para pantallas medianas y anchas
            return Row(
              children: [
                // #
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D233A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Local
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      TeamLogoAvatar(
                        logoUrl: partido.equipoLocalLogo,
                        teamName: partido.equipoLocalNombre,
                        sigla: partido.equipoLocalSigla,
                        size: 30,
                        borderRadius: 6,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          partido.equipoLocalNombre,
                          style: const TextStyle(
                            fontSize: 14,
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

                // Marcador en pastilla azul oscuro
                Container(
                  constraints: const BoxConstraints(minWidth: 84),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D233A),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    marcadorTexto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                // Visitante
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          partido.equipoVisitanteNombre,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TeamLogoAvatar(
                        logoUrl: partido.equipoVisitanteLogo,
                        teamName: partido.equipoVisitanteNombre,
                        sigla: partido.equipoVisitanteSigla,
                        size: 30,
                        borderRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Estado
                StatusChip(
                  status: partido.estado,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                ),

                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
