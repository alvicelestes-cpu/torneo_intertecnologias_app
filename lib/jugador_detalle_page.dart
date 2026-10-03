import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/theme/tournament_theme.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/ui_helpers.dart';
import 'editar_jugador_page.dart';
import 'models/jugador.dart';
import 'services/jugadores_service.dart';
import 'widgets/player_avatar.dart';
import 'widgets/status_chip.dart';
import 'widgets/team_logo_avatar.dart';

class JugadorDetallePage extends StatefulWidget {
  final Map<String, dynamic> jugador;
  final String equipoNombre;
  final String? token;
  final JugadoresService? jugadoresService;

  const JugadorDetallePage({
    super.key,
    required this.jugador,
    required this.equipoNombre,
    this.token,
    this.jugadoresService,
  });

  @override
  State<JugadorDetallePage> createState() => _JugadorDetallePageState();
}

class _JugadorDetallePageState extends State<JugadorDetallePage> {
  late Jugador jugador;
  late final JugadoresService _jugadoresService;

  @override
  void initState() {
    super.initState();
    _jugadoresService = widget.jugadoresService ?? JugadoresService();
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

  bool get _esAdmin {
    final session = SessionManager();
    final tieneTokenValido = (widget.token != null && widget.token!.isNotEmpty) || session.token.isNotEmpty;
    return tieneTokenValido && session.hasAdminAccess;
  }

  Future<void> _confirmarEliminarJugador() async {
    if (!_esAdmin) {
      UiHelpers.showError(
        context,
        'Acceso restringido: Se requieren permisos de administrador para eliminar jugadores.',
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
      await _jugadoresService.eliminarJugador(
        jugador.id,
        token: widget.token ?? (SessionManager().token.isNotEmpty ? SessionManager().token : null),
        campeonatoId: SessionManager().selectedCampeonatoId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jugador "${jugador.nombreCompleto}" eliminado del plantel.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } on AppException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    } catch (e) {
      if (mounted) UiHelpers.showError(context, 'No se pudo eliminar al jugador: $e');
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
    final theme = TournamentTheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.isBanquita ? theme.primary : null,
        foregroundColor: theme.isBanquita ? Colors.white : null,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ficha deportiva'),
            ListenableBuilder(
              listenable: SessionManager(),
              builder: (context, _) => Text(
                SessionManager().selectedCampeonatoNombre,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: theme.isBanquita ? Colors.white70 : null,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_esAdmin)
            IconButton(
              key: const Key('btn_eliminar_jugador_appbar'),
              icon: Icon(
                Icons.delete_outline,
                color: theme.isBanquita ? Colors.white : const Color(0xFFDC2626),
              ),
              tooltip: 'Eliminar jugador',
              onPressed: _confirmarEliminarJugador,
            ),
        ],
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
                        colors: theme.getPlayerCardHeaderGradient(jugador.edad),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TeamLogoAvatar(
                                logoUrl: jugador.equipoLogo,
                                teamName: widget.equipoNombre,
                                sigla: jugador.equipoSigla,
                                size: 20,
                                borderRadius: 5,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.equipoNombre,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                  iconColor: theme.isBanquita ? theme.accent : const Color(0xFF1565C0),
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
                  iconColor: theme.isBanquita ? theme.primary : const Color(0xFF0D233A),
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
                if (_esAdmin) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      key: const Key('btn_eliminar_jugador'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _confirmarEliminarJugador,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text(
                        'ELIMINAR JUGADOR',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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