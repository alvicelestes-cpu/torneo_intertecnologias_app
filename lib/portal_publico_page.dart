import 'package:flutter/material.dart';

import 'configuracion_torneo_page.dart';
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
                if (SessionManager().hasAdminAccess)
                  ListTile(
                    leading: const Icon(Icons.tune, color: Color(0xFF1E88E5)),
                    title: const Text(
                      '⚙️ Configuración del Torneo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConfiguracionTorneoPage(token: SessionManager().token),
                        ),
                      );
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
        'subtitulo': 'Conoce los clubes y sus plantillas',
        'icono': Icons.groups,
        'color': const Color(0xFF2E7D32),
        'bgPastilla': const Color(0xFFE8F5E9),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EquiposPage()),
        ),
      },
      {
        'titulo': 'Partidos',
        'subtitulo': 'Calendario y resultados',
        'icono': Icons.sports_soccer,
        'color': const Color(0xFF2E7D32),
        'bgPastilla': const Color(0xFFE8F5E9),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PartidosPage()),
        ),
      },
      {
        'titulo': 'Jornadas',
        'subtitulo': 'Partidos por jornada',
        'icono': Icons.calendar_month,
        'color': const Color(0xFF7B1FA2),
        'bgPastilla': const Color(0xFFF3E5F5),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JornadasPage()),
        ),
      },
      {
        'titulo': 'Posiciones',
        'subtitulo': 'Tabla en tiempo real',
        'icono': Icons.sports_soccer,
        'color': const Color(0xFFFFA000),
        'bgPastilla': const Color(0xFFFFF8E1),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PosicionesPage()),
        ),
      },
      {
        'titulo': 'Goleadores',
        'subtitulo': 'Máximos artilleros',
        'icono': Icons.emoji_events,
        'color': const Color(0xFFE65100),
        'bgPastilla': const Color(0xFFFFF3E0),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GoleadoresPage()),
        ),
      },
      {
        'titulo': 'Estadísticas',
        'subtitulo': 'Datos y rendimiento',
        'icono': Icons.bar_chart,
        'color': const Color(0xFF8E24AA),
        'bgPastilla': const Color(0xFFEDE7F6),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstadisticasPage()),
        ),
      },
      {
        'titulo': 'Jugadores',
        'subtitulo': 'Carnets deportivos',
        'icono': Icons.person,
        'color': const Color(0xFF546E7A),
        'bgPastilla': const Color(0xFFECEFF1),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JugadoresPage()),
        ),
      },
      {
        'titulo': 'Acerca del Torneo',
        'subtitulo': 'Información general',
        'icono': Icons.info,
        'color': const Color(0xFF0288D1),
        'bgPastilla': const Color(0xFFE1F5FE),
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
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER BANNER CON FONDO DE ESTADIO, BALÓN Y MÉTRICAS TRANSLÚCIDAS
                  PublicHeaderBanner(
                    totalEquipos: _totalEquipos,
                    totalJugadores: _totalJugadores,
                    totalJornadas: _totalJornadas,
                    totalPartidos: _totalPartidos,
                    cargando: _cargandoResumen,
                    onEquiposTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EquiposPage()),
                      );
                    },
                    onJugadoresTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JugadoresPage()),
                      );
                    },
                    onJornadasTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JornadasPage()),
                      );
                    },
                    onPartidosTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PartidosPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // SELECTOR DE CAMPEONATO ACTIVO (FILTRADO PARA PÚBLICO)
                  Card(
                    elevation: 1.5,
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

                  // TÍTULO DE SECCIÓN
                  const Text(
                    'Explora el Torneo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D233A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GRID DE MÓDULOS CON PASTILLAS CIRCULARES DE COLORES
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modulos.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisExtent: 168,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemBuilder: (context, index) {
                      final modulo = modulos[index];
                      final titulo = modulo['titulo'] as String;
                      final subtitulo = modulo['subtitulo'] as String;
                      final icono = modulo['icono'] as IconData;
                      final color = modulo['color'] as Color;
                      final bgPastilla = modulo['bgPastilla'] as Color;
                      final onTap = modulo['onTap'] as VoidCallback;

                      return Card(
                        elevation: 1.5,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: bgPastilla,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(icono, color: color, size: 22),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      titulo,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D233A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      subtitulo,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
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
  final int totalEquipos;
  final int totalJugadores;
  final int totalJornadas;
  final int totalPartidos;
  final bool cargando;
  final VoidCallback? onEquiposTap;
  final VoidCallback? onJugadoresTap;
  final VoidCallback? onJornadasTap;
  final VoidCallback? onPartidosTap;

  const PublicHeaderBanner({
    super.key,
    this.totalEquipos = 8,
    this.totalJugadores = 110,
    this.totalJornadas = 7,
    this.totalPartidos = 28,
    this.cargando = false,
    this.onEquiposTap,
    this.onJugadoresTap,
    this.onJornadasTap,
    this.onPartidosTap,
  });

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required VoidCallback? onTap,
    required bool isSmall,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 8 : 10,
            vertical: isSmall ? 5 : 7,
          ),
          decoration: BoxDecoration(
            color: color.withAlpha(210),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withAlpha(50),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isSmall ? 28 : 34,
                height: isSmall ? 28 : 34,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isSmall ? 16 : 19,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    cargando
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '$value',
                            style: TextStyle(
                              fontSize: isSmall ? 16 : 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: isSmall ? 9.0 : 10.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withAlpha(220),
                        letterSpacing: 0.5,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isVerySmall = cardWidth < 400;
        final isMobile = cardWidth < 600;

        final double titleFontSize = isVerySmall
            ? 18.0
            : (isMobile
                ? 21.0
                : (cardWidth < 800 ? 24.0 : 27.0));

        final EdgeInsets cardPadding = EdgeInsets.all(
          isVerySmall ? 12.0 : (isMobile ? 16.0 : 22.0),
        );

        final metricEquipos = _buildMetricCard(
          icon: Icons.groups,
          label: 'EQUIPOS',
          value: totalEquipos,
          color: const Color(0xFF00695C),
          onTap: onEquiposTap,
          isSmall: isVerySmall,
        );

        final metricJugadores = _buildMetricCard(
          icon: Icons.person,
          label: 'JUGADORES',
          value: totalJugadores,
          color: const Color(0xFF1565C0),
          onTap: onJugadoresTap,
          isSmall: isVerySmall,
        );

        final metricJornadas = _buildMetricCard(
          icon: Icons.calendar_month,
          label: 'JORNADAS',
          value: totalJornadas,
          color: const Color(0xFF6A1B9A),
          onTap: onJornadasTap,
          isSmall: isVerySmall,
        );

        final metricPartidos = _buildMetricCard(
          icon: Icons.sports_soccer,
          label: 'PARTIDOS',
          value: totalPartidos,
          color: const Color(0xFFE65100),
          onTap: onPartidosTap,
          isSmall: isVerySmall,
        );

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
                // Foto de fondo del estadio iluminado con balón a la derecha
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/banner_home.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),

                // Gradiente oscuro superpuesto para garantizar alto contraste
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withAlpha(160),
                          Colors.black.withAlpha(70),
                          Colors.black.withAlpha(130),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),

                // Contenido del Banner
                Padding(
                  padding: cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera: Adaptable verticalmente para móvil (< 600px) y horizontal para escritorio
                      if (isMobile)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Logotipo con escudo de balón a la izquierda
                                Container(
                                  width: isVerySmall ? 40.0 : 46.0,
                                  height: isVerySmall ? 40.0 : 46.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withAlpha(45),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(70),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.sports_soccer,
                                    size: isVerySmall ? 22.0 : 26.0,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(35),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PORTAL DEL TORNEO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Título adaptado a todo el ancho sin compresión
                            Text(
                              'TORNEO INTERTECNOLOGÍAS',
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.6,
                                height: 1.15,
                              ),
                              softWrap: true,
                            ),
                            const SizedBox(height: 4),
                            ListenableBuilder(
                              listenable: SessionManager(),
                              builder: (context, _) => Text(
                                SessionManager().selectedCampeonatoNombre,
                                style: TextStyle(
                                  fontSize: isVerySmall ? 13.0 : 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(235),
                                ),
                                softWrap: true,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pasión, tecnología y deporte en un solo torneo',
                              style: TextStyle(
                                color: Colors.white.withAlpha(210),
                                fontSize: isVerySmall ? 11.0 : 12.5,
                                fontStyle: FontStyle.italic,
                              ),
                              softWrap: true,
                            ),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logotipo con escudo de balón a la izquierda
                            Container(
                              width: 54.0,
                              height: 54.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(45),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(70),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sports_soccer,
                                size: 32.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Badge PORTAL DEL TORNEO
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(35),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'PORTAL DEL TORNEO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Título: TORNEO INTERTECNOLOGÍAS
                                  Text(
                                    'TORNEO INTERTECNOLOGÍAS',
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                      height: 1.15,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 4),

                                  // Subtítulo
                                  ListenableBuilder(
                                    listenable: SessionManager(),
                                    builder: (context, _) => Text(
                                      SessionManager().selectedCampeonatoNombre,
                                      style: const TextStyle(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      maxLines: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),

                                  // Lema
                                  Text(
                                    'Pasión, tecnología y deporte en un solo torneo',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(210),
                                      fontSize: 13.0,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: isMobile ? 16.0 : 24.0),

                      // Cuadrícula de 2x2 para móvil (< 600px) y fila horizontal de 4 para escritorio
                      if (isMobile)
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            mainAxisExtent: isVerySmall ? 58 : 64,
                          ),
                          children: [
                            metricEquipos,
                            metricJugadores,
                            metricJornadas,
                            metricPartidos,
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: metricEquipos),
                            const SizedBox(width: 10),
                            Expanded(child: metricJugadores),
                            const SizedBox(width: 10),
                            Expanded(child: metricJornadas),
                            const SizedBox(width: 10),
                            Expanded(child: metricPartidos),
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

