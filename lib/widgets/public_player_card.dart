import '../core/theme/tournament_theme.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/image_utils.dart';
import '../core/utils/text_utils.dart';
import '../models/jugador.dart';
import 'stat_badge.dart';
import 'team_logo_avatar.dart';

class PublicPlayerCard extends StatelessWidget {
  final Jugador jugador;
  final void Function(Jugador jugador)? onVerFicha;
  final void Function(Jugador jugador)? onEliminar;
  final Color? carnetColor;
  final bool? isBanquitaOverride;

  const PublicPlayerCard({
    super.key,
    required this.jugador,
    this.onVerFicha,
    this.onEliminar,
    this.carnetColor,
    this.isBanquitaOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TournamentTheme.of(context);
    final isBanquita = isBanquitaOverride ?? (theme.isBanquita && theme.id != 1);
    final edad = jugador.edad;

    // Para Banquita ID 2: NUNCA usar colores por edad (ni verde ni naranja ni azul por edad).
    // Usar estrictamente la identidad visual deportiva de Banquita:
    // Header verde deportivo [Color(0xFF064E3B), Color(0xFF047857)], dorsal y acentos ámbar/dorado [Color(0xFFF59E0B)].
    // Para Intertecnologías ID 1: SIEMPRE colores por edad (>40 verde #2E7D32, 35-39 naranja #E65100, 18-34 azul #1565C0).
    final carnetColor = isBanquita
        ? theme.secondary // #047857
        : (this.carnetColor ?? getColorByAge(edad));

    final headerColors = isBanquita
        ? theme.getPlayerCardHeaderGradient(edad) // [Color(0xFF064E3B), Color(0xFF047857)]
        : (this.carnetColor != null
            ? [
                this.carnetColor!,
                Color.lerp(this.carnetColor!, const Color(0xFF0D233A), 0.35) ?? this.carnetColor!,
              ]
            : [
                carnetColor,
                Color.lerp(carnetColor, const Color(0xFF0D233A), 0.35) ?? carnetColor,
              ]);

    final dorsalBadgeBg = isBanquita
        ? theme.getPlayerDorsalBadgeColor(edad) // Color(0xFFF59E0B) Ámbar / Dorado
        : Colors.black26;

    final dorsalTextColor = isBanquita
        ? theme.getPlayerDorsalTextColor(edad) // Colors.white
        : Colors.white;

    final ageTextColor = isBanquita
        ? theme.getPlayerAgeTextColor(edad) // Color(0xFF064E3B)
        : carnetColor;

    final buttonColor = isBanquita
        ? theme.getPlayerCardButtonColor(edad) // Color(0xFF047857)
        : carnetColor;



    final sigla = (jugador.equipoSigla != null && jugador.equipoSigla!.trim().isNotEmpty)
        ? jugador.equipoSigla!.trim()
        : TextUtils.getInitials(jugador.equipoNombre, fallback: 'DEP');

    final equipoNombre = (jugador.equipoNombre != null && jugador.equipoNombre!.trim().isNotEmpty)
        ? jugador.equipoNombre!.trim()
        : 'EQUIPO';

    final nombreCompleto = jugador.nombreCompleto.isNotEmpty
        ? jugador.nombreCompleto
        : 'JUGADOR SIN NOMBRE';

    final fechaNac = AppDateUtils.formatDate(
      jugador.fechaNacimiento,
      defaultText: 'Sin registrar',
    );

    final edadTexto = edad != null ? '$edad años' : 'Sin reg.';

    final resolvedPhotoUrl = ImageUtils.resolveUrl(jugador.fotoJugador);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: carnetColor.withAlpha(70), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ENCABEZADO CON COLOR SEGÚN EDAD DEL JUGADOR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Escudo o Sigla del equipo en el carnet
                TeamLogoAvatar(
                  logoUrl: jugador.equipoLogo,
                  teamName: equipoNombre,
                  sigla: sigla,
                  teamColor: carnetColor,
                  size: 28,
                  borderRadius: 6,
                ),
                const SizedBox(width: 8),
                // Equipo + Nombre del Jugador
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        equipoNombre.toUpperCase(),
                        style: TextStyle(
                          color: isBanquita ? Colors.white.withAlpha(230) : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        nombreCompleto.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (jugador.numeroCamiseta != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: dorsalBadgeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${jugador.numeroCamiseta}',
                      style: TextStyle(
                        color: dorsalTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                if (onEliminar != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    key: Key('btn_eliminar_jugador_${jugador.id}'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                    tooltip: 'Eliminar jugador',
                    onPressed: () => onEliminar!(jugador),
                  ),
                ],
              ],
            ),
          ),


          // 2. CUERPO DEL CARNET (FOTO + DATOS + ESTADÍSTICAS)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FOTO PROPORCIONAL (SIN DEFORMAR)
                  SizedBox(
                    width: 96,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: resolvedPhotoUrl.isNotEmpty
                          ? Image.network(
                              resolvedPhotoUrl,
                              width: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildAvatarFallback(carnetColor),
                            )
                          : _buildAvatarFallback(carnetColor),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // BLOQUE DE DATOS Y ESTADÍSTICAS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // BLOQUE NACIMIENTO Y EDAD DESTACADA
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: carnetColor.withAlpha(14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: carnetColor.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // NACIMIENTO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'NACIMIENTO',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      fechaNac,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // EDAD DESTACADA Y VISIBLE
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'EDAD',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: ageTextColor,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    edadTexto,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: ageTextColor,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // TRES MINI-BLOQUES DE ESTADÍSTICAS
                        Row(
                          children: [
                            Expanded(child: StatBadge.goles(jugador.goles)),
                            const SizedBox(width: 4),
                            Expanded(child: StatBadge.amarillas(jugador.amarillas)),
                            const SizedBox(width: 4),
                            Expanded(child: StatBadge.rojas(jugador.rojas)),
                          ],
                        ),

                        // BOTONES "VER FICHA" Y "ELIMINAR"
                        SizedBox(
                          height: 28,
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: Key('btn_ver_ficha_${jugador.id}'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: buttonColor,
                                    side: BorderSide(
                                      color: buttonColor,
                                      width: 1.2,
                                    ),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: onVerFicha != null
                                      ? () => onVerFicha!(jugador)
                                      : null,
                                  child: const Text(
                                    'Ver ficha',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                              if (onEliminar != null) ...[
                                const SizedBox(width: 6),
                                SizedBox(
                                  height: 28,
                                  child: OutlinedButton.icon(
                                    key: Key('btn_eliminar_carnet_${jugador.id}'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                                      backgroundColor: const Color(0xFFFEF2F2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () => onEliminar!(jugador),
                                    icon: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFDC2626)),
                                    label: const Text(
                                      'Eliminar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(Color carnetColor) {
    return Container(
      color: carnetColor.withAlpha(20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 36, color: carnetColor),
          const SizedBox(height: 2),
          Text(
            jugador.iniciales,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: carnetColor,
            ),
          ),
        ],
      ),
    );
  }
}
