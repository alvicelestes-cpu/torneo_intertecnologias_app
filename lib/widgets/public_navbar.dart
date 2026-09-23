import 'package:flutter/material.dart';

import '../core/session/session_manager.dart';
import '../equipos_page.dart';
import '../estadisticas_page.dart';
import '../goleadores_page.dart';
import '../jornadas_page.dart';
import '../partidos_page.dart';
import '../posiciones_page.dart';
import 'campeonato_selector_bar.dart';

/// Barra superior oscura (#0D1B2A / azul noche) pública con navegación horizontal,
/// logo "TORNEO INTERTECNOLOGÍAS", selector visual de torneo activo y acceso / perfil.
class PublicTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String activeRoute;

  const PublicTopNavBar({
    super.key,
    this.activeRoute = 'Inicio',
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  void _navigateTo(BuildContext context, String routeName) {
    if (activeRoute == routeName) return;

    switch (routeName) {
      case 'Inicio':
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 'Equipos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EquiposPage()),
        );
        break;
      case 'Partidos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PartidosPage()),
        );
        break;
      case 'Jornadas':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JornadasPage()),
        );
        break;
      case 'Posiciones':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PosicionesPage()),
        );
        break;
      case 'Goleadores':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GoleadoresPage()),
        );
        break;
      case 'Estadísticas':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstadisticasPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1060;
        final isCompact = width < 720;
        final isTiny = width < 460;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1B2A), // Barra superior oscura / azul noche
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTiny ? 8 : (isCompact ? 12 : 20),
            vertical: 8,
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Botón menú para móvil (abre drawer si existe) o volver si es subpantalla
                if (!isDesktop)
                  Builder(
                    builder: (ctx) {
                      final scaffold = Scaffold.maybeOf(ctx);
                      if (scaffold != null && scaffold.hasDrawer) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                            onPressed: () => scaffold.openDrawer(),
                            tooltip: 'Menú principal',
                          ),
                        );
                      }
                      if (Navigator.canPop(ctx) && activeRoute != 'Inicio') {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                            onPressed: () => Navigator.pop(ctx),
                            tooltip: 'Volver',
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                // LOGO A LA IZQUIERDA
                Flexible(
                  fit: isDesktop ? FlexFit.loose : FlexFit.tight,
                  child: InkWell(
                    onTap: () => _navigateTo(context, 'Inicio'),
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white30, width: 1.2),
                          ),
                          child: const Icon(
                            Icons.sports_soccer,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TORNEO INTERTECNOLOGÍAS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: isTiny ? 12 : (isCompact ? 13.5 : 15),
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Torneo Intertecnologías',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // MENÚ DE NAVEGACIÓN HORIZONTAL (ESCRITORIO)
                if (isDesktop) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildNavItem(context, 'Inicio', Icons.home),
                          _buildNavItem(context, 'Equipos', Icons.groups),
                          _buildNavItem(context, 'Partidos', Icons.sports_soccer),
                          _buildNavItem(context, 'Jornadas', Icons.calendar_month),
                          _buildNavItem(context, 'Posiciones', Icons.leaderboard),
                          _buildNavItem(context, 'Goleadores', Icons.emoji_events),
                          _buildNavItem(context, 'Estadísticas', Icons.bar_chart),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],

                // SELECTOR DE TORNEO Y ACCESO / PERFIL
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isTiny) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isCompact ? 125 : 170),
                        child: const CampeonatoSelectorBar(),
                      ),
                      const SizedBox(width: 8),
                    ],

                    ListenableBuilder(
                      listenable: SessionManager(),
                      builder: (context, _) {
                        final isLoggedIn = SessionManager().isAuthenticated;
                        if (isCompact) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: const EdgeInsets.all(8),
                              onPressed: () {
                                if (isLoggedIn) {
                                  Navigator.pushNamed(context, '/perfil');
                                } else {
                                  Navigator.pushNamed(context, '/login');
                                }
                              },
                              icon: Icon(
                                isLoggedIn ? Icons.person : Icons.login,
                                color: Colors.white,
                                size: 18,
                              ),
                              tooltip: isLoggedIn ? 'Perfil' : 'Iniciar sesión',
                            ),
                          );
                        }

                        return OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            backgroundColor: Colors.white.withAlpha(20),
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          onPressed: () {
                            if (isLoggedIn) {
                              Navigator.pushNamed(context, '/perfil');
                            } else {
                              Navigator.pushNamed(context, '/login');
                            }
                          },
                          icon: Icon(
                            isLoggedIn ? Icons.person : Icons.login,
                            size: 16,
                          ),
                          label: Text(
                            isLoggedIn ? 'Perfil' : 'Iniciar sesión',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, String title, IconData icon) {
    final isActive = activeRoute == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => _navigateTo(context, title),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withAlpha(35) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: Colors.white38, width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
