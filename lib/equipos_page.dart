import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'jugadores_equipo_page.dart';

class EquiposPage extends StatefulWidget {
  final String token;

  const EquiposPage({
    super.key,
    required this.token,
  });

  @override
  State<EquiposPage> createState() => _EquiposPageState();
}

class _EquiposPageState extends State<EquiposPage> {
  static const String equiposUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app/api/equipos';

  bool cargando = true;
  String? error;

  List<dynamic> equipos = [];

  @override
  void initState() {
    super.initState();
    cargarEquipos();
  }

  Future<void> cargarEquipos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http.get(
        Uri.parse(equiposUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos = jsonDecode(respuesta.body);

        if (datos is List) {
          setState(() {
            equipos = datos;
          });
        } else {
          setState(() {
            error =
                'La respuesta del servidor no tiene el formato esperado.';
          });
        }
      } else if (respuesta.statusCode == 401) {
        setState(() {
          error =
              'Sesión no autorizada o token vencido.';
        });
      } else {
        setState(() {
          error =
              'No fue posible cargar los equipos. Código ${respuesta.statusCode}.';
        });
      }
    } catch (e) {
      setState(() {
        error =
            'No se pudo conectar con el servidor.';
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  String obtenerIniciales(
      Map<String, dynamic> equipo) {
    final sigla =
        equipo['sigla']?.toString().trim() ?? '';

    if (sigla.isNotEmpty) {
      return sigla.length >= 2
          ? sigla.substring(0, 2).toUpperCase()
          : sigla.toUpperCase();
    }

    final nombre =
        equipo['nombre']?.toString().trim() ?? '';

    if (nombre.isEmpty) {
      return 'FC';
    }

    final partes = nombre
        .split(' ')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'
          .toUpperCase();
    }

    return nombre.length >= 2
        ? nombre.substring(0, 2).toUpperCase()
        : nombre.toUpperCase();
  }

  bool logoValido(dynamic logo) {
    if (logo == null) {
      return false;
    }

    final valor = logo.toString().trim();

    if (valor.isEmpty) {
      return false;
    }

    if (valor.toLowerCase() == 'string') {
      return false;
    }

    return valor.startsWith('http://') ||
        valor.startsWith('https://');
  }

  Widget construirIniciales(
      Map<String, dynamic> equipo) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        obtenerIniciales(equipo),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D4F7A),
        ),
      ),
    );
  }

  Widget construirLogo(
      Map<String, dynamic> equipo) {
    final logo = equipo['logo'];

    if (!logoValido(logo)) {
      return construirIniciales(equipo);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        logo.toString(),
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return construirIniciales(equipo);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text('Equipos'),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: cargarEquipos,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (error != null) {
              return ListView(
                padding:
                    const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),

                  const Icon(
                    Icons.error_outline,
                    size: 70,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 18),

                  Text(
                    error!,
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child:
                        FilledButton.icon(
                      onPressed:
                          cargarEquipos,
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label: const Text(
                        'REINTENTAR',
                      ),
                    ),
                  ),
                ],
              );
            }

            if (equipos.isEmpty) {
              return const Center(
                child: Text(
                  'No hay equipos registrados.',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding:
                  const EdgeInsets.all(16),

              itemCount: equipos.length,

              separatorBuilder:
                  (_, __) =>
                      const SizedBox(
                          height: 10),

              itemBuilder:
                  (context, index) {
                final equipo =
                    Map<String, dynamic>.from(
                  equipos[index],
                );

                final int? equipoId =
                    equipo['id'] is int
                        ? equipo['id']
                        : int.tryParse(
                            equipo['id']
                                    ?.toString() ??
                                '',
                          );

                final nombre =
                    equipo['nombre']
                            ?.toString() ??
                        'Sin nombre';

                final sigla =
                    equipo['sigla']
                            ?.toString() ??
                        '';

                return Card(
                  elevation: 2,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.all(14),

                    leading:
                        construirLogo(equipo),

                    title: Text(
                      nombre,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),

                    subtitle:
                        sigla.isNotEmpty
                            ? Text(sigla)
                            : null,

                    trailing:
                        const Icon(
                      Icons.chevron_right,
                    ),

                    onTap: () {
                      if (equipoId == null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'El equipo no tiene un ID válido.',
                            ),
                          ),
                        );

                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JugadoresEquipoPage(
                            equipoId:
                                equipoId,
                            equipoNombre:
                                nombre,
                            token:
                                widget.token,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}