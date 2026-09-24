import 'package:flutter/material.dart';

import '../core/utils/date_utils.dart';
import '../models/partido.dart';

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

  static Color getClubColor(String nombre, String? sigla) {
    final upper = '${nombre.toUpperCase()} ${sigla?.toUpperCase() ?? ''}';
    if (upper.contains('INPEC') || upper.contains(' IN ')) return const Color(0xFF0D47A1);
    if (upper.contains('DEP') || upper.contains('ELITE')) return const Color(0xFF689F38);
    if (upper.contains('CEM') || upper.contains('CEMENTEROS')) return const Color(0xFF2E7D32);
    if (upper.contains('TELEMATIK') || upper.contains(' TE ')) return const Color(0xFFE65100);
    if (upper.contains('GREMIO') || upper.contains(' GH ')) return const Color(0xFF0288D1);
    if (upper.contains('CONEXI') || upper.contains(' CD ')) return const Color(0xFF1976D2);
    if (upper.contains('TIGO') || upper.contains(' TI ')) return const Color(0xFFD32F2F);
    if (upper.contains('RACING') || upper.contains(' TR ')) return const Color(0xFF7B1FA2);

    final hash = nombre.hashCode.abs() % 6;
    const colors = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFFE65100),
      Color(0xFF7B1FA2),
      Color(0xFF00838F),
      Color(0xFFC2185B),
    ];
    return colors[hash];
  }

  static String getClubSigla(String nombre, String? sigla) {
    if (sigla != null && sigla.trim().isNotEmpty) {
      return sigla.trim();
    }
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    if (nombre.length >= 3) {
      return nombre.substring(0, 3).toUpperCase();
    }
    return nombre.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isFinalizado = partido.estado.toUpperCase().trim() == 'FINALIZADO';
    final esPorDefinir = partido.estado.toUpperCase().contains('DEFINIR') || partido.id <= 0;
    final marcadorTexto = partido.marcador.isNotEmpty && partido.marcador != '-'
        ? partido.marcador
        : (isFinalizado && partido.golesLocal != null && partido.golesVisitante != null
            ? '${partido.golesLocal} - ${partido.golesVisitante}'
            : (partido.golesLocal != null && partido.golesVisitante != null
                ? '${partido.golesLocal} - ${partido.golesVisitante}'
                : 'VS'));

    final fechaTexto = esPorDefinir
        ? 'Por definir'
        : AppDateUtils.formatDateTime(
            partido.fechaHora,
            defaultText: 'Por programar',
          );

    final localColor = getClubColor(partido.equipoLocalNombre, partido.equipoLocalSigla);
    final visitColor = getClubColor(partido.equipoVisitanteNombre, partido.equipoVisitanteSigla);

    final localSigla = getClubSigla(partido.equipoLocalNombre, partido.equipoLocalSigla);
    final visitSigla = getClubSigla(partido.equipoVisitanteNombre, partido.equipoVisitanteSigla);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
          ),
        ),
        child: Row(
          children: [
            // Columna 1: #
            SizedBox(
              width: 34,
              child: Text(
                '$index',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),

            // Columna 2: Local
            SizedBox(
              width: 175,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 24,
                    decoration: BoxDecoration(
                      color: localColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      localSigla,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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

            // Columna 3: Marcador
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0D233A),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                marcadorTexto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // Columna 4: Visitante
            SizedBox(
              width: 175,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Container(
                    width: 30,
                    height: 24,
                    decoration: BoxDecoration(
                      color: visitColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      visitSigla,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      partido.equipoVisitanteNombre,
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

            // Columna 5: Fecha
            SizedBox(
              width: 135,
              child: Text(
                fechaTexto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Columna 6: Estado
            SizedBox(
              width: 95,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isFinalizado
                        ? const Color(0xFFE8F5E9)
                        : (esPorDefinir ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFinalizado
                        ? 'FINALIZADO'
                        : (esPorDefinir
                            ? 'POR DEFINIR'
                            : partido.estado.toUpperCase().replaceAll('_', ' ')),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isFinalizado
                          ? const Color(0xFF2E7D32)
                          : (esPorDefinir ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
