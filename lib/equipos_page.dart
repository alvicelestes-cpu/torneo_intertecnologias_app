import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/utils/ui_helpers.dart';
import 'models/equipo.dart';
import 'services/equipos_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/team_logo_avatar.dart';

import 'jugadores_equipo_page.dart';

class EquiposPage extends StatefulWidget {
  final String token;

  const EquiposPage({
    super.key,
    required this.token,
  });

  @override
  State<EquiposPage> createState() => _EquiposPageState();
}

class _EquiposPageState extends State<EquiposPage> {
  final EquiposService _equiposService = EquiposService();

  bool cargando = true;
  String? error;
  List<Equipo> equipos = [];

  @override
  void initState() {
    super.initState();
    cargarEquipos();
  }

  Future<void> cargarEquipos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final list = await _equiposService.getEquipos(token: widget.token);
      if (mounted) {
        setState(() {
          equipos = list;
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
        title: const Text('Equipos'),
        centerTitle: true,
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

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: equipos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final equipo = equipos[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: TeamLogoAvatar(
                      logoUrl: equipo.logo,
                      teamName: equipo.nombre,
                      sigla: equipo.sigla,
                    ),
                    title: Text(
                      equipo.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    subtitle: equipo.sigla.isNotEmpty ? Text(equipo.sigla) : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
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
                    },
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