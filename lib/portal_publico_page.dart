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
import 'widgets/public_navbar.dart';

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
      elevation: 2.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withAlpha(80), width: 1.2),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _cargandoResumen
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '$value',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0D233A),
                              ),
                            ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
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
                  Color(0xFF0D233A),
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
                  leading: Icon(
                    SessionManager().isAuthenticated
                        ? Icons.admin_panel_settings
                        : Icons.admin_panel_settings_outlined,
                    color: Colors.blueGrey,
                  ),
                  title: Text(
                    SessionManager().isAuthenticated
                        ? 'Panel de Administración'
                        : 'Iniciar sesión / Acceso Admin',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (SessionManager().isAuthenticated) {
                      Navigator.pushNamed(context, '/inicio');
                    } else {
                      Navigator.pushNamed(context, '/login');
                    }
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

  void _mostrarAcercaDelTorneo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 24),
            SizedBox(width: 10),
            Text(
              'Acerca del Torneo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListenableBuilder(
                listenable: SessionManager(),
                builder: (context, _) => Text(
                  SessionManager().selectedCampeonatoNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF0D233A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Torneo oficial intertecnologías con control deportivo de planteles, partidos por jornadas, tabla de posiciones en tiempo real, estadísticas oficiales y carnets deportivos de futbolistas organizados por rangos de edad:\n\n'
                '• 🟢 Mayores de 40 años (Verde #2E7D32)\n'
                '• 🟠 Entre 35 y 39 años (Naranja #E65100)\n'
                '• 🔵 De 18 a 34 años (Azul #1565C0)\n\n'
                'Control multitorneo independiente, estadísticas en vivo y portal público de consulta deportiva.',
                style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modulos = <Map<String, dynamic>>[
      {
        'titulo': 'Equipos',
        'subtitulo': 'Clubes y plantillas oficiales',
        'icono': Icons.groups,
        'color': const Color(0xFF2E7D32),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EquiposPage()),
        ),
      },
      {
        'titulo': 'Partidos',
        'subtitulo': 'Calendario y resultados oficiales',
        'icono': Icons.sports_soccer,
        'color': const Color(0xFFE65100),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PartidosPage()),
        ),
      },
      {
        'titulo': 'Jornadas',
        'subtitulo': 'Partidos agrupados por jornada',
        'icono': Icons.calendar_month,
        'color': const Color(0xFF7B1FA2),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JornadasPage()),
        ),
      },
      {
        'titulo': 'Posiciones',
        'subtitulo': 'Tabla de posiciones en vivo',
        'icono': Icons.leaderboard,
        'color': const Color(0xFF1565C0),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PosicionesPage()),
        ),
      },
      {
        'titulo': 'Goleadores',
        'subtitulo': 'Clasificación de máximos artilleros',
        'icono': Icons.emoji_events,
        'color': const Color(0xFFF57C00),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GoleadoresPage()),
        ),
      },
      {
        'titulo': 'Estadísticas',
        'subtitulo': 'Valla menos vencida y Fair Play',
        'icono': Icons.bar_chart,
        'color': const Color(0xFF8E24AA),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstadisticasPage()),
        ),
      },
      {
        'titulo': 'Jugadores (Carnets)',
        'subtitulo': 'Carnets oficiales ordenados por edad',
        'icono': Icons.badge_outlined,
        'color': const Color(0xFF0277BD),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JugadoresPage()),
        ),
      },
      {
        'titulo': 'Acerca del Torneo',
        'subtitulo': 'Reglamento, sedes e información oficial',
        'icono': Icons.info_outline,
        'color': const Color(0xFF37474F),
        'onTap': () => _mostrarAcercaDelTorneo(context),
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const PublicTopNavBar(activeRoute: 'Inicio'),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _cargarResumen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 500 ? 12 : 20,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ENCABEZADO AZUL CON GRAN PRESENCIA
                  const PublicHeaderBanner(),
                  const SizedBox(height: 16),

                  // 4 MÉTRICAS CON VIDA Y CONTRASTE (Verde, Azul, Morado, Naranja)
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
                            color: const Color(0xFF2E7D32), // Verde
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
                            color: const Color(0xFF1565C0), // Azul
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
                            color: const Color(0xFF7B1FA2), // Morado
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
                            color: const Color(0xFFE65100), // Naranja
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

                  // SELECTOR DE CAMPEONATO ACTIVO (FILTRADO PARA PÚBLICO)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    color: Colors.white,
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
                              color: Color(0xFF0D233A),
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

                  // TÍTULO DE SECCIONES
                  const Text(
                    'Explora el Torneo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D233A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GRID DE MÓDULOS CON CONTRASTE Y VIDA
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
                      final onTap = modulo['onTap'] as VoidCallback;

                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        color: Colors.white,
                        child: InkWell(
                          onTap: onTap,
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
                                      backgroundColor: color.withAlpha(25),
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
                                    color: Color(0xFF0D233A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitulo,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
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

                  // PIE DE PÁGINA
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

class PublicHeaderBanner extends StatelessWidget {
  const PublicHeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isVerySmall = cardWidth < 380;
        final isMobile = cardWidth < 600;

        final double titleFontSize = isVerySmall
            ? 18.0
            : (isMobile
                ? 20.0
                : (cardWidth < 800 ? 23.0 : 26.0));
        final double letterSpacing =
            isVerySmall ? 0.4 : (isMobile ? 0.6 : 0.8);

        final double iconBoxSize =
            isVerySmall ? 44.0 : (isMobile ? 50.0 : 58.0);
        final double iconSize =
            isVerySmall ? 26.0 : (isMobile ? 30.0 : 36.0);
        final double iconSpacing =
            isVerySmall ? 10.0 : (isMobile ? 12.0 : 16.0);

        final EdgeInsets cardPadding = EdgeInsets.all(
          isVerySmall ? 14.0 : (isMobile ? 18.0 : 24.0),
        );

        final double spaceTitleToSubtitle = isVerySmall ? 8.0 : 10.0;
        final double spaceSubtitleToDivider = isVerySmall ? 16.0 : 20.0;
        final double spaceDividerToFooter = isVerySmall ? 12.0 : 14.0;

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D233A),
                  Color(0xFF1565C0),
                  Color(0xFF1E88E5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -25,
                  bottom: -35,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.10,
                      child: Icon(
                        Icons.sports_soccer,
                        size: isVerySmall ? 110 : 160,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(
                          isVerySmall ? 12 : 16,
                        ),
                        border: Border.all(
                          color: Colors.white30,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        size: iconSize,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: iconSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PORTAL DEL TORNEO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TORNEO INTERTECNOLOGÍAS',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: letterSpacing,
                              height: 1.15,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            maxLines: 2,
                          ),
                          SizedBox(height: spaceTitleToSubtitle),
                          ListenableBuilder(
                            listenable: SessionManager(),
                            builder: (context, _) => Text(
                              SessionManager().selectedCampeonatoNombre,
                              style: TextStyle(
                                fontSize: isVerySmall
                                    ? 13.0
                                    : (isMobile ? 14.0 : 15.0),
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(235),
                                letterSpacing: 0.3,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spaceSubtitleToDivider),
                const Divider(color: Colors.white24, height: 1),
                SizedBox(height: spaceDividerToFooter),
                Row(
                  children: [
                    const Icon(Icons.public, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Consulta pública oficial de equipos, jugadores, partidos, posiciones y estadísticas.',
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: isVerySmall ? 12 : 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
      },
    );
  }
}
