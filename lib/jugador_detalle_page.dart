import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/session/session_manager.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/ui_helpers.dart';
import 'editar_jugador_page.dart';
import 'models/jugador.dart';
import 'services/jugadores_service.dart';
import 'widgets/player_avatar.dart';
import 'widgets/status_chip.dart';

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
  final JugadoresService _jugadoresService = JugadoresService();

  @override
  void initState() {
    super.initState();
    jugador = Jugador.fromJson(widget.jugador);
    _cargarDetallesCompletos();
  }

  Future<void> _cargarDetallesCompletos() async {
    if (jugador.id <= 0) return;
    try {
      final j = await _jugadoresService.getJugadorById(jugador.id, token: widget.token);
      if (mounted) {
        setState(() {
          jugador = j;
        });
      }
    } catch (_) {}
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    bool highlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.primary.withAlpha(80) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black45,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
                    color: highlight ? const Color(0xFF0D233A) : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final nombreCompleto = jugador.nombreCompleto.isNotEmpty
        ? jugador.nombreCompleto
        : 'Jugador sin nombre';
    final numero = jugador.numeroCamiseta != null
        ? '#${jugador.numeroCamiseta}'
        : 'Sin número';
    final posicion = (jugador.posicion != null && jugador.posicion!.trim().isNotEmpty)
        ? jugador.posicion!
        : 'No registrada';
    final fechaNacimiento = AppDateUtils.formatDate(
      jugador.fechaNacimiento,
      defaultText: 'No registrada',
    );
    final edadTexto = jugador.edad != null ? '${jugador.edad} años' : 'No registrada';

    final isAuthenticated = SessionManager().isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ficha deportiva'),
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
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TARJETA PRINCIPAL CON FOTO Y NOMBRE
                Card(
                  elevation: 2.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.getColorByAge(jugador.edad),
                          Color.lerp(AppColors.getColorByAge(jugador.edad), const Color(0xFF0D233A), 0.4) ??
                              AppColors.getColorByAge(jugador.edad),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: PlayerAvatar(
                            photoUrl: jugador.fotoJugador,
                            playerName: jugador.nombreCompleto,
                            radius: 64,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          nombreCompleto.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.equipoNombre,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        StatusChip(
                          status: jugador.estado,
                          fontSize: 11,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // TARJETAS DE ESTADÍSTICAS DEPORTIVAS
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox(
                          icon: Icons.sports_soccer,
                          label: 'GOLES',
                          value: jugador.goles,
                          color: const Color(0xFF2E7D32),
                          bgColor: const Color(0xFFE8F5E9),
                        ),
                        _buildStatBox(
                          icon: Icons.style,
                          label: 'AMARILLAS',
                          value: jugador.amarillas,
                          color: const Color(0xFFF57F17),
                          bgColor: const Color(0xFFFFFDE7),
                        ),
                        _buildStatBox(
                          icon: Icons.style,
                          label: 'ROJAS',
                          value: jugador.rojas,
                          color: const Color(0xFFC62828),
                          bgColor: const Color(0xFFFFEBEE),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // FILAS DE INFORMACIÓN DEPORTIVA PÚBLICA
                _buildInfoRow(
                  icon: Icons.groups,
                  label: 'Equipo',
                  value: widget.equipoNombre,
                ),
                _buildInfoRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Dorsal / Camiseta',
                  value: numero,
                  iconColor: const Color(0xFF1565C0),
                ),
                _buildInfoRow(
                  icon: Icons.sports_soccer_outlined,
                  label: 'Posición de juego',
                  value: posicion,
                  iconColor: const Color(0xFF00897B),
                ),
                _buildInfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Fecha de nacimiento',
                  value: fechaNacimiento,
                ),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Edad actual',
                  value: edadTexto,
                  highlight: true,
                  iconColor: const Color(0xFF0D233A),
                ),

                // CAMPOS PRIVADOS (SÓLO ADMINISTRADORES AUTENTICADOS)
                if (isAuthenticated) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Información Administrativa (Interna)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (jugador.documento != null && jugador.documento!.isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Documento de identidad',
                      value: jugador.documento!,
                      iconColor: Colors.blueGrey,
                    ),
                  if (jugador.observacionAdmin != null && jugador.observacionAdmin!.isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.note_outlined,
                      label: 'Observaciones internas',
                      value: jugador.observacionAdmin!,
                      iconColor: Colors.blueGrey,
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: abrirEdicion,
                      icon: const Icon(Icons.edit, size: 18),
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

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(70), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}