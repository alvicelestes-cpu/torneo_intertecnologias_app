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

  const PublicPlayerCard({
    super.key,
    required this.jugador,
    this.onVerFicha,
  });

  @override
  Widget build(BuildContext context) {
    final edad = jugador.edad;
    final carnetColor = getColorByAge(edad);

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
                colors: [
                  carnetColor,
                  Color.lerp(carnetColor, const Color(0xFF0D233A), 0.35) ?? carnetColor,
                ],
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
                        style: const TextStyle(
                          color: Colors.white70,
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
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${jugador.numeroCamiseta}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
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
                                      color: carnetColor,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    edadTexto,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: carnetColor,
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

                        // BOTÓN "VER FICHA"
                        SizedBox(
                          height: 28,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: carnetColor,
                              side: BorderSide(
                                color: carnetColor,
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
