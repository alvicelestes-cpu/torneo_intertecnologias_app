import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/date_utils.dart';
import 'models/goleador.dart';
import 'models/jugador.dart';
import 'services/equipos_service.dart';
import 'services/jugadores_service.dart';
import 'services/torneo_service.dart';
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
  final JugadoresService _jugadoresService = JugadoresService();
  final TorneoService _torneoService = TorneoService();

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
      final resultados = await Future.wait([
        _equiposService.getJugadoresEquipo(
          widget.equipoId,
          token: widget.token,
        ),
        _torneoService
            .getGoleadores(
              token: widget.token,
              campeonatoId: SessionManager().selectedCampeonatoId,
              cargarFotos: false,
            )
            .catchError((_) => <Goleador>[]),
      ]);

      final listaJugadores = resultados[0] as List<Jugador>;
      final listaGoleadores = resultados[1] as List<Goleador>;

      final golesMap = <int, int>{};
      for (final g in listaGoleadores) {
        golesMap[g.jugadorId] = g.goles;
      }

      final iniciales = listaJugadores.map((j) {
        final totalGoles = golesMap[j.id] ?? j.goles;
        return j.copyWith(
          equipoNombre: widget.equipoNombre,
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
        ),
      ),
    );

    if (actualizado == true && mounted) {
      cargarJugadores();
    }
  }

  Widget _buildJugadorCarnet(Jugador jugador) {
    final fechaNac = AppDateUtils.formatDate(
      jugador.fechaNacimiento,
      defaultText: 'Sin registrar',
    );

    final edadTexto = jugador.edad != null ? '${jugador.edad} años' : 'Sin registrar';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blueGrey.shade100, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirFicha(jugador),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera: Foto + Nombre + Equipo
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: PlayerAvatar(
                      photoUrl: jugador.fotoJugador,
                      playerName: jugador.nombreCompleto,
                      radius: 34,
                    ),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                widget.equipoNombre,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (jugador.numeroCamiseta != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${jugador.numeroCamiseta}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (jugador.posicion != null &&
                                jugador.posicion!.trim().isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  jugador.posicion!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Datos biográficos: Nacimiento y Edad
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cake_outlined,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Nac: $fechaNac',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Edad: $edadTexto',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ficha deportiva: Goles, Amarillas y Rojas
              Row(
                children: [
                  // Goles
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sports_soccer,
                            size: 16,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${jugador.goles} ${jugador.goles == 1 ? 'gol' : 'goles'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Amarillas
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.crop_portrait,
                            size: 16,
                            color: Color(0xFFF57F17),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${jugador.amarillas}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFF57F17),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Rojas
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.crop_portrait,
                            size: 16,
                            color: Color(0xFFC62828),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${jugador.rojas}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFC62828),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Botón de acción: Ver ficha
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _abrirFicha(jugador),
                  icon: const Icon(Icons.badge_outlined, size: 16),
                  label: const Text(
                    'Ver ficha',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
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

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: jugadores.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _buildJugadorCarnet(jugadores[index]);
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