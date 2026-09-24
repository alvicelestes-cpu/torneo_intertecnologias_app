import 'package:flutter/material.dart';

import '../core/utils/date_utils.dart';
import '../models/partido.dart';
import 'public_partido_row.dart';

class PublicJornadaAccordion extends StatefulWidget {
  final int numeroJornada;
  final String fase;
  final String? tituloPersonalizado;
  final String? fecha;
  final int cantidadPartidos;
  final List<Partido> partidos;
  final bool initiallyExpanded;
  final bool esPendiente;
  final String? mensajePendiente;
  final void Function(Partido partido)? onPartidoTap;

  const PublicJornadaAccordion({
    super.key,
    required this.numeroJornada,
    this.fase = 'PRIMERA FASE',
    this.tituloPersonalizado,
    this.fecha,
    required this.cantidadPartidos,
    required this.partidos,
    this.initiallyExpanded = false,
    this.esPendiente = false,
    this.mensajePendiente,
    this.onPartidoTap,
  });

  @override
  State<PublicJornadaAccordion> createState() => _PublicJornadaAccordionState();
}

class _PublicJornadaAccordionState extends State<PublicJornadaAccordion> {
  late bool _expanded;
  final ScrollController _tableScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PublicJornadaAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  String _obtenerFechaJornada() {
    if (widget.esPendiente) {
      return 'Por definir (Al concluir fase previa)';
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    width: 40,
                    height: 40,
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
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Título, fase y fecha (dispuesto verticalmente para no desbordar en móvil)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.fase.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _expanded ? Colors.white70 : const Color(0xFF64748B),
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          widget.tituloPersonalizado ?? 'Jornada ${widget.numeroJornada}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _expanded ? Colors.white : const Color(0xFF0D233A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_expanded) ...[
                              const Icon(
                                Icons.calendar_today,
                                size: 11,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                fechaJornada,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: _expanded ? Colors.white.withAlpha(230) : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Badge de cantidad de partidos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                      widget.esPendiente
                          ? (cantPartidos > 0 ? '$cantPartidos por definir' : 'Pendiente')
                          : '$cantPartidos ${cantPartidos == 1 ? 'partido' : 'partidos'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _expanded ? Colors.white : const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Flecha arriba/abajo
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: _expanded ? Colors.white : const Color(0xFF1976D2),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // Tabla de partidos expandible con scroll horizontal fluido y aviso en móvil
          if (_expanded)
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.mensajePendiente != null && widget.mensajePendiente!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFBFDBFE), width: 1.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Color(0xFF1D4ED8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.mensajePendiente!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.partidos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          widget.esPendiente
                              ? 'Enfrentamientos pendientes de definición por clasificación.'
                              : 'No hay partidos registrados en esta jornada.',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 730;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isNarrow)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                color: const Color(0xFFF1F5F9),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.swap_horiz, size: 14, color: Color(0xFF64748B)),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Desliza para ver la tabla completa',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF64748B),
                                          fontStyle: FontStyle.italic,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Scrollbar(
                              controller: _tableScrollController,
                              thumbVisibility: isNarrow,
                              child: SingleChildScrollView(
                                controller: _tableScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
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
                        );
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
