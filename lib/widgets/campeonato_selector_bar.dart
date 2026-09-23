import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/session/session_manager.dart';
import '../services/torneo_service.dart';

class CampeonatoSelectorBar extends StatefulWidget {
  final VoidCallback? onCampeonatoChanged;

  const CampeonatoSelectorBar({
    super.key,
    this.onCampeonatoChanged,
  });

  @override
  State<CampeonatoSelectorBar> createState() => _CampeonatoSelectorBarState();
}

class _CampeonatoSelectorBarState extends State<CampeonatoSelectorBar> {
  final TorneoService _torneoService = TorneoService();
  final SessionManager _sessionManager = SessionManager();
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarCampeonatos();
  }

  Future<void> _cargarCampeonatos() async {
    if (_sessionManager.campeonatos.isNotEmpty) return;

    setState(() => _cargando = true);
    try {
      final list = await _torneoService.getCampeonatos();
      if (mounted) {
        _sessionManager.setCampeonatos(list);
      }
    } catch (_) {
      // Ignorar fallo de red silencioso para no bloquear el inicio
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirSelectorModal() {
    if (!_sessionManager.canChangeCampeonato) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Seleccionar Torneo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Elige el campeonato a consultar (hasta 20 torneos independientes):',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListenableBuilder(
                  listenable: _sessionManager,
                  builder: (context, _) {
                    final allList = _sessionManager.campeonatos;
                    final activos = allList.where((c) => c.estaActivo).toList();
                    final campeonatos = activos.isNotEmpty ? activos : allList;

                    if (campeonatos.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                _cargando
                                    ? 'Cargando torneos disponibles...'
                                    : 'Torneo Intertecnologías (Predeterminado)',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: campeonatos.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = campeonatos[index];
                        final isSelected = c.id == _sessionManager.selectedCampeonatoId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.primaryLight,
                            child: Text(
                              c.iniciales,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            c.nombre,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${c.totalEquipos} equipos • ${c.totalPartidos} partidos',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary)
                              : null,
                          onTap: () {
                            _sessionManager.selectCampeonato(c);
                            Navigator.pop(ctx);
                            widget.onCampeonatoChanged?.call();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sessionManager,
      builder: (context, _) {
        final nombreTorneo = _sessionManager.selectedCampeonatoNombre;
        final canChange = _sessionManager.canChangeCampeonato;

        return InkWell(
          onTap: canChange ? _abrirSelectorModal : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    nombreTorneo,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                if (canChange) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
