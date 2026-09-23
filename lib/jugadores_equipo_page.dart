import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'models/jugador.dart';
import 'services/equipos_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/player_avatar.dart';

import 'jugador_detalle_page.dart';

class JugadoresEquipoPage extends StatefulWidget {
  final int equipoId;
  final String equipoNombre;
  final String? token;

  const JugadoresEquipoPage({
    super.key,
    required this.equipoId,
    required this.equipoNombre,
    this.token,
  });

  @override
  State<JugadoresEquipoPage> createState() => _JugadoresEquipoPageState();
}

class _JugadoresEquipoPageState extends State<JugadoresEquipoPage> {
  final EquiposService _equiposService = EquiposService();

  bool cargando = true;
  String? error;
  List<Jugador> jugadores = [];

  @override
  void initState() {
    super.initState();
    cargarJugadores();
  }

  Future<void> cargarJugadores() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final list = await _equiposService.getJugadoresEquipo(
        widget.equipoId,
        token: widget.token,
      );
      if (mounted) {
        setState(() {
          jugadores = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.equipoNombre),
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
      ),
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
              return const AppEmptyView(
                message: 'No hay jugadores registrados en este equipo.',
                icon: Icons.person_off_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: jugadores.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final jugador = jugadores[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final actualizado = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JugadorDetallePage(
                            jugador: jugador.toJson(),
                            equipoNombre: widget.equipoNombre,
                            token: widget.token,
                          ),
                        ),
                      );

                      if (actualizado == true && mounted) {
                        cargarJugadores();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          PlayerAvatar(
                            photoUrl: jugador.fotoJugador,
                            playerName: jugador.nombreCompleto,
                            radius: 30,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  jugador.nombreCompleto.isEmpty
                                      ? 'Jugador sin nombre'
                                      : jugador.nombreCompleto,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                if (jugador.numeroCamiseta != null)
                                  Text('Camiseta: ${jugador.numeroCamiseta}'),
                                if (jugador.posicion != null &&
                                    jugador.posicion!.isNotEmpty)
                                  Text('Posición: ${jugador.posicion}'),
                                if (jugador.estado.isNotEmpty)
                                  Text(
                                    'Estado: ${jugador.estado}',
                                    style: TextStyle(
                                      color: jugador.estado == 'VALIDADO' ||
                                              jugador.estado == 'ACTIVO'
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}