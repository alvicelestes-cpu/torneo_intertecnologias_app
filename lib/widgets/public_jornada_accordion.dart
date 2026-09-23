import 'package:flutter/material.dart';

import '../core/utils/date_utils.dart';
import '../models/partido.dart';
import 'public_partido_row.dart';

class PublicJornadaAccordion extends StatefulWidget {
  final int numeroJornada;
  final String fase;
  final String? fecha;
  final int cantidadPartidos;
  final List<Partido> partidos;
  final bool initiallyExpanded;
  final void Function(Partido partido)? onPartidoTap;

  const PublicJornadaAccordion({
    super.key,
    required this.numeroJornada,
    this.fase = 'PRIMERA FASE',
    this.fecha,
    required this.cantidadPartidos,
    required this.partidos,
    this.initiallyExpanded = false,
    this.onPartidoTap,
  });

  @override
  State<PublicJornadaAccordion> createState() => _PublicJornadaAccordionState();
}

class _PublicJornadaAccordionState extends State<PublicJornadaAccordion> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant PublicJornadaAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  String _obtenerFechaJornada() {
    if (widget.fecha != null && widget.fecha!.isNotEmpty) {
      return widget.fecha!;
    }
    for (final p in widget.partidos) {
      if (p.fechaHora != null && p.fechaHora!.isNotEmpty) {
        final formatted = AppDateUtils.formatDate(p.fechaHora);
        if (formatted.isNotEmpty && formatted != 'Sin fecha') {
          return formatted;
        }
      }
    }
    return 'Por definir';
  }

  @override
  Widget build(BuildContext context) {
    final fechaJornada = _obtenerFechaJornada();
    final cantPartidos = widget.cantidadPartidos > 0
        ? widget.cantidadPartidos
        : widget.partidos.length;

    return Card(
      elevation: 2.5,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CABECERA DEPORTIVA AZUL DEGRADADA
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D233A),
                    Color(0xFF1565C0),
                    Color(0xFF1E88E5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    right: 48,
                    top: -12,
                    bottom: -12,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.12,
                        child: Icon(Icons.sports_soccer, size: 84, color: Colors.white),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // FASE + JORNADA UNIFICADA ("PRIMERA FASE - Jornada X")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(35),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('⚽ ', style: TextStyle(fontSize: 10)),
                                  Text(
                                    widget.fase.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '-',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Jornada ${widget.numeroJornada}',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 250),
                        turns: _expanded ? 0.5 : 0.0,
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // FECHA Y CANTIDAD DE PARTIDOS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 13, color: Colors.white70),
                          const SizedBox(width: 5),
                          Text(
                            fechaJornada,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$cantPartidos ${cantPartidos == 1 ? 'partido' : 'partidos'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),

          // CONTENIDO EXPANDIBLE: LISTA DE PARTIDOS
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: widget.partidos.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          'No hay partidos registrados en esta jornada.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.partidos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final partido = widget.partidos[index];
                        return PublicPartidoRow(
                          index: index + 1,
                          partido: partido,
                          onTap: widget.onPartidoTap != null
                              ? () => widget.onPartidoTap!(partido)
                              : null,
                        );
                      },
                    ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
