import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/session/session_manager.dart';
import 'core/utils/text_utils.dart';
import 'equipos_page.dart';
import 'estadisticas_page.dart';
import 'goleadores_page.dart';
import 'jornadas_page.dart';
import 'jugadores_page.dart';
import 'partidos_page.dart';
import 'posiciones_page.dart';
import 'services/torneo_service.dart';
import 'widgets/campeonato_selector_bar.dart';

class PortalPublicoPage extends StatefulWidget {
  const PortalPublicoPage({super.key});

  @override
  State<PortalPublicoPage> createState() => _PortalPublicoPageState();
}

class _PortalPublicoPageState extends State<PortalPublicoPage> {
  final TorneoService _torneoService = TorneoService();

  bool _cargandoResumen = true;
  int _totalEquipos = 0;
  int _totalJugadores = 0;
  int _totalJornadas = 0;
  int _totalPartidos = 0;

  @override
  void initState() {
    super.initState();
    SessionManager().addListener(_onSessionChanged);
    _cargarResumen();
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      _cargarResumen();
    }
  }

  Future<void> _cargarResumen() async {
    setState(() {
      _cargandoResumen = true;
    });

    try {
      final data = await _torneoService.getResumenTorneo(
        campeonatoId: SessionManager().selectedCampeonatoId,
      );

      if (mounted) {
        setState(() {
          _totalEquipos = TextUtils.toInt(data['equipos']?['total']);
          _totalJugadores = TextUtils.toInt(data['jugadores']?['total']);
          _totalJornadas = TextUtils.toInt(data['jornadas']?['total']);
          _totalPartidos = TextUtils.toInt(data['partidos']?['total']);
          _cargandoResumen = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargandoResumen = false;
        });
      }
    }
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _cargandoResumen
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0B3C68),
                  Color(0xFF1565C0),
                  Color(0xFF1E88E5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.sports_soccer, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 14),
                const Text(
                  'TORNEO INTERTECNOLOGÍAS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                ListenableBuilder(
                  listenable: SessionManager(),
                  builder: (context, _) => Text(
                    SessionManager().selectedCampeonatoNombre,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ListTile(
                  leading: const Icon(Icons.home, color: AppColors.primary),
                  title: const Text('Inicio', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.groups, color: Color(0xFF00897B)),
                  title: const Text('Equipos', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EquiposPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Color(0xFF8E24AA)),
                  title: const Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EstadisticasPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sports_soccer, color: Color(0xFF43A047)),
                  title: const Text('Partidos', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PartidosPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.leaderboard, color: Color(0xFF1E88E5)),
                  title: const Text('Posiciones', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PosicionesPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_events, color: Color(0xFFFB8C00)),
                  title: const Text('Goleadores', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GoleadoresPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_search, color: Color(0xFF546E7A)),
                  title: const Text('Jugadores', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JugadoresPage()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.blueGrey),
                  title: const Text('Iniciar sesión / Acceso Admin', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '© ${DateTime.now().year} Torneo Intertecnologías',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _cargarResumen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado azul / degradado
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF0B3C68),
                            Color(0xFF1565C0),
                            Color(0xFF1E88E5),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(40),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.sports_soccer,
                                  size: 34,
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
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'TORNEO INTERTECNOLOGÍAS',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ListenableBuilder(
                                      listenable: SessionManager(),
                                      builder: (context, _) => Text(
                                        '${SessionManager().selectedCampeonatoNombre} • Portal Oficial de Competencia',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 14),
                          const Row(
                            children: [
                              Icon(Icons.public, color: Colors.white70, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Consulta pública oficial de equipos, jugadores, partidos, posiciones y estadísticas.',
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

                  // Resumen visible del torneo
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return GridView.count(
                        crossAxisCount: isMobile ? 2 : 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isMobile ? 1.6 : 1.9,
                        children: [
                          _buildMetricCard(
                            icon: Icons.groups,
                            label: 'EQUIPOS',
                            value: _totalEquipos,
                            color: const Color(0xFF00897B),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EquiposPage()),
                              );
                            },
                          ),
                          _buildMetricCard(
                            icon: Icons.person,
                            label: 'JUGADORES',
                            value: _totalJugadores,
                            color: const Color(0xFF1E88E5),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const JugadoresPage()),
                              );
                            },
                          ),
                          _buildMetricCard(
                            icon: Icons.calendar_month,
                            label: 'JORNADAS',
                            value: _totalJornadas,
                            color: const Color(0xFF5E35B1),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const JornadasPage()),
                              );
                            },
                          ),
                          _buildMetricCard(
                            icon: Icons.sports_soccer,
                            label: 'PARTIDOS',
                            value: _totalPartidos,
                            color: const Color(0xFFFB8C00),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PartidosPage()),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Selector de campeonato activo
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                    'Explorar Torneo',
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
                            padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 32),

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
      ),
    );
  }
}
