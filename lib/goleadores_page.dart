import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'models/goleador.dart';
import 'services/torneo_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/campeonato_selector_bar.dart';
import 'widgets/player_avatar.dart';

class GoleadoresPage extends StatefulWidget {
  final String token;

  const GoleadoresPage({
    super.key,
    required this.token,
  });

  @override
  State<GoleadoresPage> createState() => _GoleadoresPageState();
}

class _GoleadoresPageState extends State<GoleadoresPage> {
  final TorneoService _torneoService = TorneoService();

  bool cargando = true;
  String? error;
  List<Goleador> goleadores = [];

  @override
  void initState() {
    super.initState();
    SessionManager().addListener(_onSessionChanged);
    cargarGoleadores();
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) cargarGoleadores();
  }

  Future<void> cargarGoleadores() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final list = await _torneoService.getGoleadores(
        token: widget.token,
        cargarFotos: true,
      );
      if (mounted) {
        setState(() {
          goleadores = list;
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

  Color colorPosicion(int pos) {
    switch (pos) {
      case 1:
        return AppColors.podioOro;
      case 2:
        return AppColors.podioPlata;
      case 3:
        return AppColors.podioBronce;
      default:
        return Colors.blueGrey.shade100;
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
            const Text('Tabla de goleadores'),
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
        onRefresh: cargarGoleadores,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarGoleadores,
              );
            }

            if (goleadores.isEmpty) {
              return const AppEmptyView(
                message: 'No hay goleadores registrados.',
                icon: Icons.emoji_events_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: goleadores.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final goleador = goleadores[index];
                final rank = goleador.posicion ?? (index + 1);

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: colorPosicion(rank),
                          child: Text(
                            rank.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: rank <= 3 ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        PlayerAvatar(
                          photoUrl: goleador.fotoJugador,
                          playerName: goleador.nombreCompleto,
                          radius: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goleador.nombreCompleto,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                goleador.equipo,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                goleador.goles.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                'GOLES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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