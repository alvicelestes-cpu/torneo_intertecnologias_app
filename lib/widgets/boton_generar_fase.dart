import 'package:flutter/material.dart';

import '../core/errors/app_exception.dart';
import '../core/session/session_manager.dart';
import '../core/utils/fixture_utils.dart';
import '../models/partido.dart';
import '../services/fases_service.dart';

class BotonGenerarFase extends StatefulWidget {
  final String fase;
  final List<Partido> todosLosPartidos;
  final bool faseGenerada;
  final VoidCallback onFaseGenerada;

  const BotonGenerarFase({
    super.key,
    required this.fase,
    required this.todosLosPartidos,
    required this.faseGenerada,
    required this.onFaseGenerada,
  });

  @override
  State<BotonGenerarFase> createState() => _BotonGenerarFaseState();
}

class _BotonGenerarFaseState extends State<BotonGenerarFase> {
  final FasesService _fasesService = FasesService();
  bool _cargando = false;

  String get _tituloBoton {
    switch (widget.fase) {
      case TournamentPhase.segundaRonda:
        return '⚡ Generar Cuadrangulares (Grupos A y B)';
      case TournamentPhase.terceraRonda:
        return '⚡ Generar Llaves de Cuartos de Final';
      case TournamentPhase.cuartaRonda:
        return '⚡ Generar Semifinales';
      case TournamentPhase.quintaRonda:
        return '⚡ Generar Gran Final';
      default:
        return '⚡ Generar Fase';
    }
  }

  (bool puedeGenerar, String? errorMensaje) _validarFasePreviaCompletada() {
    switch (widget.fase) {
      case TournamentPhase.segundaRonda:
        final partidosPF = widget.todosLosPartidos.where((p) {
          final f = p.fase?.toUpperCase().trim() ?? '';
          return f == 'PRIMERA_FASE' ||
              (!f.contains('SEGUNDA') &&
                  !f.contains('CUADRANGULAR') &&
                  !f.contains('TERCERA') &&
                  !f.contains('CUARTO') &&
                  !f.contains('SEMI') &&
                  !f.contains('FINAL') &&
                  (p.jornada == null || p.jornada! <= 7));
        }).toList();

        final tieneJ7 = partidosPF.any((p) => p.jornada == 7);
        final todosFinalizados = partidosPF.isNotEmpty && partidosPF.every((p) => p.esFinalizado);

        if (!tieneJ7 || !todosFinalizados) {
          return (false, 'Aún hay partidos pendientes por disputar en la fase previa.');
        }
        return (true, null);

      case TournamentPhase.terceraRonda:
        final partidosSR = widget.todosLosPartidos.where((p) {
          final f = p.fase?.toUpperCase().trim() ?? '';
          return f.contains('SEGUNDA') || f.contains('CUADRANGULAR') || p.jornada == 8;
        }).toList();

        if (partidosSR.isEmpty || !partidosSR.every((p) => p.esFinalizado)) {
          return (false, 'Aún hay partidos pendientes por disputar en la fase previa.');
        }
        return (true, null);

      case TournamentPhase.cuartaRonda:
        final partidosCF = widget.todosLosPartidos.where((p) {
          final f = p.fase?.toUpperCase().trim() ?? '';
          return f.contains('TERCERA') || f.contains('CUARTO');
        }).toList();

        if (partidosCF.isEmpty || !partidosCF.every((p) => p.esFinalizado)) {
          return (false, 'Aún hay partidos pendientes por disputar en la fase previa.');
        }
        return (true, null);

      case TournamentPhase.quintaRonda:
        final partidosSF = widget.todosLosPartidos.where((p) {
          final f = p.fase?.toUpperCase().trim() ?? '';
          return f.contains('CUARTA') || f.contains('SEMI');
        }).toList();

        if (partidosSF.isEmpty || !partidosSF.every((p) => p.esFinalizado)) {
          return (false, 'Aún hay partidos pendientes por disputar en la fase previa.');
        }
        return (true, null);

      default:
        return (true, null);
    }
  }

  Future<void> _ejecutarGeneracion() async {
    final (puedeGenerar, errorMensaje) = _validarFasePreviaCompletada();

    if (!puedeGenerar) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fase previa incompleta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            errorMensaje ?? 'Aún hay partidos pendientes por disputar en la fase previa.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirmar Generación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Deseas generar oficialmente los cruces de esta fase? Los partidos se crearán en la base de datos y estarán disponibles para todo el público.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D233A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar y Generar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    setState(() => _cargando = true);

    try {
      switch (widget.fase) {
        case TournamentPhase.segundaRonda:
          await _fasesService.generarSegundaRonda();
          break;
        case TournamentPhase.terceraRonda:
          await _fasesService.generarCuartos();
          break;
        case TournamentPhase.cuartaRonda:
          await _fasesService.generarSemifinales();
          break;
        case TournamentPhase.quintaRonda:
          await _fasesService.generarFinal();
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Fase generada exitosamente. Se han publicado los cruces oficiales.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        widget.onFaseGenerada();
      }
    } catch (e) {
      if (mounted) {
        final mensaje = e is AppException ? e.message : 'Error al generar la fase: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Exclusivo para administradores
    if (!SessionManager().hasAdminAccess) {
      return const SizedBox.shrink();
    }

    if (widget.fase == TournamentPhase.primeraFase) {
      return const SizedBox.shrink();
    }

    if (widget.faseGenerada) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981), width: 1.0),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text(
              '✓ Fase Generada (Cruces Oficiales Activos)',
              style: TextStyle(
                color: Color(0xFF065F46),
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ElevatedButton.icon(
        onPressed: _cargando ? null : _ejecutarGeneracion,
        icon: _cargando
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 18),
        label: Text(
          _tituloBoton,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D233A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
