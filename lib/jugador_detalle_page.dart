import 'package:flutter/material.dart';

import 'editar_jugador_page.dart';

class JugadorDetallePage extends StatefulWidget {
  final Map<String, dynamic> jugador;
  final String equipoNombre;
  final String token;

  const JugadorDetallePage({
    super.key,
    required this.jugador,
    required this.equipoNombre,
    required this.token,
  });

  @override
  State<JugadorDetallePage> createState() =>
      _JugadorDetallePageState();
}

class _JugadorDetallePageState
    extends State<JugadorDetallePage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  late Map<String, dynamic> jugador;

  @override
  void initState() {
    super.initState();

    jugador = Map<String, dynamic>.from(
      widget.jugador,
    );
  }

  String obtenerFotoUrl(dynamic fotoJugador) {
    if (fotoJugador == null) {
      return '';
    }

    final valor =
        fotoJugador.toString().trim();

    if (valor.isEmpty ||
        valor.toLowerCase() == 'string') {
      return '';
    }

    if (valor.startsWith('http://') ||
        valor.startsWith('https://')) {
      return valor;
    }

    if (valor.startsWith('/')) {
      return '$baseUrl$valor';
    }

    return '$baseUrl/$valor';
  }

  String obtenerIniciales() {
    final nombres =
        jugador['nombres']
                ?.toString()
                .trim() ??
            '';

    final apellidos =
        jugador['apellidos']
                ?.toString()
                .trim() ??
            '';

    String iniciales = '';

    if (nombres.isNotEmpty) {
      iniciales += nombres[0];
    }

    if (apellidos.isNotEmpty) {
      iniciales += apellidos[0];
    }

    if (iniciales.isEmpty) {
      return 'JG';
    }

    return iniciales.toUpperCase();
  }

  String formatearFecha(dynamic fecha) {
    if (fecha == null) {
      return 'No registrada';
    }

    final valor =
        fecha.toString().trim();

    if (valor.isEmpty) {
      return 'No registrada';
    }

    final date =
        DateTime.tryParse(valor);

    if (date == null) {
      return valor;
    }

    final dia =
        date.day
            .toString()
            .padLeft(2, '0');

    final mes =
        date.month
            .toString()
            .padLeft(2, '0');

    final anio =
        date.year.toString();

    return '$dia/$mes/$anio';
  }

  int? obtenerJugadorId() {
    if (jugador['id'] is int) {
      return jugador['id'];
    }

    return int.tryParse(
      jugador['id']?.toString() ?? '',
    );
  }

  Widget construirIniciales() {
    return Container(
      width: 150,
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        obtenerIniciales(),
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D4F7A),
        ),
      ),
    );
  }

  Widget construirFoto() {
    final fotoUrl =
        obtenerFotoUrl(
      jugador['fotoJugador'],
    );

    if (fotoUrl.isEmpty) {
      return construirIniciales();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.network(
        fotoUrl,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return construirIniciales();
        },
      ),
    );
  }

  Widget filaDato(
    IconData icono,
    String titulo,
    String valor,
  ) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(icono),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> abrirEdicion() async {
    final jugadorId =
        obtenerJugadorId();

    if (jugadorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El jugador no tiene un ID válido.',
          ),
        ),
      );

      return;
    }

    final actualizado =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarJugadorPage(
          jugadorId: jugadorId,
          token: widget.token,
        ),
      ),
    );

    if (actualizado == true &&
        mounted) {
      Navigator.pop(
        context,
        true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombres =
        jugador['nombres']
                ?.toString()
                .trim() ??
            '';

    final apellidos =
        jugador['apellidos']
                ?.toString()
                .trim() ??
            '';

    final nombreCompleto =
        '$nombres $apellidos'.trim();

    final numero =
        jugador['numeroCamiseta']
                ?.toString() ??
            '';

    final posicion =
        jugador['posicion']
                ?.toString()
                .trim() ??
            '';

    final estado =
        jugador['estado']
                ?.toString()
                .trim() ??
            '';

    final fechaNacimiento =
        formatearFecha(
      jugador['fechaNacimiento'],
    );

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text(
          'Ficha del jugador',
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 600,
            ),

            child: Column(
              children: [
                construirFoto(),

                const SizedBox(
                  height: 18,
                ),

                Text(
                  nombreCompleto.isEmpty
                      ? 'Jugador sin nombre'
                      : nombreCompleto,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 26,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  widget.equipoNombre,
                  style:
                      const TextStyle(
                    fontSize: 17,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                filaDato(
                  Icons.confirmation_number,
                  'Número de camiseta',
                  numero.isEmpty
                      ? 'No registrado'
                      : numero,
                ),

                filaDato(
                  Icons.sports_soccer,
                  'Posición',
                  posicion.isEmpty
                      ? 'No registrada'
                      : posicion,
                ),

                filaDato(
                  Icons.cake_outlined,
                  'Fecha de nacimiento',
                  fechaNacimiento,
                ),

                filaDato(
                  Icons.verified,
                  'Estado',
                  estado.isEmpty
                      ? 'No registrado'
                      : estado,
                ),

                filaDato(
                  Icons.groups,
                  'Equipo',
                  widget.equipoNombre,
                ),

                const SizedBox(
                  height: 24,
                ),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: abrirEdicion,
                    icon: const Icon(
                      Icons.edit,
                    ),
                    label: const Text(
                      'EDITAR JUGADOR',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}