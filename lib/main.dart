import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'equipos_page.dart';
import 'jugadores_page.dart';
import 'partidos_page.dart';
import 'jornadas_page.dart';
import 'posiciones_page.dart';
import 'goleadores_page.dart';
import 'estadisticas_page.dart';

void main() {
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
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  final _formKey = GlobalKey<FormState>();

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
      final respuesta = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'usuario': usuarioCtrl.text.trim(),
          'contrasena': contrasenaCtrl.text,
        }),
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos =
            jsonDecode(respuesta.body);

        if (datos is! Map<String, dynamic>) {
          mostrarMensaje(
            'La respuesta del servidor no es válida.',
            esError: true,
          );
          return;
        }

        final token =
            datos['token']?.toString() ?? '';

        if (token.isEmpty) {
          mostrarMensaje(
            'El servidor no devolvió el token de acceso.',
            esError: true,
          );
          return;
        }

        final usuario =
            datos['usuario']?.toString() ??
                usuarioCtrl.text.trim();

        final rol =
            datos['rol']?.toString() ??
                'Administrador';

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InicioPage(
              token: token,
              usuario: usuario,
              rol: rol,
            ),
          ),
        );
      } else if (respuesta.statusCode == 401) {
        mostrarMensaje(
          'Usuario o contraseña incorrectos.',
          esError: true,
        );
      } else {
        mostrarMensaje(
          'No fue posible iniciar sesión. Código ${respuesta.statusCode}.',
          esError: true,
        );
      }
    } catch (e) {
      mostrarMensaje(
        'No se pudo conectar con el servidor.',
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  void mostrarMensaje(
    String mensaje, {
    bool esError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError
            ? Colors.red.shade700
            : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Card(
                elevation: 4,
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
                          color: Color(0xFF1D4F7A),
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
                          decoration:
                              const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon:
                                Icon(Icons.person),
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            if (valor == null ||
                                valor.trim().isEmpty) {
                              return 'Ingrese el usuario.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: contrasenaCtrl,
                          obscureText:
                              ocultarContrasena,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon:
                                const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  ocultarContrasena =
                                      !ocultarContrasena;
                                });
                              },
                              icon: Icon(
                                ocultarContrasena
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                            border:
                                const OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            if (valor == null ||
                                valor.isEmpty) {
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
                            onPressed: cargando
                                ? null
                                : iniciarSesion,
                            icon: cargando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.login,
                                  ),
                            label: Text(
                              cargando
                                  ? 'INGRESANDO...'
                                  : 'INICIAR SESIÓN',
                            ),
                          ),
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final opciones =
        <Map<String, dynamic>>[
      {
        'titulo': 'Equipos',
        'subtitulo':
            'Consultar equipos del torneo',
        'icono': Icons.groups,
      },
      {
        'titulo': 'Jugadores',
        'subtitulo':
            'Consultar y administrar jugadores',
        'icono': Icons.person_search,
      },
      {
        'titulo': 'Partidos',
        'subtitulo':
            'Consultar partidos',
        'icono': Icons.sports_soccer,
      },
      {
        'titulo': 'Jornadas',
        'subtitulo':
            'Consultar jornadas',
        'icono': Icons.calendar_month,
      },
      {
        'titulo': 'Posiciones',
        'subtitulo':
            'Tabla de posiciones',
        'icono': Icons.leaderboard,
      },
      {
        'titulo': 'Goleadores',
        'subtitulo':
            'Tabla de goleadores',
        'icono': Icons.emoji_events,
      },
      {
        'titulo': 'Estadísticas',
        'subtitulo':
            'Estadísticas del torneo',
        'icono': Icons.bar_chart,
      },
    ];

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text(
          'Administración',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              cerrarSesion(context);
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 32,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
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
                                style:
                                    const TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              Text(
                                'Rol: $rol',
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          tooltip: 'Cerrar sesión',
                          onPressed: () {
                            cerrarSesion(context);
                          },
                          icon: const Icon(
                            Icons.logout,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Panel principal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: opciones.length,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 165,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder:
                      (context, index) {
                    final opcion =
                        opciones[index];

                    final titulo =
                        opcion['titulo']
                            as String;

                    final subtitulo =
                        opcion['subtitulo']
                            as String;

                    final icono =
                        opcion['icono']
                            as IconData;

                    return Card(
                      elevation: 2,
                      clipBehavior:
                          Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          if (titulo ==
                              'Equipos') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EquiposPage(
                                  token: token,
                                ),
                              ),
                            );

                            return;
                          }

                          if (titulo ==
                              'Jugadores') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    JugadoresPage(
                                  token: token,
                                ),
                              ),
                            );

                            return;
                          }

                          if (titulo ==
                              'Partidos') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PartidosPage(
                                  token: token,
                                ),
                              ),
                            );

                            return;
                          }
if (titulo == 'Jornadas') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => JornadasPage(
        token: token,
      ),
    ),
  );

  return;
}
if (titulo == 'Posiciones') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PosicionesPage(
        token: token,
      ),
    ),
  );

  return;
}
if (titulo == 'Goleadores') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GoleadoresPage(
        token: token,
      ),
    ),
  );

  return;
}
if (titulo == 'Estadísticas') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EstadisticasPage(
        token: token,
      ),
    ),
  );

  return;
}
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Módulo $titulo pendiente de conectar.',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                                  18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                icono,
                                size: 40,
                                color:
                                    const Color(
                                  0xFF1D4F7A,
                                ),
                              ),

                              const Spacer(),

                              Text(
                                titulo,
                                style:
                                    const TextStyle(
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                subtitulo,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    const TextStyle(
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