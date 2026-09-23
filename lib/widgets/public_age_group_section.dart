import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/jugador.dart';
import 'public_player_card.dart';

class PublicAgeGroupSection extends StatelessWidget {
  final String titulo;
  final int cantidad;
  final Color color;
  final List<Color>? coloresGradiente;
  final List<Jugador> jugadores;
  final IconData icono;
  final void Function(Jugador jugador)? onVerFicha;

  const PublicAgeGroupSection({
    super.key,
    required this.titulo,
    required this.cantidad,
    required this.color,
    this.coloresGradiente,
    required this.jugadores,
    this.icono = Icons.sports_soccer,
    this.onVerFicha,
  });

  factory PublicAgeGroupSection.fromGroup({
    Key? key,
    required AgeGroup group,
    required List<Jugador> jugadores,
    void Function(Jugador jugador)? onVerFicha,
  }) {
    return PublicAgeGroupSection(
      key: key,
      titulo: group.title,
      cantidad: jugadores.length,
      color: group.color,
      coloresGradiente: group.gradientColors,
      jugadores: jugadores,
      icono: Icons.sports_soccer,
      onVerFicha: onVerFicha,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (jugadores.isEmpty) {
      return const SizedBox.shrink();
    }

    final gradientList = coloresGradiente ??
        [
          color,
          Color.lerp(color, const Color(0xFF0D233A), 0.35) ?? color,
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CABECERA DEPORTIVA DEL GRUPO DE EDAD
        Card(
          elevation: 2.5,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientList,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Decoración deportiva de balón en segundo plano a la derecha (no tapa el texto)
                Positioned(
                  right: -10,
                  top: -14,
                  bottom: -14,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.13,
                      child: Icon(
                        icono,
                        size: 88,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Contenido de la cabecera
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Icono deportivo en caja blanca traslúcida
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white30, width: 1.2),
                        ),
                        child: Icon(
                          icono,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Título del grupo (Mayores de 40 años, etc.)
                      Expanded(
                        child: Text(
                          titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Conteo visible de jugadores
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                        child: Text(
                          '($cantidad ${cantidad == 1 ? 'jugador' : 'jugadores'})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
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

        // GRID RESPONSIVE DE CARNETS
        // Escritorio: 3 carnets por fila
        // Tablet: 2 por fila
        // Móvil: 1 por fila
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final int crossAxisCount;
            if (width < 640) {
              crossAxisCount = 1;
            } else if (width < 1050) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 3;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 215,
              ),
              itemCount: jugadores.length,
              itemBuilder: (context, index) {
                return PublicPlayerCard(
                  jugador: jugadores[index],
                  onVerFicha: onVerFicha,
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
