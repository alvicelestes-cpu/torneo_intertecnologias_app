import 'dart:math';

import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/ui_helpers.dart';
import 'models/equipo.dart';
import 'models/jugador.dart';
import 'services/equipos_service.dart';
import 'services/jugadores_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/campeonato_selector_bar.dart';
import 'widgets/team_logo_avatar.dart';

import 'jugadores_equipo_page.dart';

class EquiposPage extends StatefulWidget {
  final String? token;

  const EquiposPage({
    super.key,
    this.token,
  });

  @override
  State<EquiposPage> createState() => _EquiposPageState();
}

class _EquiposPageState extends State<EquiposPage> {
  final EquiposService _equiposService = EquiposService();
  final JugadoresService _jugadoresService = JugadoresService();

  bool cargando = true;
  String? error;
  List<Equipo> equipos = [];

  @override
  void initState() {
    super.initState();
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JugadoresEquipoPage(
          equipoId: equipo.id,
          equipoNombre: equipo.nombre,
          token: widget.token,
        ),
      ),
    );
  }

  Widget _buildEquipoCard(Equipo equipo) {
    final teamColor = equipo.color;
    const maxPlantilla = 20; // Cupo referencial estándar de torneo
    final cant = equipo.cantidadJugadores;
    final porcentaje = min(1.0, cant / maxPlantilla);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: teamColor.withAlpha(50),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirPlantilla(equipo),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra superior con color representativo
            Container(
              height: 6,
              color: teamColor,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: teamColor.withAlpha(120),
                            width: 2,
                          ),
                        ),
                        child: TeamLogoAvatar(
                          logoUrl: equipo.logo,
                          teamName: equipo.nombre,
                          sigla: equipo.sigla,
                          size: 56,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipo.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (equipo.sigla.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: teamColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: teamColor.withAlpha(80),
                                  ),
                                ),
                                child: Text(
                                  equipo.sigla,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: teamColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 26,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Sección de Plantilla con indicador visual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.groups,
                            size: 18,
                            color: teamColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$cant ${cant == 1 ? 'jugador' : 'jugadores'}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$cant / $maxPlantilla inscritos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Barra de progreso de plantilla
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: porcentaje,
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(teamColor),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Botón de acción deportiva
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: teamColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () => _abrirPlantilla(equipo),
                      icon: const Icon(Icons.people_outline, size: 18),
                      label: const Text(
                        'Ver jugadores',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Equipos'),
            ListenableBuilder(
              listenable: SessionManager(),
              builder: (context, _) => Text(
                SessionManager().selectedCampeonatoNombre,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: CampeonatoSelectorBar(),
          ),
        ],
      ),
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
              return const AppEmptyView(
                message: 'No hay equipos registrados.',
                icon: Icons.groups_outlined,
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: equipos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _buildEquipoCard(equipos[index]);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}