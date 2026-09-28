import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/fixture_utils.dart';
import 'core/utils/ui_helpers.dart';
import 'models/jornada.dart';
import 'models/partido.dart';
import 'models/posicion.dart';
import 'partido_detalle_page.dart';
import 'services/jornadas_service.dart';
import 'services/partidos_service.dart';
import 'services/torneo_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/boton_generar_fase.dart';
import 'widgets/public_jornada_accordion.dart';
import 'widgets/public_navbar.dart';

class JornadasPage extends StatefulWidget {
  final String? token;
  final JornadasService? jornadasService;
  final PartidosService? partidosService;
  final TorneoService? torneoService;

  const JornadasPage({
    super.key,
    this.token,
    this.jornadasService,
    this.partidosService,
    this.torneoService,
  });

  @override
  State<JornadasPage> createState() => _JornadasPageState();
}

class _JornadasPageState extends State<JornadasPage> {
  late final JornadasService _jornadasService;
  late final PartidosService _partidosService;
  late final TorneoService _torneoService;

  bool cargando = true;
  String? error;
  int cantidadJornadas = 0;
  List<Jornada> jornadas = [];
  List<Partido> todosPartidos = [];
  List<FixtureSection> seccionesFixture = [];
  List<Posicion> posiciones = [];
  String faseSeleccionada = 'TODAS';

  @override
  void initState() {
    super.initState();
    _jornadasService = widget.jornadasService ?? JornadasService();
    _partidosService = widget.partidosService ?? PartidosService();
    _torneoService = widget.torneoService ?? TorneoService();
    SessionManager().addListener(_onSessionChanged);
    cargarJornadas();
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) cargarJornadas();
  }

  bool get _esAdmin {
    final session = SessionManager();
    final tieneTokenValido = (widget.token != null && widget.token!.isNotEmpty) || session.token.isNotEmpty;
    return tieneTokenValido && session.hasAdminAccess;
  }

  Future<void> cargarJornadas() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resultados = await Future.wait([
        _jornadasService.getJornadas(token: widget.token),
        _partidosService.getPartidos(token: widget.token).catchError((_) => <Partido>[]),
        _torneoService.getPosiciones(token: widget.token).catchError((_) => <Posicion>[]),
      ]);

      final resJornadas = resultados[0] as JornadasResponse;
      final listaPartidos = resultados[1] as List<Partido>;
      final listaPosiciones = resultados[2] as List<Posicion>;

      final sections = FixtureUtils.buildTournamentSections(
        partidos: listaPartidos,
        jornadas: resJornadas.jornadas,
        posiciones: listaPosiciones,
      );

      // Ordenar jornadas ascendente
      final sortedJornadas = List<Jornada>.from(resJornadas.jornadas)
        ..sort((a, b) => a.numero.compareTo(b.numero));

      if (mounted) {
        setState(() {
          cantidadJornadas = resJornadas.cantidadJornadas;
          jornadas = sortedJornadas;
          todosPartidos = listaPartidos;
          seccionesFixture = sections;
          posiciones = listaPosiciones;
        });
      }
    } on AppException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'No se pudo conectar con el servidor.');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _abrirPartido(int partidoId) async {
    if (partidoId <= 0) {
      UiHelpers.showInfo(
        context,
        'Este enfrentamiento se encuentra pendiente de definición por clasificados.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartidoDetallePage(
          partidoId: partidoId,
          token: widget.token,
        ),
      ),
    );

    if (mounted) {
      cargarJornadas();
    }
  }

  String _obtenerNombreFase(String key) {
    switch (key) {
      case TournamentPhase.primeraFase:
      case 'PRIMERA_FASE':
        return 'Primera Fase';
      case TournamentPhase.segundaRonda:
      case 'SEGUNDA_RONDA':
        return 'Cuadrangulares';
      case TournamentPhase.terceraRonda:
      case 'CUARTOS':
        return 'Cuartos de Final';
      case TournamentPhase.cuartaRonda:
      case 'SEMIFINAL':
        return 'Semifinales';
      case TournamentPhase.quintaRonda:
      case 'FINAL':
        return 'Gran Final';
      default:
        return 'la Fase';
    }
  }

  String _mapFaseToBackend(String key) {
    final k = key.toUpperCase().trim();
    if (k.contains('PRIMER')) return 'PRIMERA_FASE';
    if (k.contains('SEGUNDA') || k.contains('CUADRANGULAR')) return 'SEGUNDA_RONDA';
    if (k.contains('TERCERA') || k.contains('CUARTO')) return 'CUARTOS';
    if (k.contains('CUARTA') || k.contains('SEMI')) return 'SEMIFINAL';
    if (k.contains('QUINTA') || k.contains('FINAL')) return 'FINAL';
    return 'PRIMERA_FASE';
  }

  String _mapBackendToTournamentPhase(String backendFase) {
    final f = backendFase.toUpperCase();
    if (f.contains('PRIMER')) return TournamentPhase.primeraFase;
    if (f.contains('SEGUNDA') || f.contains('CUADRANGULAR')) return TournamentPhase.segundaRonda;
    if (f.contains('CUARTO') || f.contains('TERCERA')) return TournamentPhase.terceraRonda;
    if (f.contains('SEMI') || f.contains('CUARTA')) return TournamentPhase.cuartaRonda;
    if (f.contains('FINAL') || f.contains('QUINTA')) return TournamentPhase.quintaRonda;
    return 'TODAS';
  }

  Future<void> _abrirModalGenerarFixture([String? faseInicial]) async {
    String faseSeleccionadaModal = _mapFaseToBackend(faseInicial ?? 'PRIMERA_FASE');
    DateTime fechaSeleccionada = DateTime.now().add(const Duration(days: 7));
    fechaSeleccionada = DateTime(fechaSeleccionada.year, fechaSeleccionada.month, fechaSeleccionada.day, 14, 0);
    String modalidad = 'Ida';
    bool sobrescribir = true;
    bool cargandoModal = false;
    bool cargandoPreview = false;
    String? errorModal;
    List<dynamic>? partidosPreview;

    await showDialog(
      context: context,
      barrierDismissible: !cargandoModal,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtxInner, setDialogState) {
            final fDateStr =
                '${fechaSeleccionada.day.toString().padLeft(2, '0')}/${fechaSeleccionada.month.toString().padLeft(2, '0')}/${fechaSeleccionada.year} ${fechaSeleccionada.hour.toString().padLeft(2, '0')}:${fechaSeleccionada.minute.toString().padLeft(2, '0')}';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generador de Fixture',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sorteo y emparejamientos automáticos',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (errorModal != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorModal!,
                                  style: TextStyle(color: Colors.red.shade800, fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Badge de torneo activo
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events_outlined, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Torneo: ${SessionManager().selectedCampeonatoNombre}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Selector de Fase
                      const Text(
                        'Fase a Sortear / Generar:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: const Key('dropdown_fase_fixture'),
                        initialValue: faseSeleccionadaModal,
                        isExpanded: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.timeline, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PRIMERA_FASE',
                            child: Text('1. Primera Fase (Todos contra Todos)'),
                          ),
                          DropdownMenuItem(
                            value: 'SEGUNDA_RONDA',
                            child: Text('2. Cuadrangulares Semifinales (Grupos A y B)'),
                          ),
                          DropdownMenuItem(
                            value: 'CUARTOS',
                            child: Text('3. Cuartos de Final (1° vs 8°, 2° vs 7°, etc.)'),
                          ),
                          DropdownMenuItem(
                            value: 'SEMIFINAL',
                            child: Text('4. Semifinales'),
                          ),
                          DropdownMenuItem(
                            value: 'FINAL',
                            child: Text('5. Gran Final y 3° Puesto'),
                          ),
                        ],
                        onChanged: cargandoModal
                            ? null
                            : (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    faseSeleccionadaModal = val;
                                    partidosPreview = null;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 14),

                      // Fecha y Hora de Inicio
                      const Text(
                        'Fecha y Hora de Inicio:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        key: const Key('btn_seleccionar_fecha_fixture'),
                        onTap: cargandoModal
                            ? null
                            : () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: fechaSeleccionada,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (d != null && mounted) {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(
                                      hour: fechaSeleccionada.hour,
                                      minute: fechaSeleccionada.minute,
                                    ),
                                  );
                                  if (t != null) {
                                    setDialogState(() {
                                      fechaSeleccionada = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                                      partidosPreview = null;
                                    });
                                  }
                                }
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text(fDateStr, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              const Icon(Icons.edit, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Modalidad (Solo Ida / Ida y Vuelta)
                      const Text(
                        'Modalidad de Encuentros:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            key: const Key('chip_modalidad_ida'),
                            label: const Text('Solo Ida'),
                            selected: modalidad == 'Ida',
                            onSelected: cargandoModal
                                ? null
                                : (sel) {
                                    if (sel) {
                                      setDialogState(() {
                                        modalidad = 'Ida';
                                        partidosPreview = null;
                                      });
                                    }
                                  },
                            selectedColor: AppColors.primary.withAlpha(40),
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            key: const Key('chip_modalidad_ida_vuelta'),
                            label: const Text('Ida y Vuelta'),
                            selected: modalidad == 'IdaYVuelta',
                            onSelected: cargandoModal
                                ? null
                                : (sel) {
                                    if (sel) {
                                      setDialogState(() {
                                        modalidad = 'IdaYVuelta';
                                        partidosPreview = null;
                                      });
                                    }
                                  },
                            selectedColor: AppColors.primary.withAlpha(40),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Sobrescribir fase previa
                      SwitchListTile.adaptive(
                        key: const Key('switch_sobrescribir_fixture'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Reemplazar partidos previos no jugados',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Si ya existen partidos programados en esta fase, serán sobrescritos.',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                        value: sobrescribir,
                        onChanged: cargandoModal
                            ? null
                            : (val) => setDialogState(() => sobrescribir = val),
                      ),
                      const SizedBox(height: 8),

                      // Botón para previsualizar cruces
                      OutlinedButton.icon(
                        key: const Key('btn_vista_previa_fixture'),
                        onPressed: (cargandoModal || cargandoPreview)
                            ? null
                            : () async {
                                setDialogState(() {
                                  cargandoPreview = true;
                                  errorModal = null;
                                });
                                try {
                                  final res = await _partidosService.generarFixture(
                                    fase: faseSeleccionadaModal,
                                    fechaInicio: fechaSeleccionada,
                                    modalidad: modalidad,
                                    soloVistaPrevia: true,
                                    token: widget.token,
                                  );
                                  setDialogState(() {
                                    partidosPreview = (res['partidos'] as List?) ?? [];
                                    cargandoPreview = false;
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    cargandoPreview = false;
                                    errorModal = e.toString().replaceFirst('Exception: ', '').replaceFirst('AppException: ', '');
                                  });
                                }
                              },
                        icon: cargandoPreview
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.remove_red_eye_outlined, size: 18),
                        label: const Text('Ver Vista Previa de Cruces'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      // Sección de previsualización de cruces
                      if (partidosPreview != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cruces proyectados (${partidosPreview!.length} partidos):',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 180),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: partidosPreview!.length,
                                  separatorBuilder: (_, _) => const Divider(height: 8),
                                  itemBuilder: (context, idx) {
                                    final p = partidosPreview![idx];
                                    final loc = p['equipoLocal'] ?? 'Local';
                                    final vis = p['equipoVisitante'] ?? 'Visitante';
                                    final obs = p['observaciones']?.toString() ?? '';
                                    final tieneVentaja = obs.toLowerCase().contains('ventaja') || obs.toLowerCase().contains('punto invisible');

                                    return Row(
                                      children: [
                                        Text(
                                          'J${p['jornada'] ?? 1}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$loc vs $vis',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (tieneVentaja)
                                          Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('⭐ Ventaja', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('btn_cancelar_generar_fixture'),
                  onPressed: cargandoModal ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  key: const Key('btn_confirmar_generar_fixture'),
                  onPressed: cargandoModal
                      ? null
                      : () async {
                          setDialogState(() {
                            cargandoModal = true;
                            errorModal = null;
                          });

                          try {
                            final res = await _partidosService.generarFixture(
                              fase: faseSeleccionadaModal,
                              fechaInicio: fechaSeleccionada,
                              modalidad: modalidad,
                              soloVistaPrevia: false,
                              sobrescribirFase: sobrescribir,
                              token: widget.token,
                            );

                            final totalP = res['totalPartidos'] ?? 0;
                            final targetPhase = _mapBackendToTournamentPhase(faseSeleccionadaModal);

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }

                            if (!mounted) return;
                            setState(() {
                              faseSeleccionada = targetPhase;
                            });
                            await cargarJornadas();
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Fixture de ${_obtenerNombreFase(faseSeleccionadaModal)} generado exitosamente ($totalP partidos).',
                                ),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              cargandoModal = false;
                              errorModal = e.toString().replaceFirst('Exception: ', '').replaceFirst('AppException: ', '');
                            });
                          }
                        },
                  icon: cargandoModal
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.bolt, size: 18),
                  label: const Text('Confirmar y Generar Fixture'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _construirSelectorFases() {
    final fases = [
      {'id': 'TODAS', 'nombre': 'Todas las Fases'},
      {'id': TournamentPhase.primeraFase, 'nombre': '1. Primera Fase'},
      {'id': TournamentPhase.segundaRonda, 'nombre': '2. Cuadrangulares'},
      {'id': TournamentPhase.terceraRonda, 'nombre': '3. Cuartos'},
      {'id': TournamentPhase.cuartaRonda, 'nombre': '4. Semifinales'},
      {'id': TournamentPhase.quintaRonda, 'nombre': '5. Gran Final'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 38,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: fases.map((f) {
            final activa = faseSeleccionada == f['id'];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                key: Key('chip_fase_${f['id']!.toLowerCase().replaceAll(' ', '_')}'),
                onTap: () => setState(() => faseSeleccionada = f['id']!),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: activa ? const Color(0xFF0D233A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: activa ? const Color(0xFF0D233A) : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                    boxShadow: activa
                        ? [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      f['nombre']!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: activa ? FontWeight.w800 : FontWeight.w600,
                        color: activa ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const PublicTopNavBar(activeRoute: 'Jornadas'),
      body: RefreshIndicator(
        onRefresh: cargarJornadas,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarJornadas,
              );
            }

            if (seccionesFixture.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppEmptyView(
                        message: 'No hay jornadas registradas en este torneo.',
                        icon: Icons.calendar_month_outlined,
                      ),
                      if (_esAdmin) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          key: const Key('btn_generar_primer_fixture'),
                          onPressed: () => _abrirModalGenerarFixture('PRIMERA_FASE'),
                          icon: const Icon(Icons.bolt),
                          label: const Text('Generar Fixture del Torneo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            final isMobile = MediaQuery.of(context).size.width < 600;

            final seccionesVisibles = faseSeleccionada == 'TODAS'
                ? seccionesFixture
                : seccionesFixture.where((s) => s.fase == faseSeleccionada).toList();

            final bool faseSinPartidos = seccionesVisibles.every((s) => s.esPendiente || s.partidos.isEmpty);

            // Determinar qué fase/jornada expandir por defecto
            String seccionInicialId = 'jornada_1';
            for (final s in seccionesVisibles) {
              if (s.partidos.any((p) => p.esEnCurso)) {
                seccionInicialId = s.id;
                break;
              }
            }
            if (seccionInicialId == 'jornada_1') {
              for (final s in seccionesVisibles) {
                if (s.partidos.any((p) => p.esProgramado && p.id > 0)) {
                  seccionInicialId = s.id;
                  break;
                }
              }
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Cabecera: Banner azul con silueta de estadio, icono de calendario y título
                    Card(
                      elevation: 2.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/banner_blue.jpg'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Color(0xB30A192F),
                              BlendMode.srcOver,
                            ),
                          ),
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
                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                        child: Row(
                          children: [
                            Container(
                              width: isMobile ? 44 : 52,
                              height: isMobile ? 44 : 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24, width: 1.2),
                              ),
                              child: Icon(
                                Icons.calendar_month,
                                color: Colors.white,
                                size: isMobile ? 26 : 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Partidos por jornada',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 19 : 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ListenableBuilder(
                                    listenable: SessionManager(),
                                    builder: (context, _) => Text(
                                      SessionManager().selectedCampeonatoNombre,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isMobile ? 13 : 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_esAdmin) ...[
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                key: const Key('btn_generar_fixture_banner'),
                                onPressed: () => _abrirModalGenerarFixture(faseSeleccionada),
                                icon: const Icon(Icons.bolt, size: 18),
                                label: Text(isMobile ? 'Fixture' : 'Generar Fixture'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 10 : 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Selector de Pestañas para las 5 Fases
                    _construirSelectorFases(),

                    // Acción rápida si una fase específica no tiene partidos registrados
                    if (faseSeleccionada != 'TODAS' && faseSinPartidos && _esAdmin) ...[
                      Builder(
                        builder: (context) {
                          final nombreFase = _obtenerNombreFase(faseSeleccionada);
                          final faseSlug = faseSeleccionada.toLowerCase().replaceAll(' ', '_');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(6),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(20),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.bolt, color: AppColors.primary, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fase sin partidos: $nombreFase',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Genera los emparejamientos y fechas de esta fase automáticamente.',
                                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    key: Key('btn_generar_cruces_$faseSlug'),
                                    onPressed: () => _abrirModalGenerarFixture(faseSeleccionada),
                                    icon: const Icon(Icons.auto_awesome, size: 18),
                                    label: Text('+ Generar Cruces de $nombreFase'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    // LISTA DE FASES Y JORNADAS EN ACORDEÓN (5 FASES)
                    ...seccionesVisibles.map((seccion) {
                      return PublicJornadaAccordion(
                        numeroJornada: seccion.numeroJornada,
                        fase: seccion.fase,
                        tituloPersonalizado: seccion.titulo,
                        subtitulo: seccion.subtitulo,
                        cantidadPartidos: seccion.cantidadPartidos,
                        partidos: seccion.partidos,
                        esPendiente: seccion.esPendiente,
                        mensajePendiente: seccion.mensajePendiente,
                        adminAction: BotonGenerarFase(
                          fase: seccion.fase,
                          todosLosPartidos: todosPartidos,
                          faseGenerada: !seccion.esPendiente && seccion.partidos.isNotEmpty,
                          onFaseGenerada: cargarJornadas,
                          onCustomGenerar: () => _abrirModalGenerarFixture(seccion.fase),
                        ),
                        initiallyExpanded: seccion.id == seccionInicialId,
                        onPartidoTap: (partido) => _abrirPartido(partido.id),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}