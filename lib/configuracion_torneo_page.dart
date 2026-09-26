import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/ui_helpers.dart';
import 'services/torneo_config_service.dart';
import 'widgets/campeonato_selector_bar.dart';

class ConfiguracionTorneoPage extends StatefulWidget {
  final String? token;

  const ConfiguracionTorneoPage({
    super.key,
    this.token,
  });

  @override
  State<ConfiguracionTorneoPage> createState() => _ConfiguracionTorneoPageState();
}

class _ConfiguracionTorneoPageState extends State<ConfiguracionTorneoPage> {
  final _formKey = GlobalKey<FormState>();
  final TorneoConfigService _configService = TorneoConfigService();

  late TextEditingController _nombreCtrl;
  late int _limiteJugadores;
  late bool _tienePuntoInvisible;
  late int _topGoleadoresMax;

  bool _cargando = true;
  bool _guardando = false;

  String get _effectiveToken =>
      (widget.token != null && widget.token!.isNotEmpty)
          ? widget.token!
          : SessionManager().token;

  @override
  void initState() {
    super.initState();
    final cfg = _configService.config;
    _nombreCtrl = TextEditingController(text: cfg.nombre);
    _limiteJugadores = cfg.limiteJugadores.clamp(10, 25);
    _tienePuntoInvisible = cfg.tienePuntoInvisible;
    _topGoleadoresMax = cfg.topGoleadoresMax.clamp(3, 50);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final torneoId = SessionManager().selectedCampeonatoId;
    final cfg = await _configService.cargarConfiguracion(
      token: _effectiveToken,
      torneoId: torneoId,
    );

    if (mounted) {
      setState(() {
        _nombreCtrl.text = cfg.nombre;
        _limiteJugadores = cfg.limiteJugadores.clamp(10, 25);
        _tienePuntoInvisible = cfg.tienePuntoInvisible;
        _topGoleadoresMax = cfg.topGoleadoresMax.clamp(3, 50);
        _cargando = false;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final session = SessionManager();
    if (!session.hasAdminAccess) {
      UiHelpers.showError(
        context,
        'Acceso denegado: Se requieren permisos de administrador para guardar cambios reglamentarios.',
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final torneoId = session.selectedCampeonatoId;
      await _configService.actualizarConfiguracion(
        token: _effectiveToken,
        nombre: _nombreCtrl.text.trim(),
        limiteJugadores: _limiteJugadores,
        tienePuntoInvisible: _tienePuntoInvisible,
        topGoleadoresMax: _topGoleadoresMax,
        torneoId: torneoId,
      );

      if (mounted) {
        UiHelpers.showSnackBar(
          context,
          '✓ Configuración del torneo actualizada correctamente.',
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        UiHelpers.showError(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        UiHelpers.showError(
          context,
          'No se pudo conectar con el servidor para guardar la configuración.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Configuración del Torneo'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Recargar reglas',
            icon: const Icon(Icons.refresh),
            onPressed: _cargando ? null : _cargarDatos,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Selector de torneo activo
                        const Card(
                          elevation: 1,
                          margin: EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.tune, color: AppColors.primary),
                                SizedBox(width: 12),
                                Expanded(child: CampeonatoSelectorBar()),
                              ],
                            ),
                          ),
                        ),

                        // Encabezado descriptivo
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0D233A),
                                  Color(0xFF1565C0),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.white24,
                                  child: Icon(Icons.settings, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'REGLAS Y PARÁMETROS DEL TORNEO',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _nombreCtrl.text.isEmpty
                                            ? 'Personalizar Torneo'
                                            : _nombreCtrl.text,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
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
                        const SizedBox(height: 20),

                        // 1. Nombre del torneo
                        Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.edit_note, color: AppColors.primary, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      'Nombre del Torneo',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Nombre institucional visible en el portal, tablas y encabezados oficiales.',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _nombreCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Ej. Torneo Intertecnologías 2026',
                                    prefixIcon: const Icon(Icons.sports_soccer),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().length < 3) {
                                      return 'El nombre del torneo debe tener al menos 3 caracteres.';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Cupo Máximo de Jugadores por Equipo (Slider 10 a 25)
                        Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.groups, color: Color(0xFF00897B), size: 22),
                                        SizedBox(width: 8),
                                        Text(
                                          'Cupo Máximo por Equipo',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2F1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$_limiteJugadores jugadores',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00695C),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Límite de futbolistas que cada equipo puede inscribir reglamentariamente en su plantilla.',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                const SizedBox(height: 14),
                                Slider(
                                  value: _limiteJugadores.toDouble(),
                                  min: 10,
                                  max: 25,
                                  divisions: 15,
                                  label: '$_limiteJugadores jugadores',
                                  activeColor: const Color(0xFF00897B),
                                  onChanged: (val) {
                                    setState(() {
                                      _limiteJugadores = val.toInt();
                                    });
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Mínimo: 10', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text('Seleccionado: $_limiteJugadores',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF00897B))),
                                    const Text('Máximo: 25', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Ventaja Deportiva ("Punto Invisible")
                        Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            secondary: CircleAvatar(
                              backgroundColor: _tienePuntoInvisible
                                  ? const Color(0xFFE8F5E9)
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.verified,
                                color: _tienePuntoInvisible
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey,
                              ),
                            ),
                            title: const Text(
                              'Ventaja Deportiva ("Punto Invisible")',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              _tienePuntoInvisible
                                  ? 'Activo: El 1º y 2º de la Primera Fase obtienen ventaja de desempate en la fase de cuadrangulares.'
                                  : 'Desactivado: No se otorga punto invisible; los desempates se resuelven por diferencia de gol reglamentaria.',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            value: _tienePuntoInvisible,
                            activeThumbColor: const Color(0xFF2E7D32),
                            activeTrackColor: const Color(0xFFA5D6A7),
                            onChanged: (val) {
                              setState(() => _tienePuntoInvisible = val);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4. Cantidad de Artilleros en Top Goleadores
                        Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.emoji_events, color: Color(0xFFFB8C00), size: 22),
                                        SizedBox(width: 8),
                                        Text(
                                          'Top de Goleadores',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Top $_topGoleadoresMax',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE65100),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Cantidad de artilleros destacados a mostrar en la tabla pública de goleadores.',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  children: [5, 10, 15, 20].map((cantidad) {
                                    final seleccionado = _topGoleadoresMax == cantidad;
                                    return ChoiceChip(
                                      label: Text('Top $cantidad'),
                                      selected: seleccionado,
                                      selectedColor: const Color(0xFFFFE0B2),
                                      labelStyle: TextStyle(
                                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                                        color: seleccionado ? const Color(0xFFE65100) : Colors.black87,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _topGoleadoresMax = cantidad);
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Botón de guardar cambios
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _guardando ? null : _guardarCambios,
                            icon: _guardando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _guardando ? 'GUARDANDO CAMBIOS...' : 'GUARDAR CONFIGURACIÓN',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
