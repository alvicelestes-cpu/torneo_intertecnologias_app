import 'package:flutter/material.dart';
import '../models/importacion_historial_item.dart';
import '../services/equipos_service.dart';
import 'importacion_detalle_modal.dart';

class ImportarPlanillaHistorialView extends StatefulWidget {
  final int torneoId;
  final String? torneoNombre;
  final String? token;
  final EquiposService? equiposService;

  const ImportarPlanillaHistorialView({
    super.key,
    required this.torneoId,
    this.torneoNombre,
    this.token,
    this.equiposService,
  });

  @override
  State<ImportarPlanillaHistorialView> createState() => _ImportarPlanillaHistorialViewState();
}

class _ImportarPlanillaHistorialViewState extends State<ImportarPlanillaHistorialView> {
  late final EquiposService _equiposService;
  List<ImportacionHistorialItem> _items = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _equiposService = widget.equiposService ?? EquiposService();
    _cargarHistorial();
  }

  @override
  void didUpdateWidget(covariant ImportarPlanillaHistorialView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.torneoId != widget.torneoId) {
      _cargarHistorial();
    }
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final items = await _equiposService.obtenerHistorialImportaciones(
        torneoId: widget.torneoId,
        campeonatoId: widget.torneoId,
        token: widget.token,
      );

      if (mounted) {
        setState(() {
          _items = items;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo cargar el historial: $e';
          _cargando = false;
        });
      }
    }
  }

  Color _obtenerColorBadge(String estado) {
    switch (estado) {
      case 'Éxito':
        return const Color(0xFF15803D);
      case 'Éxito con alertas':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFFDC2626);
    }
  }

  String _formatearFecha(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;

    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando historial de importaciones...', style: TextStyle(color: Colors.blueGrey)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarHistorial,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No hay importaciones registradas para este torneo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              Text(
                'Cada vez que importes una planilla Excel o Google Sheets, el registro y sus estadísticas quedarán guardados aquí automáticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _cargarHistorial,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra superior de acciones
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${_items.length} ${_items.length == 1 ? "importación registrada" : "importaciones registradas"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                key: const Key('btn_refrescar_historial'),
                onPressed: _cargarHistorial,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refrescar',
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Listado de importaciones
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: _items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final item = _items[i];
            return _buildHistorialCard(context, item, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildHistorialCard(BuildContext context, ImportacionHistorialItem item, bool isMobile) {
    final estadoColor = _obtenerColorBadge(item.estadoVisual);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => ImportacionDetalleModal.show(
          context,
          item: item,
          torneoNombre: widget.torneoNombre,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Fecha, Archivo y Badge de Estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.description_outlined, color: Colors.blueGrey.shade700, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nombreArchivo,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatearFecha(item.fechaImportacion)}${item.usuarioNombre != null ? " • Por: ${item.usuarioNombre}" : ""}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge Estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: estadoColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item.estadoVisual,
                      style: TextStyle(
                        color: estadoColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chips de Métricas Cuantitativas
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildMetricChip(
                    Icons.table_rows_outlined,
                    '${item.filasProcesadas} filas',
                    Colors.grey.shade800,
                    Colors.grey.shade100,
                  ),
                  _buildMetricChip(
                    Icons.person_add_alt_1,
                    '${item.jugadoresRegistrados} inscritos',
                    const Color(0xFF15803D),
                    const Color(0xFFDCFCE7),
                  ),
                  if (item.jugadoresOmitidos > 0)
                    _buildMetricChip(
                      Icons.person_off_outlined,
                      '${item.jugadoresOmitidos} omitidos',
                      const Color(0xFFD97706),
                      const Color(0xFFFEF3C7),
                    ),
                  if (item.equiposCreados > 0)
                    _buildMetricChip(
                      Icons.group_add_outlined,
                      '${item.equiposCreados} eq. nuevos',
                      Colors.indigo.shade700,
                      Colors.indigo.shade50,
                    ),
                  if (item.alertasCantidad > 0)
                    _buildMetricChip(
                      Icons.warning_amber_rounded,
                      '${item.alertasCantidad} alertas',
                      const Color(0xFFB45309),
                      const Color(0xFFFFFBEB),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Botón inferior para abrir detalle
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver detalle completo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }
}
