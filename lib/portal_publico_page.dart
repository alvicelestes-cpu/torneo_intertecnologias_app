import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/session/session_manager.dart';
import 'equipos_page.dart';
import 'estadisticas_page.dart';
import 'goleadores_page.dart';
import 'jornadas_page.dart';
import 'jugadores_page.dart';
import 'partidos_page.dart';
import 'posiciones_page.dart';
import 'widgets/campeonato_selector_bar.dart';

class PortalPublicoPage extends StatelessWidget {
  const PortalPublicoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final modulos = <Map<String, dynamic>>[
      {
        'titulo': 'Posiciones',
        'subtitulo': 'Tabla de posiciones en vivo',
        'icono': Icons.leaderboard,
        'color': const Color(0xFF1E88E5),
        'builder': (BuildContext ctx) => const PosicionesPage(),
      },
      {
        'titulo': 'Partidos',
        'subtitulo': 'Calendario y resultados',
        'icono': Icons.sports_soccer,
        'color': const Color(0xFF43A047),
        'builder': (BuildContext ctx) => const PartidosPage(),
      },
      {
        'titulo': 'Jornadas',
        'subtitulo': 'Partidos por jornada',
        'icono': Icons.calendar_month,
        'color': const Color(0xFF5E35B1),
        'builder': (BuildContext ctx) => const JornadasPage(),
      },
      {
        'titulo': 'Goleadores',
        'subtitulo': 'Tabla de goleadores',
        'icono': Icons.emoji_events,
        'color': const Color(0xFFFB8C00),
        'builder': (BuildContext ctx) => const GoleadoresPage(),
      },
      {
        'titulo': 'Estadísticas',
        'subtitulo': 'Rendimiento y tarjetas',
        'icono': Icons.bar_chart,
        'color': const Color(0xFF8E24AA),
        'builder': (BuildContext ctx) => const EstadisticasPage(),
      },
      {
        'titulo': 'Equipos',
        'subtitulo': 'Equipos participantes',
        'icono': Icons.groups,
        'color': const Color(0xFF00897B),
        'builder': (BuildContext ctx) => const EquiposPage(),
      },
      {
        'titulo': 'Jugadores',
        'subtitulo': 'Plantel de futbolistas',
        'icono': Icons.person_search,
        'color': const Color(0xFF546E7A),
        'builder': (BuildContext ctx) => const JugadoresPage(),
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Torneo Intertecnologías',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
              label: const Text(
                'Acceso Admin',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner principal
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withAlpha(210),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.sports_soccer,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PORTAL DEL TORNEO',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ListenableBuilder(
                                    listenable: SessionManager(),
                                    builder: (context, _) => Text(
                                      SessionManager().selectedCampeonatoNombre,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white70, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Consulta libre de partidos, resultados, posiciones y estadísticas.',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de campeonato activo
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.tune, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Campeonato:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: CampeonatoSelectorBar(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Título de secciones
                const Text(
                  'Consulta del Torneo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Grid de módulos
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: modulos.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 180,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final modulo = modulos[index];
                    final titulo = modulo['titulo'] as String;
                    final subtitulo = modulo['subtitulo'] as String;
                    final icono = modulo['icono'] as IconData;
                    final color = modulo['color'] as Color;
                    final builder = modulo['builder'] as WidgetBuilder;

                    return Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: builder),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: color.withAlpha(30),
                                    child: Icon(icono, color: color, size: 22),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.black38,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                titulo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitulo,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Pie de página
                Center(
                  child: Text(
                    '© ${DateTime.now().year} Torneo Intertecnologías • Información oficial',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
