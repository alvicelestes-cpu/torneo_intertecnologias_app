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
    return '24/08/2026';
  }

  @override
  Widget build(BuildContext context) {
    final fechaJornada = _obtenerFechaJornada();
    final cantPartidos = widget.cantidadPartidos > 0
        ? widget.cantidadPartidos
        : widget.partidos.length;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera interactiva del acordeón
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _expanded ? null : Colors.white,
                gradient: _expanded
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF0072CE),
                          Color(0xFF0D6EFD),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Icono de calendario en badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _expanded
                          ? Colors.white.withAlpha(45)
                          : const Color(0xFFEAF2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.calendar_month,
                      color: _expanded ? Colors.white : const Color(0xFF1976D2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Título, fase y fecha
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.fase.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _expanded ? Colors.white70 : const Color(0xFF64748B),
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Jornada ${widget.numeroJornada}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _expanded ? Colors.white : const Color(0xFF0D233A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (_expanded) ...[
                              const Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              fechaJornada,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _expanded ? Colors.white.withAlpha(230) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Badge de cantidad de partidos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _expanded
                          ? Colors.white.withAlpha(35)
                          : const Color(0xFFEAF2FD),
                      borderRadius: BorderRadius.circular(16),
                      border: _expanded
                          ? Border.all(color: Colors.white30, width: 0.8)
                          : null,
                    ),
                    child: Text(
                      '$cantPartidos ${cantPartidos == 1 ? 'partido' : 'partidos'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _expanded ? Colors.white : const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Flecha arriba/abajo
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: _expanded ? Colors.white : const Color(0xFF1976D2),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Tabla de partidos expandible
          if (_expanded)
            Container(
              color: Colors.white,
              child: widget.partidos.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No hay partidos registrados en esta jornada.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 730,
                        child: Column(
                          children: [
                            // Cabecera de la tabla de partidos
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 34,
                                    child: Text(
                                      '#',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 175,
                                    child: Text(
                                      'Local',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'Marcador',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 175,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 12),
                                      child: Text(
                                        'Visitante',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 135,
                                    child: Text(
                                      'Fecha',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 95,
                                    child: Text(
                                      'Estado',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Filas de partidos
                            ...List.generate(widget.partidos.length, (index) {
                              final partido = widget.partidos[index];
                              return PublicPartidoRow(
                                index: index + 1,
                                partido: partido,
                                onTap: widget.onPartidoTap != null
                                    ? () => widget.onPartidoTap!(partido)
                                    : null,
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
