import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/ui_helpers.dart';
import 'services/auth_service.dart';

import 'crear_jugador_page.dart';
import 'equipos_page.dart';
import 'estadisticas_page.dart';
import 'goleadores_page.dart';
import 'jornadas_page.dart';
import 'jugadores_page.dart';
import 'partidos_page.dart';
import 'portal_publico_page.dart';
import 'posiciones_page.dart';
import 'widgets/campeonato_selector_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager().init();
  runApp(const TorneoApp());
}

class TorneoApp extends StatelessWidget {
  const TorneoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Torneo Intertecnologías',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const PortalPublicoPage(),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        final path = uri.path;

        if (path == '/admin' || path == '/login') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const LoginPage(),
          );
        }

        if (path == '/inicio' || path == '/perfil' || path == '/admin-panel') {
          final session = SessionManager();
          if (session.isAuthenticated && session.currentUser != null) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => InicioPage(
                token: session.token,
                usuario: session.currentUser!.usuario,
                rol: session.currentUser!.rol,
              ),
            );
          }
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const LoginPage(),
          );
        }

        if (path == '/equipos') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const EquiposPage(),
          );
        }
        if (path == '/partidos') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const PartidosPage(),
          );
        }
        if (path == '/jornadas') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const JornadasPage(),
          );
        }
        if (path == '/posiciones') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const PosicionesPage(),
          );
        }
        if (path == '/goleadores') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const GoleadoresPage(),
          );
        }
        if (path == '/estadisticas') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const EstadisticasPage(),
          );
        }
        if (path == '/jugadores') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const JugadoresPage(),
          );
        }

        if (path == '/crear-jugador' ||
            path == '/inscribir-jugador' ||
            path == '/nuevo-jugador') {
          final session = SessionManager();
          if (session.hasAdminAccess) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => CrearJugadorPage(token: session.token),
            );
          }
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const LoginPage(),
          );
        }

        // Por defecto: / o cualquier otra ruta va al portal público
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PortalPublicoPage(),
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final usuarioCtrl = TextEditingController();
  final contrasenaCtrl = TextEditingController();

  bool cargando = false;
  bool ocultarContrasena = true;

  @override
  void dispose() {
    usuarioCtrl.dispose();
    contrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final authUser = await _authService.login(
        usuario: usuarioCtrl.text.trim(),
        contrasena: contrasenaCtrl.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InicioPage(
            token: authUser.token,
            usuario: authUser.usuario,
            rol: authUser.rol,
          ),
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      UiHelpers.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      UiHelpers.showError(context, 'No se pudo conectar con el servidor.');
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sports_soccer,
                          size: 72,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Torneo Intertecnologías',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Panel de administración',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: usuarioCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            if (valor == null || valor.trim().isEmpty) {
                              return 'Ingrese el usuario.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: contrasenaCtrl,
                          obscureText: ocultarContrasena,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  ocultarContrasena = !ocultarContrasena;
                                });
                              },
                              icon: Icon(
                                ocultarContrasena
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            if (valor == null || valor.isEmpty) {
                              return 'Ingrese la contraseña.';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            if (!cargando) {
                              iniciarSesion();
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: cargando ? null : iniciarSesion,
                            icon: cargando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(
                              cargando ? 'INGRESANDO...' : 'INICIAR SESIÓN',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          },
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('← Volver al Portal Público'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InicioPage extends StatelessWidget {
  final String token;
  final String usuario;
  final String rol;

  const InicioPage({
    super.key,
    required this.token,
    required this.usuario,
    required this.rol,
  });

  void cerrarSesion(BuildContext context) {
    SessionManager().clearSession();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final opciones = <Map<String, dynamic>>[
      {
        'titulo': 'Equipos',
        'subtitulo': 'Consultar equipos del torneo',
        'icono': Icons.groups,
      },
      {
        'titulo': 'Jugadores',
        'subtitulo': 'Consultar y administrar jugadores',
        'icono': Icons.person_search,
      },
      {
        'titulo': 'Partidos',
        'subtitulo': 'Consultar partidos',
        'icono': Icons.sports_soccer,
      },
      {
        'titulo': 'Jornadas',
        'subtitulo': 'Consultar jornadas',
        'icono': Icons.calendar_month,
      },
      {
        'titulo': 'Posiciones',
        'subtitulo': 'Tabla de posiciones',
        'icono': Icons.leaderboard,
      },
      {
        'titulo': 'Goleadores',
        'subtitulo': 'Tabla de goleadores',
        'icono': Icons.emoji_events,
      },
      {
        'titulo': 'Estadísticas',
        'subtitulo': 'Estadísticas del torneo',
        'icono': Icons.bar_chart,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Administración'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Ir al Portal Público',
          icon: const Icon(Icons.public),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => cerrarSesion(context),
            icon: const Icon(Icons.logout),
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
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bienvenido',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                usuario,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rol: $rol',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar sesión',
                          onPressed: () => cerrarSesion(context),
                          icon: const Icon(Icons.logout),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Text(
                      'Torneo activo:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CampeonatoSelectorBar(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Panel principal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: opciones.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 165,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final opcion = opciones[index];
                    final titulo = opcion['titulo'] as String;
                    final subtitulo = opcion['subtitulo'] as String;
                    final icono = opcion['icono'] as IconData;

                    return Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: InkWell(
                        onTap: () {
                          Widget destination;
                          switch (titulo) {
                            case 'Equipos':
                              destination = EquiposPage(token: token);
                              break;
                            case 'Jugadores':
                              destination = JugadoresPage(token: token);
                              break;
                            case 'Partidos':
                              destination = PartidosPage(token: token);
                              break;
                            case 'Jornadas':
                              destination = JornadasPage(token: token);
                              break;
                            case 'Posiciones':
                              destination = PosicionesPage(token: token);
                              break;
                            case 'Goleadores':
                              destination = GoleadoresPage(token: token);
                              break;
                            case 'Estadísticas':
                              destination = EstadisticasPage(token: token);
                              break;
                            default:
                              UiHelpers.showSnackBar(
                                context,
                                'Módulo $titulo pendiente de conectar.',
                              );
                              return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => destination),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                icono,
                                size: 40,
                                color: AppColors.primary,
                              ),
                              const Spacer(),
                              Text(
                                titulo,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}