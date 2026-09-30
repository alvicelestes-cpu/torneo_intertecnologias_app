import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'models/equipo.dart';
import 'models/goleador.dart';
import 'models/jugador.dart';
import 'services/carnets_pdf_service.dart';
import 'services/equipos_service.dart';
import 'services/jugadores_service.dart';
import 'services/torneo_config_service.dart';
import 'services/torneo_service.dart';
import 'core/utils/player_sort_utils.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/public_age_group_section.dart';
import 'widgets/public_navbar.dart';
import 'widgets/team_logo_avatar.dart';

import 'core/utils/ui_helpers.dart';
import 'crear_jugador_page.dart';
import 'editar_equipo_page.dart';
import 'jugador_detalle_page.dart';

class JugadoresEquipoPage extends StatefulWidget {
  final int equipoId;
  final String equipoNombre;
  final String? token;
  final EquiposService? equiposService;
  final JugadoresService? jugadoresService;
  final TorneoService? torneoService;

  const JugadoresEquipoPage({
    super.key,
    required this.equipoId,
    required this.equipoNombre,
    this.token,
    this.equiposService,
    this.jugadoresService,
    this.torneoService,
  });

  @override
  State<JugadoresEquipoPage> createState() => _JugadoresEquipoPageState();
}

class _JugadoresEquipoPageState extends State<JugadoresEquipoPage> {
  late final EquiposService _equiposService;
  late final JugadoresService _jugadoresService;
  late final TorneoService _torneoService;

  bool cargando = true;
  String? error;
  List<Jugador> jugadores = [];
  Equipo? equipoInfo;
  int get _limiteJugadores => TorneoConfigService().limiteJugadores;

  @override
  void initState() {
    super.initState();
    _equiposService = widget.equiposService ?? EquiposService();
    _jugadoresService = widget.jugadoresService ?? JugadoresService();
    _torneoService = widget.torneoService ?? TorneoService();
    cargarJugadores();
  }

  Future<void> cargarJugadores() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final currentCampeonatoId = SessionManager().selectedCampeonatoId;
      final resultados = await Future.wait([
        _equiposService.getJugadoresEquipo(
          widget.equipoId,
          token: widget.token,
          campeonatoId: currentCampeonatoId,
        ),
        _torneoService
            .getGoleadores(
              token: widget.token,
              campeonatoId: currentCampeonatoId,
              cargarFotos: false,
            )
            .catchError((_) => <Goleador>[]),
        _equiposService
            .getEquipos(
              token: widget.token,
              campeonatoId: currentCampeonatoId,
            )
            .catchError((_) => <Equipo>[]),
      ]);

      final listaJugadores = resultados[0] as List<Jugador>;
      final listaGoleadores = resultados[1] as List<Goleador>;
      final listaEquipos = resultados[2] as List<Equipo>;

      final equipoEncontrado = listaEquipos
          .where((e) => e.id == widget.equipoId)
          .firstOrNull;
      equipoInfo = equipoEncontrado;

      final golesMap = <int, int>{};
      for (final g in listaGoleadores) {
        golesMap[g.jugadorId] = g.goles;
      }

      final iniciales = listaJugadores.map((j) {
        final totalGoles = golesMap[j.id] ?? j.goles;
        return j.copyWith(
          equipoNombre: widget.equipoNombre,
          equipoSigla: equipoEncontrado?.sigla ?? j.equipoSigla,
          equipoColor: equipoEncontrado?.colorPrincipal ?? j.equipoColor,
          equipoLogo: equipoEncontrado?.logo ?? j.equipoLogo,
          goles: totalGoles,
        );
      }).toList();

      if (mounted) {
        setState(() {
          jugadores = iniciales;
          cargando = false;
        });
      }

      _enriquecerEstadisticasTarjetas(iniciales);
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
          cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'No se pudo conectar con el servidor.';
          cargando = false;
        });
      }
    }
  }

  Future<void> _enriquecerEstadisticasTarjetas(List<Jugador> list) async {
    try {
      final enriquecidos = await Future.wait(
        list.map((j) async {
          try {
            final detalle = await _jugadoresService.getJugadorById(j.id, token: widget.token);
            return j.copyWith(
              goles: detalle.goles > 0 ? detalle.goles : j.goles,
              amarillas: detalle.amarillas,
              rojas: detalle.rojas,
            );
          } catch (_) {
            return j;
          }
        }),
      );

      if (mounted) {
        setState(() {
          jugadores = enriquecidos;
        });
      }
    } catch (_) {
      // Ignorar fallos de enriquecimiento en segundo plano
    }
  }

  Future<void> _abrirFicha(Jugador jugador) async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JugadorDetallePage(
          jugador: jugador.toJson(),
          equipoNombre: widget.equipoNombre,
          token: widget.token,
          jugadoresService: _jugadoresService,
        ),

      ),
    );

    if (actualizado == true && mounted) {
      cargarJugadores();
    }
  }

  Future<void> _confirmarEliminarJugador(Jugador jugador) async {
    if (!_esAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso restringido: Se requieren permisos de administrador para eliminar jugadores.'),
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
                'Eliminar Jugador',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Deseas eliminar a este jugador del plantel?',
          style: TextStyle(fontSize: 14, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            key: const Key('btn_cancelar_eliminar_jugador'),
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            key: const Key('btn_confirmar_eliminar_jugador'),
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
      // 1. Eliminar en el almacenamiento / backend
      await _jugadoresService.eliminarJugador(
        jugador.id,
        token: widget.token,
        campeonatoId: SessionManager().selectedCampeonatoId,
      );

      // 2. Remover de la lista local inmediatamente para recalcular total de inscritos y carnets
      if (mounted) {
        setState(() {
          jugadores.removeWhere((j) => j.id == jugador.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jugador "${jugador.nombreCompleto}" eliminado del plantel.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // 3. Sincronizar con el backend
      await cargarJugadores();
    } on AppException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    } catch (e) {
      if (mounted) UiHelpers.showError(context, 'No se pudo eliminar al jugador: $e');
    }
  }


  Future<void> _abrirInscripcion() async {
    if (jugadores.length >= _limiteJugadores) {
      UiHelpers.showError(
        context,
        'Este equipo ya ha alcanzado el límite reglamentario máximo de $_limiteJugadores jugadores inscritos.',
      );
      return;
    }

    final nuevoRegistrado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearJugadorPage(
          equipoIdInicial: widget.equipoId,
          equipoNombreInicial: widget.equipoNombre,
          token: widget.token,
        ),
      ),
    );

    if (nuevoRegistrado == true && mounted) {
      cargarJugadores();
    }
  }

  Future<void> _abrirEditarEquipo() async {
    final eq = equipoInfo ??
        Equipo(
          id: widget.equipoId,
          nombre: widget.equipoNombre,
          sigla: '',
        );

    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarEquipoPage(
          equipo: eq,
          token: widget.token,
        ),
      ),
    );

    if (actualizado == true && mounted) {
      cargarJugadores();
    }
  }

  Future<void> _descargarCarnets() async {
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

    if (jugadores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay jugadores registrados en ${widget.equipoNombre}.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final eq = equipoInfo ??
        Equipo(
          id: widget.equipoId,
          nombre: widget.equipoNombre,
          sigla: '',
        );

    await CarnetsPdfService.descargarCarnetsConFeedback(
      context: context,
      equipo: eq,
      jugadores: jugadores,
      torneoNombre: SessionManager().selectedCampeonatoNombre,
    );
  }

  bool get _esAdmin {
    final session = SessionManager();
    final tieneTokenValido = (widget.token != null && widget.token!.isNotEmpty) || session.token.isNotEmpty;
    return tieneTokenValido && session.hasAdminAccess;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const PublicTopNavBar(activeRoute: 'Equipos'),
      body: RefreshIndicator(
        onRefresh: cargarJugadores,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarJugadores,
              );
            }

            if (jugadores.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppEmptyView(
                        message: 'No hay jugadores registrados en este equipo.',
                        icon: Icons.person_off_outlined,
                      ),
                      if (_esAdmin) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _abrirInscripcion,
                          icon: const Icon(Icons.person_add),
                          label: const Text(
                            'Inscribir Jugador',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            final grupos = groupJugadoresPorEdad(jugadores);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabecera del equipo con botón Volver a equipos, escudo, nombre y badge de inscritos
                      Card(
                        elevation: 2.5,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
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
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Botón "← Volver a equipos"
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white30, width: 1),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back, color: Colors.white, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Volver a equipos',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Escudo, Nombre del club y Badge inscritos
                              Row(
                                children: [
                                  Tooltip(
                                    message: _esAdmin
                                        ? 'Cambiar escudo / Editar club'
                                        : widget.equipoNombre,
                                    child: InkWell(
                                      onTap: _esAdmin ? _abrirEditarEquipo : null,
                                      borderRadius: BorderRadius.circular(26),
                                      child: Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white70, width: 2),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 6,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: TeamLogoAvatar(
                                              logoUrl: equipoInfo?.logo,
                                              teamName: widget.equipoNombre,
                                              sigla: equipoInfo?.sigla,
                                              size: 52,
                                              isCircle: true,
                                            ),
                                          ),
                                          if (_esAdmin)
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF0D233A),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                size: 11,
                                                color: Colors.white,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              'PLANTEL OFICIAL',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                                letterSpacing: 1.1,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (_esAdmin) ...[
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: _abrirEditarEquipo,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white24,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.edit, size: 10, color: Colors.white),
                                                      SizedBox(width: 3),
                                                      Text(
                                                        'Editar Club',
                                                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.equipoNombre,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(35),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white38, width: 1.2),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${jugadores.length}/$_limiteJugadores',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const Text(
                                          'inscritos',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.end,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (_esAdmin)
                                      FilledButton.icon(
                                        key: const Key('btn_descargar_carnets_equipo'),
                                        style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF0F766E),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                      ),
                                      onPressed: _descargarCarnets,
                                      icon: const Icon(Icons.badge, size: 18, color: Color(0xFF0F766E)),
                                      label: const Text(
                                        '🪪 Descargar Carnets (PDF)',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (_esAdmin)
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: jugadores.length >= _limiteJugadores
                                              ? Colors.white24
                                              : Colors.white,
                                          foregroundColor: jugadores.length >= _limiteJugadores
                                              ? Colors.white60
                                              : const Color(0xFF0D233A),
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: _abrirInscripcion,
                                        icon: const Icon(Icons.person_add, size: 18),
                                        label: Text(
                                          jugadores.length >= _limiteJugadores
                                              ? 'Plantel Completo (${jugadores.length}/$_limiteJugadores)'
                                              : '+ Inscribir Jugador',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // SECCIONES VISUALES DE CARNETS POR GRUPO DE EDAD
                      ...kAgeGroupsOrder.map((group) {
                        final list = grupos[group] ?? [];
                        if (list.isEmpty) return const SizedBox.shrink();
                        return PublicAgeGroupSection.fromGroup(
                          group: group,
                          jugadores: list,
                          onVerFicha: _abrirFicha,
                          onEliminar: _esAdmin ? _confirmarEliminarJugador : null,
                        );

                      }),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _esAdmin
          ? FloatingActionButton.extended(
              backgroundColor:
                  (jugadores.length >= _limiteJugadores) ? Colors.blueGrey : AppColors.primary,
              onPressed: _abrirInscripcion,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                jugadores.length >= _limiteJugadores
                    ? 'Plantel Completo (${jugadores.length}/$_limiteJugadores)'
                    : 'Inscribir Jugador',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}