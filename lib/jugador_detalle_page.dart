import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/session/session_manager.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/ui_helpers.dart';
import 'models/jugador.dart';
import 'widgets/player_avatar.dart';

import 'editar_jugador_page.dart';

class JugadorDetallePage extends StatefulWidget {
  final Map<String, dynamic> jugador;
  final String equipoNombre;
  final String? token;

  const JugadorDetallePage({
    super.key,
    required this.jugador,
    required this.equipoNombre,
    this.token,
  });

  @override
  State<JugadorDetallePage> createState() => _JugadorDetallePageState();
}

class _JugadorDetallePageState extends State<JugadorDetallePage> {
  late Jugador jugador;

  @override
  void initState() {
    super.initState();
    jugador = Jugador.fromJson(widget.jugador);
  }

  Widget filaDato(IconData icono, String titulo, String valor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Icon(icono, color: AppColors.primary),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          valor,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> abrirEdicion() async {
    if (!SessionManager().isAuthenticated) return;
    if (jugador.id <= 0) {
      UiHelpers.showError(context, 'El jugador no tiene un ID válido.');
      return;
    }

    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarJugadorPage(
          jugadorId: jugador.id,
          token: widget.token ?? SessionManager().token,
        ),
      ),
    );

    if (actualizado == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreCompleto = jugador.nombreCompleto.isEmpty
        ? 'Jugador sin nombre'
        : jugador.nombreCompleto;
    final numero = jugador.numeroCamiseta != null
        ? jugador.numeroCamiseta.toString()
        : 'No registrado';
    final posicion = jugador.posicion?.isNotEmpty == true
        ? jugador.posicion!
        : 'No registrada';
    final estado = jugador.estado.isNotEmpty ? jugador.estado : 'No registrado';
    final fechaNacimiento = AppDateUtils.formatDate(
      jugador.fechaNacimiento,
      defaultText: 'No registrada',
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ficha del jugador'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                PlayerAvatar(
                  photoUrl: jugador.fotoJugador,
                  playerName: jugador.nombreCompleto,
                  radius: 75,
                ),
                const SizedBox(height: 18),
                Text(
                  nombreCompleto,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.equipoNombre,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                filaDato(
                  Icons.confirmation_number,
                  'Número de camiseta',
                  numero,
                ),
                filaDato(
                  Icons.sports_soccer,
                  'Posición',
                  posicion,
                ),
                filaDato(
                  Icons.cake_outlined,
                  'Fecha de nacimiento',
                  fechaNacimiento,
                ),
                if (SessionManager().isAuthenticated &&
                    jugador.documento != null &&
                    jugador.documento!.isNotEmpty)
                  filaDato(
                    Icons.badge,
                    'Documento',
                    jugador.documento!,
                  ),
                filaDato(
                  Icons.verified,
                  'Estado',
                  estado,
                ),
                filaDato(
                  Icons.groups,
                  'Equipo',
                  widget.equipoNombre,
                ),
                if (SessionManager().isAuthenticated &&
                    jugador.observacionAdmin != null &&
                    jugador.observacionAdmin!.isNotEmpty)
                  filaDato(
                    Icons.note,
                    'Observaciones',
                    jugador.observacionAdmin!,
                  ),
                if (SessionManager().isAuthenticated) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: abrirEdicion,
                      icon: const Icon(Icons.edit),
                      label: const Text(
                        'EDITAR JUGADOR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}