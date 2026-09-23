import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'models/jugador.dart';
import 'services/jugadores_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/player_avatar.dart';

import 'jugador_detalle_page.dart';

class JugadoresPage extends StatefulWidget {
  final String token;

  const JugadoresPage({
    super.key,
    required this.token,
  });

  @override
  State<JugadoresPage> createState() => _JugadoresPageState();
}

class _JugadoresPageState extends State<JugadoresPage> {
  final JugadoresService _jugadoresService = JugadoresService();

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
      final list = await _jugadoresService.getJugadores(token: widget.token);
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
        title: const Text('Jugadores'),
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
                message: 'No hay jugadores registrados.',
                icon: Icons.person_search_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: jugadores.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final jugador = jugadores[index];
                final equipoNombre = jugador.equipoNombre?.trim().isNotEmpty == true
                    ? jugador.equipoNombre!
                    : 'Sin equipo';

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
                            equipoNombre: equipoNombre,
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
                                const SizedBox(height: 4),
                                Text(
                                  equipoNombre,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (jugador.numeroCamiseta != null) ...[
                                      Text(
                                        '#${jugador.numeroCamiseta}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    if (jugador.posicion != null &&
                                        jugador.posicion!.isNotEmpty) ...[
                                      Text(jugador.posicion!),
                                      const SizedBox(width: 10),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (jugador.estado == 'VALIDADO' ||
                                                jugador.estado == 'ACTIVO'
                                            ? Colors.green
                                            : Colors.orange)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        jugador.estado,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: jugador.estado == 'VALIDADO' ||
                                                  jugador.estado == 'ACTIVO'
                                              ? Colors.green.shade800
                                              : Colors.orange.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
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