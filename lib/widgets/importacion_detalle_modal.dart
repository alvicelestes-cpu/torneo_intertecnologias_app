import 'package:flutter/material.dart';
import '../models/importacion_historial_item.dart';

class ImportacionDetalleModal extends StatelessWidget {
  final ImportacionHistorialItem item;
  final String? torneoNombre;

  const ImportacionDetalleModal({
    super.key,
    required this.item,
    this.torneoNombre,
  });

  static Future<void> show(
    BuildContext context, {
    required ImportacionHistorialItem item,
    String? torneoNombre,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ImportacionDetalleModal(
        item: item,
        torneoNombre: torneoNombre,
      ),
    );
  }

  Color _obtenerColorEstado() {
    switch (item.estadoVisual) {
      case 'Éxito':
        return const Color(0xFF15803D);
      case 'Éxito con alertas':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFFDC2626);
    }
  }

  IconData _obtenerIconoEstado() {
    switch (item.estadoVisual) {
      case 'Éxito':
        return Icons.check_circle_rounded;
      case 'Éxito con alertas':
        return Icons.warning_amber_rounded;
      default:
        return Icons.error_rounded;
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final colorEstado = _obtenerColorEstado();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalle de Importación',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID #${item.id} • ${_formatearFecha(item.fechaImportacion)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Contenido Scrolleable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de Estado General
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorEstado.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorEstado.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_obtenerIconoEstado(), color: colorEstado, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            item.estadoVisual,
                            style: TextStyle(
                              color: colorEstado,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Metadatos Clave
                    _buildInfoCard(context),
                    const SizedBox(height: 16),

                    // Grid de Métricas
                    const Text(
                      'Resumen Cuantitativo',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildMetricasGrid(context, isMobile),
                    const SizedBox(height: 20),

                    // Detalle de Equipos
                    if (item.equiposDetalle.isNotEmpty) ...[
                      const Text(
                        'Equipos Procesados',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...item.equiposDetalle.map((eq) => _buildEquipoTile(eq)),
                      const SizedBox(height: 20),
                    ],

                    // Alertas
                    if (item.alertas.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Alertas Registradas (${item.alertas.length})',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: item.alertas.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFFDE68A)),
                          itemBuilder: (ctx, i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    item.alertas[i],
                                    style: const TextStyle(color: Color(0xFF92400E), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Mensaje Informativo si existe
                    if (item.mensaje.isNotEmpty) ...[
                      const Text(
                        'Mensaje del Sistema',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          item.mensaje,
                          style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Botón inferior
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        children: [
          _buildInfoRow('Archivo / Origen', item.nombreArchivo, Icons.description_outlined),
          const Divider(height: 16),
          _buildInfoRow('Torneo', torneoNombre != null && torneoNombre!.isNotEmpty ? '$torneoNombre (ID ${item.torneoId})' : 'Torneo ID ${item.torneoId}', Icons.emoji_events_outlined),
          if (item.usuarioNombre != null && item.usuarioNombre!.isNotEmpty) ...[
            const Divider(height: 16),
            _buildInfoRow('Importado por', item.usuarioNombre!, Icons.person_outline),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey.shade700),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricasGrid(BuildContext context, bool isMobile) {
    final items = [
      _Metrica('Filas Leídas', '${item.filasProcesadas}', Colors.blue.shade700, Icons.table_rows_outlined),
      _Metrica('Inscritos', '${item.jugadoresRegistrados}', const Color(0xFF15803D), Icons.person_add_alt_1),
      _Metrica('Omitidos', '${item.jugadoresOmitidos}', const Color(0xFFD97706), Icons.person_off_outlined),
      _Metrica('Cédulas Duplicadas', '${item.duplicadosDocumento}', Colors.purple.shade700, Icons.copy_outlined),
      _Metrica('Conflictos Dorsal', '${item.conflictosDorsal}', Colors.deepOrange.shade700, Icons.numbers_outlined),
      _Metrica('Equipos Nuevos', '${item.equiposCreados}', Colors.indigo.shade700, Icons.group_add_outlined),
      _Metrica('Equipos Reutilizados', '${item.equiposExistentes}', Colors.teal.shade700, Icons.groups_outlined),
    ];

    if (isMobile) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((m) => SizedBox(width: 140, child: _buildMetricaCard(m))).toList(),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossCount = constraints.maxWidth > 500 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: 2.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (ctx, i) => _buildMetricaCard(items[i]),
        );
      },
    );
  }

  Widget _buildMetricaCard(_Metrica m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: m.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: m.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(m.icon, color: m.color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  m.valor,
                  style: TextStyle(color: m.color, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  m.titulo,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipoTile(dynamic eq) {
    final fueCreado = eq.fueCreado == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            fueCreado ? Icons.add_business_rounded : Icons.check_circle_outline,
            color: fueCreado ? const Color(0xFF0F766E) : const Color(0xFF15803D),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              eq.nombre ?? 'Equipo',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: fueCreado ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              fueCreado ? 'Nuevo Equipo' : 'Equipo Existente',
              style: TextStyle(
                fontSize: 11,
                color: fueCreado ? const Color(0xFF0369A1) : Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${eq.jugadoresAgregados} jugadores',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF15803D)),
          ),
        ],
      ),
    );
  }
}

class _Metrica {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icon;

  const _Metrica(this.titulo, this.valor, this.color, this.icon);
}
