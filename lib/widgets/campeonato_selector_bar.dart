import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/session/session_manager.dart';
import '../models/campeonato.dart';
import '../models/torneo_model.dart';
import '../services/torneo_config_service.dart';
import '../services/torneo_service.dart';

class CampeonatoSelectorBar extends StatefulWidget {
  final VoidCallback? onCampeonatoChanged;
  final TorneoService? torneoService;

  const CampeonatoSelectorBar({
    super.key,
    this.onCampeonatoChanged,
    this.torneoService,
  });

  @override
  State<CampeonatoSelectorBar> createState() => _CampeonatoSelectorBarState();
}

class _CampeonatoSelectorBarState extends State<CampeonatoSelectorBar> {
  late final TorneoService _torneoService;
  final SessionManager _sessionManager = SessionManager();
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _torneoService = widget.torneoService ?? TorneoService();
    _cargarCampeonatos();
  }

  Future<void> _cargarCampeonatos() async {
    if (_sessionManager.campeonatos.isNotEmpty) return;

    setState(() => _cargando = true);
    try {
      final list = await _torneoService.getCampeonatos();
      if (mounted) {
        _sessionManager.setCampeonatos(list);
      }
    } catch (_) {
      // Ignorar fallo de red silencioso para no bloquear el inicio
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirDialogoCrearTorneo() {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    int limiteJugadores = 14;
    int topGoleadoresMax = 10;
    bool tienePuntoInvisible = true;
    bool guardando = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: !guardando,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nuevo Torneo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // 1. Nombre del torneo (obligatorio)
                        const Text(
                          'Nombre del Torneo *',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('input_nombre_torneo'),
                          controller: nombreController,
                          enabled: !guardando,
                          decoration: InputDecoration(
                            hintText: 'Ej. Torneo Apertura 2026',
                            prefixIcon: const Icon(Icons.title, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'El nombre del torneo es obligatorio';
                            }
                            if (val.trim().length < 3) {
                              return 'El nombre debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // 2. Cupo de jugadores (slider/selector 10 a 25)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Cupo de jugadores por equipo:',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$limiteJugadores jugadores',
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          key: const Key('slider_cupo_jugadores'),
                          value: limiteJugadores.toDouble(),
                          min: 10,
                          max: 25,
                          divisions: 15,
                          label: '$limiteJugadores',
                          activeColor: AppColors.primary,
                          onChanged: guardando
                              ? null
                              : (val) {
                                  setDialogState(() {
                                    limiteJugadores = val.round();
                                  });
                                },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Mín. 10', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Por defecto: 14', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Máx. 25', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // 3. Top de goleadores (5, 10, 15)
                        const Text(
                          'Top de Goleadores (tabla pública):',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<int>(
                            key: const Key('segmented_top_goleadores'),
                            segments: const [
                              ButtonSegment(value: 5, label: Text('Top 5')),
                              ButtonSegment(value: 10, label: Text('Top 10')),
                              ButtonSegment(value: 15, label: Text('Top 15')),
                            ],
                            selected: {topGoleadoresMax},
                            onSelectionChanged: guardando
                                ? null
                                : (newSelection) {
                                    setDialogState(() {
                                      topGoleadoresMax = newSelection.first;
                                    });
                                  },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4. Switch de Ventaja Deportiva (Punto Invisible)
                        Card(
                          elevation: 0,
                          color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: SwitchListTile(
                            key: const Key('switch_punto_invisible'),
                            title: const Text(
                              'Ventaja Deportiva (Punto Invisible)',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: const Text(
                              'Aplica ventaja reglamentaria al mejor clasificado en instancias finales',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: tienePuntoInvisible,
                            activeThumbColor: AppColors.primary,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            onChanged: guardando
                                ? null
                                : (val) {
                                    setDialogState(() {
                                      tienePuntoInvisible = val;
                                    });
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('btn_cancelar_creacion_torneo'),
                  onPressed: guardando ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  key: const Key('btn_guardar_torneo'),
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            guardando = true;
                            errorMessage = null;
                          });

                          try {
                            final nombre = nombreController.text.trim();
                            final res = await _torneoService.crearTorneo(
                              nombre: nombre,
                              limiteJugadores: limiteJugadores,
                              tienePuntoInvisible: tienePuntoInvisible,
                              topGoleadoresMax: topGoleadoresMax,
                              token: _sessionManager.token,
                            );

                            final rawTorneo = res['torneo'] is Map<String, dynamic>
                                ? res['torneo'] as Map<String, dynamic>
                                : res;

                            final nuevoModel = TorneoModel.fromJson(rawTorneo);
                            final nuevoCampeonato = Campeonato(
                              id: nuevoModel.id,
                              nombre: nuevoModel.nombre,
                              slug: nuevoModel.slug,
                              activo: true,
                              publicado: true,
                              totalEquipos: 0,
                              totalPartidos: 0,
                            );

                            // Registrar y activar torneo en el contexto
                            _sessionManager.registrarNuevoTorneo(nuevoCampeonato);
                            TorneoConfigService().setLocalConfig(nuevoModel);

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (!mounted) return;
                            widget.onCampeonatoChanged?.call();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Torneo "$nombre" creado y activado exitosamente.',
                                ),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              guardando = false;
                              errorMessage = e.toString().replaceFirst('Exception: ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crear Torneo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _abrirSelectorModal() {
    if (!_sessionManager.canChangeCampeonato) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Seleccionar Torneo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Elige el campeonato a consultar (hasta 20 torneos independientes):',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              if (_sessionManager.isSuperAdmin) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('btn_crear_nuevo_torneo'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _abrirDialogoCrearTorneo();
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text(
                      '+ Crear Nuevo Torneo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: ListenableBuilder(
                  listenable: _sessionManager,
                  builder: (context, _) {
                    final allList = _sessionManager.campeonatos;
                    final isSuperAdmin = _sessionManager.isSuperAdmin;
                    final campeonatos = isSuperAdmin
                        ? allList.where((c) => c.estaActivo).toList()
                        : allList.where((c) => c.estaPublicado).toList();

                    if (campeonatos.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                _cargando
                                    ? 'Cargando torneos disponibles...'
                                    : 'Torneo Intertecnologías (Predeterminado)',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: campeonatos.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = campeonatos[index];
                        final isSelected = c.id == _sessionManager.selectedCampeonatoId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.primaryLight,
                            child: Text(
                              c.iniciales,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.nombre,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (!c.publicado) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber.shade700, width: 0.8),
                                  ),
                                  child: Text(
                                    'No publicado',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${c.totalEquipos} equipos • ${c.totalPartidos} partidos',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary)
                              : null,
                          onTap: () {
                            _sessionManager.selectCampeonato(c);
                            Navigator.pop(ctx);
                            widget.onCampeonatoChanged?.call();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sessionManager,
      builder: (context, _) {
        final nombreTorneo = _sessionManager.selectedCampeonatoNombre;
        final canChange = _sessionManager.canChangeCampeonato;

        return InkWell(
          onTap: canChange ? _abrirSelectorModal : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    nombreTorneo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                if (canChange) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
