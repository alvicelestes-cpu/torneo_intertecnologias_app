import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/theme/tournament_theme.dart';
import 'core/utils/mobile_image_picker.dart';
import 'core/utils/ui_helpers.dart';
import 'models/equipo.dart';
import 'models/jugador.dart';
import 'services/carnets_pdf_service.dart';
import 'services/equipos_service.dart';
import 'services/jugadores_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/public_navbar.dart';
import 'widgets/public_team_card.dart';

import 'crear_jugador_page.dart';
import 'editar_equipo_page.dart';
import 'jugadores_equipo_page.dart';
import 'widgets/importar_planilla_modal.dart';

class EquiposPage extends StatefulWidget {
  final String? token;
  final EquiposService? equiposService;
  final JugadoresService? jugadoresService;

  const EquiposPage({
    super.key,
    this.token,
    this.equiposService,
    this.jugadoresService,
  });

  @override
  State<EquiposPage> createState() => _EquiposPageState();
}

class _EquiposPageState extends State<EquiposPage> {
  late final EquiposService _equiposService;
  late final JugadoresService _jugadoresService;

  bool cargando = true;
  String? error;
  List<Equipo> equipos = [];

  @override
  void initState() {
    super.initState();
    _equiposService = widget.equiposService ?? EquiposService();
    _jugadoresService = widget.jugadoresService ?? JugadoresService();
    SessionManager().addListener(_onSessionChanged);
    cargarEquipos();
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) cargarEquipos();
  }

  Future<void> cargarEquipos() async {
    setState(() {
      cargando = true;
      error = null;
      equipos = [];
    });

    try {
      final resultados = await Future.wait([
        _equiposService.getEquipos(token: widget.token),
        _jugadoresService.getJugadores(token: widget.token).catchError((_) => <Jugador>[]),
      ]);

      final listaEquipos = resultados[0] as List<Equipo>;
      final listaJugadores = resultados[1] as List<Jugador>;

      // Mapear cantidad de jugadores por equipo
      final conteoJugadores = <int, int>{};
      for (final j in listaJugadores) {
        conteoJugadores[j.equipoId] = (conteoJugadores[j.equipoId] ?? 0) + 1;
      }

      final equiposActualizados = listaEquipos.map((e) {
        final total = conteoJugadores[e.id] ?? e.cantidadJugadores;
        return e.copyWith(cantidadJugadores: total);
      }).toList();

      // ORDEN CONSISTENTE: ALFABÉTICO
      equiposActualizados.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      if (mounted) {
        setState(() {
          equipos = equiposActualizados;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'No se pudo conectar con el servidor.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  void _abrirPlantilla(Equipo equipo) {
    if (equipo.id <= 0) {
      UiHelpers.showError(
        context,
        'El equipo no tiene un ID válido.',
      );
      return;
    }

    final targetTheme = equipo.resolvedCampeonatoId == 2
        ? TournamentTheme.banquita
        : (equipo.resolvedCampeonatoId == 1
            ? TournamentTheme.intertecnologias
            : TournamentTheme.of(context));

    final targetTorneoId = equipo.resolvedCampeonatoId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InheritedTournamentTheme(
          theme: targetTheme,
          child: JugadoresEquipoPage(
            equipoId: equipo.id,
            equipoNombre: equipo.nombre,
            token: widget.token,
            torneoId: targetTorneoId,
            tieneCategoriasEdad: targetTheme.usaCategoriasEdad,
          ),
        ),
      ),
    );
  }

  Future<void> _descargarCarnetsEquipo(Equipo equipo) async {
    if (!_esAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso restringido: Solo administradores autorizados pueden descargar carnets.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      List<Jugador> jugadoresEquipo = [];
      try {
        jugadoresEquipo = await _equiposService.getJugadoresEquipo(
          equipo.id,
          token: widget.token,
          campeonatoId: SessionManager().selectedCampeonatoId,
        );
      } catch (_) {
        jugadoresEquipo = [];
      }

      if (!mounted) return;

      if (jugadoresEquipo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El equipo ${equipo.nombre} no tiene jugadores registrados.'),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await CarnetsPdfService.descargarCarnetsConFeedback(
        context: context,
        equipo: equipo,
        jugadores: jugadoresEquipo,
        torneoNombre: SessionManager().selectedCampeonatoNombre,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar carnets: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _abrirInscripcion() async {
    final nuevoRegistrado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearJugadorPage(token: widget.token),
      ),
    );

    if (nuevoRegistrado == true && mounted) {
      cargarEquipos();
    }
  }

  Future<void> _abrirModalImportarPlanilla({int initialTabIndex = 0}) async {
    if (!_esAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso restringido: Solo administradores pueden importar planillas.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ImportarPlanillaModal(
        token: widget.token,
        equiposService: _equiposService,
        initialTabIndex: initialTabIndex,
      ),
    );

    if (resultado == true && mounted) {
      cargarEquipos();
    }
  }

  void _abrirCrearEquipo() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final siglaCtrl = TextEditingController();
    final logoUrlCtrl = TextEditingController();

    String colorSeleccionado = '#0D47A1';
    Uint8List? escudoBytes;
    String? escudoDataUri;
    bool guardando = false;
    String? errorCreacion;

    final coloresPaleta = [
      '#0D47A1', // Azul Noche
      '#1565C0', // Azul Real
      '#00897B', // Turquesa
      '#2E7D32', // Verde
      '#C62828', // Rojo
      '#E65100', // Naranja
      '#6A1B9A', // Púrpura
      '#37474F', // Gris Pizarra
      '#F9A825', // Dorado
      '#212121', // Negro Grafito
    ];

    Color hexToColor(String hex) {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      return const Color(0xFF0D47A1);
    }

    showDialog(
      context: context,
      barrierDismissible: !guardando,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final colorWidget = hexToColor(colorSeleccionado);
            final nombreActual = nombreCtrl.text.trim();
            final siglaActual = siglaCtrl.text.trim();
            final previewTexto = siglaActual.isNotEmpty
                ? siglaActual
                : (nombreActual.isNotEmpty
                    ? (nombreActual.length > 3 ? nombreActual.substring(0, 3).toUpperCase() : nombreActual.toUpperCase())
                    : 'EQP');

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    child: const Icon(Icons.shield, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nuevo Equipo',
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
                        if (errorCreacion != null) ...[
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
                                    errorCreacion!,
                                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Contexto del torneo activo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Torneo: ${SessionManager().selectedCampeonatoNombre}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Previsualización de escudo y color
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: colorWidget,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: escudoBytes != null
                                    ? Image.memory(escudoBytes!, fit: BoxFit.cover)
                                    : (logoUrlCtrl.text.trim().isNotEmpty
                                        ? Image.network(
                                            logoUrlCtrl.text.trim(),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Center(
                                              child: Text(
                                                previewTexto,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              previewTexto,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          )),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Vista previa del escudo',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 1. Nombre del equipo (obligatorio)
                        const Text(
                          'Nombre del Equipo *',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('input_nombre_equipo'),
                          controller: nombreCtrl,
                          enabled: !guardando,
                          decoration: InputDecoration(
                            hintText: 'Ej. Deportivo Inter',
                            prefixIcon: const Icon(Icons.shield_outlined, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'El nombre del equipo es obligatorio';
                            }
                            if (val.trim().length < 3) {
                              return 'El nombre debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                          onChanged: (val) {
                            if (siglaCtrl.text.isEmpty || siglaCtrl.text.length <= 4) {
                              final words = val.trim().split(RegExp(r'\s+'));
                              if (words.length >= 2) {
                                siglaCtrl.text = words.map((w) => w.isNotEmpty ? w[0] : '').take(4).join().toUpperCase();
                              } else if (val.trim().length >= 3) {
                                siglaCtrl.text = val.trim().substring(0, 3).toUpperCase();
                              }
                            }
                            setDialogState(() {});
                          },
                        ),
                        const SizedBox(height: 14),

                        // 2. Código corto / Abreviatura (ej. PRU27)
                        const Text(
                          'Código Corto / Sigla (ej. PRU27)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('input_sigla_equipo'),
                          controller: siglaCtrl,
                          enabled: !guardando,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 6,
                          decoration: InputDecoration(
                            hintText: 'Ej. DEP o PRU27',
                            counterText: '',
                            prefixIcon: const Icon(Icons.short_text, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                        const SizedBox(height: 14),

                        // 3. Color distintivo (paleta predefinida)
                        const Text(
                          'Color Distintivo:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: coloresPaleta.map((hex) {
                            final colorItem = hexToColor(hex);
                            final isSelected = colorSeleccionado.toUpperCase() == hex.toUpperCase();

                            return InkWell(
                              key: Key('color_picker_$hex'),
                              onTap: guardando
                                  ? null
                                  : () {
                                      setDialogState(() {
                                        colorSeleccionado = hex;
                                      });
                                    },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: colorItem,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.black : Colors.black12,
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // 4. Subida o selección de escudo/logo (opcional con valor por defecto)
                        const Text(
                          'Escudo / Logo (opcional):',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              key: const Key('btn_subir_escudo_equipo'),
                              onPressed: guardando
                                  ? null
                                  : () async {
                                      try {
                                        final picked = await MobileImagePicker.pickImage();
                                        if (picked != null) {
                                          setDialogState(() {
                                            escudoBytes = picked.bytes;
                                            escudoDataUri = picked.dataUri;
                                          });
                                        }
                                      } catch (_) {}
                                    },
                              icon: const Icon(Icons.upload, size: 18),
                              label: const Text('Subir Imagen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryLight,
                                foregroundColor: AppColors.primaryDark,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            if (escudoBytes != null) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setDialogState(() {
                                    escudoBytes = null;
                                    escudoDataUri = null;
                                  });
                                },
                                child: const Text('Quitar', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: logoUrlCtrl,
                          enabled: !guardando,
                          decoration: InputDecoration(
                            hintText: 'O ingresa URL de imagen (https://...)',
                            prefixIcon: const Icon(Icons.link, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('btn_cancelar_crear_equipo'),
                  onPressed: guardando ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  key: const Key('btn_guardar_nuevo_equipo'),
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            guardando = true;
                            errorCreacion = null;
                          });

                          try {
                            final nombre = nombreCtrl.text.trim();
                            final sigla = siglaCtrl.text.trim();
                            final logoFinal = escudoDataUri ?? (logoUrlCtrl.text.trim().isNotEmpty ? logoUrlCtrl.text.trim() : null);

                            await _equiposService.crearEquipo(
                              nombre: nombre,
                              sigla: sigla.isNotEmpty ? sigla : null,
                              colorPrincipal: colorSeleccionado,
                              logo: logoFinal,
                              campeonatoId: SessionManager().selectedCampeonatoId,
                              token: widget.token,
                            );

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }

                            if (!mounted) return;
                            await cargarEquipos();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Equipo "$nombre" creado exitosamente en ${SessionManager().selectedCampeonatoNombre}.',
                                ),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              guardando = false;
                              errorCreacion = e.toString().replaceFirst('Exception: ', '').replaceFirst('AppException: ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Crear Equipo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _abrirEditarEquipo(Equipo equipo) async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarEquipoPage(
          equipo: equipo,
          token: widget.token,
        ),
      ),
    );

    if (actualizado == true && mounted) {
      cargarEquipos();
    }
  }

  Future<void> _confirmarEliminarEquipo(Equipo equipo) async {
    if (!_esAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso restringido: Se requieren permisos de administrador para eliminar equipos.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Eliminar Equipo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este equipo? Se borrarán también todos sus jugadores inscritos.',
          style: TextStyle(fontSize: 14, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            key: const Key('btn_cancelar_eliminar_equipo'),
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            key: const Key('btn_confirmar_eliminar_equipo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      // 1. Intentar eliminar jugadores vinculados para asegurar consistencia
      try {
        final jugadoresEquipo = await _equiposService.getJugadoresEquipo(
          equipo.id,
          token: widget.token,
          campeonatoId: SessionManager().selectedCampeonatoId,
        );
        for (final j in jugadoresEquipo) {
          try {
            await _jugadoresService.eliminarJugador(
              j.id,
              token: widget.token,
              campeonatoId: SessionManager().selectedCampeonatoId,
            );
          } catch (_) {
            // Continuar con la eliminación del equipo
          }
        }
      } catch (_) {
        // Continuar con la eliminación del equipo
      }

      // 2. Eliminar el equipo en el servidor
      await _equiposService.eliminarEquipo(
        equipo.id,
        token: widget.token,
        campeonatoId: SessionManager().selectedCampeonatoId,
      );

      // 3. Actualizar la vista inmediatamente
      if (mounted) {
        setState(() {
          equipos.removeWhere((e) => e.id == equipo.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Equipo "${equipo.nombre}" eliminado exitosamente.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // 4. Sincronizar con el backend
      await cargarEquipos();
    } on AppException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    } catch (e) {
      if (mounted) UiHelpers.showError(context, 'No se pudo eliminar el equipo: $e');
    }
  }

  bool get _esAdmin {
    final session = SessionManager();
    final tieneTokenValido = (widget.token != null && widget.token!.isNotEmpty) || session.token.isNotEmpty;
    return tieneTokenValido && session.hasAdminAccess;
  }


  @override
  Widget build(BuildContext context) {
    final theme = TournamentTheme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const PublicTopNavBar(activeRoute: 'Equipos'),
      body: RefreshIndicator(
        onRefresh: cargarEquipos,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarEquipos,
              );
            }

            if (equipos.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppEmptyView(
                        message: 'No hay equipos registrados en este torneo.',
                        icon: Icons.groups_outlined,
                      ),
                      if (_esAdmin) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              key: const Key('btn_importar_planilla_vacio'),
                              onPressed: _abrirModalImportarPlanilla,
                              icon: const Icon(Icons.file_upload_outlined),
                              label: const Text('Importar Planilla'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.usaCategoriasEdad ? const Color(0xFF0F766E) : theme.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            ElevatedButton.icon(
                              key: const Key('btn_crear_primer_equipo'),
                              onPressed: _abrirCrearEquipo,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Crear Primer Equipo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            final isMobile = MediaQuery.of(context).size.width < 600;
            final isBanquita = (SessionManager().selectedCampeonatoId == 2) ||
                (theme.isBanquita && SessionManager().selectedCampeonatoId != 1);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 16,
                  ),
                  children: [
                    // Cabecera: Fondo azul degradado con imagen de estadio, icono dorado de trofeo y título
                    Card(
                      elevation: 2.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          image: !isBanquita
                              ? const DecorationImage(
                                  image: AssetImage('assets/images/banner_blue.jpg'),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Color(0xB30A192F),
                                    BlendMode.srcOver,
                                  ),
                                )
                              : null,
                          gradient: LinearGradient(
                            colors: isBanquita
                                ? theme.headerGradient
                                : const [
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
                                Icons.emoji_events,
                                color: const Color(0xFFFFD700),
                                size: isMobile ? 26 : 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Equipos participantes',
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
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                key: const Key('btn_importar_planilla_banner'),
                                onPressed: _abrirModalImportarPlanilla,
                                icon: const Icon(Icons.file_upload_outlined, size: 18),
                                label: Text(isMobile ? 'Importar' : 'Importar Planilla'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.usaCategoriasEdad ? const Color(0xFF0F766E) : theme.secondary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 10 : 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                key: const Key('btn_crear_equipo_banner'),
                                onPressed: _abrirCrearEquipo,
                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                label: Text(isMobile ? 'Crear' : 'Crear Equipo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: theme.primary,
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

                    // Grid responsive de tarjetas de equipo (4 en desktop, 2 en tablet, 1 en móvil a ancho completo)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final int crossAxisCount = width >= 1050
                            ? 4
                            : (width >= 620 ? 2 : 1);

                        if (crossAxisCount == 1) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: equipos
                                .map(
                                  (equipo) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: PublicTeamCard(
                                        equipo: equipo,
                                        onTap: () => _abrirPlantilla(equipo),
                                        onCarnets: _esAdmin ? () => _descargarCarnetsEquipo(equipo) : null,
                                        onEdit: _esAdmin ? () => _abrirEditarEquipo(equipo) : null,
                                        onDelete: _esAdmin ? () => _confirmarEliminarEquipo(equipo) : null,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 232,
                          ),
                          itemCount: equipos.length,
                          itemBuilder: (context, index) {
                            final equipo = equipos[index];
                            return PublicTeamCard(
                              equipo: equipo,
                              onTap: () => _abrirPlantilla(equipo),
                              onCarnets: _esAdmin ? () => _descargarCarnetsEquipo(equipo) : null,
                              onEdit: _esAdmin ? () => _abrirEditarEquipo(equipo) : null,
                              onDelete: _esAdmin ? () => _confirmarEliminarEquipo(equipo) : null,
                            );
                          },
                        );

                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _esAdmin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'fab_importar_planilla',
                  key: const Key('btn_importar_planilla_fab'),
                  backgroundColor: theme.usaCategoriasEdad ? const Color(0xFF0F766E) : theme.secondary,
                  onPressed: _abrirModalImportarPlanilla,
                  icon: const Icon(Icons.file_upload, color: Colors.white),
                  label: const Text(
                    'Importar Planilla',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'fab_crear_equipo',
                  key: const Key('btn_crear_equipo_fab'),
                  backgroundColor: theme.primary,
                  onPressed: _abrirCrearEquipo,
                  icon: const Icon(Icons.group_add, color: Colors.white),
                  label: const Text(
                    'Crear Equipo',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'fab_inscribir_jugador',
                  key: const Key('btn_inscribir_jugador_fab'),
                  backgroundColor: theme.usaCategoriasEdad ? const Color(0xFF1E3A8A) : theme.primaryDark,
                  onPressed: _abrirInscripcion,
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text(
                    'Inscribir Jugador',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}