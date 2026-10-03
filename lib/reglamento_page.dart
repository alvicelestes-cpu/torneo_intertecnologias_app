import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/session/session_manager.dart';
import 'core/theme/tournament_theme.dart';
import 'core/utils/web_url_helper.dart';
import 'models/reglamento_model.dart';
import 'services/reglamento_service.dart';
import 'widgets/public_navbar.dart';

class ReglamentoPage extends StatefulWidget {
  final String? slug;

  const ReglamentoPage({
    super.key,
    this.slug,
  });

  @override
  State<ReglamentoPage> createState() => _ReglamentoPageState();
}

class _ReglamentoPageState extends State<ReglamentoPage> {
  final TextEditingController _searchController = TextEditingController();
  final ReglamentoService _reglamentoService = ReglamentoService();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _effectiveSlug {
    if (widget.slug != null && widget.slug!.trim().isNotEmpty) {
      return widget.slug!.trim();
    }
    return SessionManager().selectedCampeonatoSlug;
  }

  void _volverAlPortal(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      final slug = _effectiveSlug;
      final target = slug.isNotEmpty ? '/t/$slug' : '/';
      setBrowserUrl(target);
      Navigator.pushReplacementNamed(context, target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slug = _effectiveSlug;
    final reglamento = _reglamentoService.getReglamentoPorSlug(slug);
    final theme = TournamentTheme.fromIdOrSlug(slug: slug);

    return InheritedTournamentTheme(
      theme: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: const PublicTopNavBar(activeRoute: 'Reglamento'),
        body: reglamento == null
            ? _buildReglamentoNoDisponible(context)
            : _buildContenidoReglamento(context, reglamento),
      ),
    );
  }

  Widget _buildReglamentoNoDisponible(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book, size: 48, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Reglamento no disponible',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D233A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Este torneo aún no cuenta con un reglamento oficial registrado en la plataforma.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _volverAlPortal(context),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Volver al Portal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContenidoReglamento(BuildContext context, TorneoReglamento reglamento) {
    final query = _searchQuery.trim().toLowerCase();
    final seccionesFiltradas = reglamento.secciones.where((s) {
      if (query.isEmpty) return true;
      if (s.titulo.toLowerCase().contains(query)) return true;
      if (s.articulos.any((a) => a.toLowerCase().contains(query))) return true;
      if (s.alertaEspecial != null && s.alertaEspecial!.toLowerCase().contains(query)) return true;
      return false;
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 24,
        vertical: 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Botón de navegación y miga de pan
              Row(
                children: [
                  OutlinedButton.icon(
                    key: const Key('btn_volver_portal_reglamento'),
                    onPressed: () => _volverAlPortal(context),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Volver al Portal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reglamento.subtitulo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Banner deportivo principal de cabecera
              _buildHeaderBanner(context, reglamento),
              const SizedBox(height: 20),

              // 3. Barra de búsqueda de reglas
              _buildBuscador(seccionesFiltradas.length, reglamento.secciones.length),
              const SizedBox(height: 20),

              // 4. Secciones oficiales (Responsive: 1 col móvil, 2 col escritorio)
              if (seccionesFiltradas.isEmpty)
                _buildSinResultadosBusqueda()
              else
                _buildSeccionesResponsive(seccionesFiltradas),

              const SizedBox(height: 32),

              // 5. Botón final para regresar
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _volverAlPortal(context),
                  icon: const Icon(Icons.home, size: 18),
                  label: const Text('Regresar al Portal del Torneo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D233A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, TorneoReglamento reglamento) {
    final theme = TournamentTheme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.headerGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.gavel, color: Colors.amberAccent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reglamento.subtitulo.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reglamento.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),

            // Chips reglamentarios rápidos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reglamento.chips.map((c) => _buildChip(c)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(ChipRegla chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chip.icono != null) ...[
            Icon(chip.icono, color: Colors.amberAccent, size: 15),
            const SizedBox(width: 6),
          ],
          Text(
            chip.texto,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuscador(int encontrados, int total) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: const Key('input_buscar_reglamento'),
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Buscar regla (ej. bomba, penal, faltas, cambios...)',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.black45),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinResultadosBusqueda() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No se encontraron reglas para "$_searchQuery"',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba con otros términos como: área, tarjeta, penal, puntos, etc.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionesResponsive(List<SeccionReglamento> secciones) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esPantallaAncha = constraints.maxWidth >= 740;

        if (!esPantallaAncha) {
          // Móvil: Columna única
          return Column(
            children: secciones
                .map((sec) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildTarjetaSeccion(sec),
                    ))
                .toList(),
          );
        }

        // Escritorio/Tablet: 2 Columnas equilibradas
        final col1 = <SeccionReglamento>[];
        final col2 = <SeccionReglamento>[];

        for (int i = 0; i < secciones.length; i++) {
          if (i % 2 == 0) {
            col1.add(secciones[i]);
          } else {
            col2.add(secciones[i]);
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: col1
                    .map((sec) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildTarjetaSeccion(sec),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: col2
                    .map((sec) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildTarjetaSeccion(sec),
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTarjetaSeccion(SeccionReglamento sec) {
    final esAreaBomba = sec.numero == 6;
    final esWO = sec.numero == 14;

    Color colorFondo = Colors.white;
    Color colorBorde = Colors.grey.shade200;
    Color colorIcono = AppColors.primary;
    Color colorFondoIcono = Colors.blue.shade50;
    String? badgeText;
    Color badgeColor = Colors.transparent;

    if (esAreaBomba) {
      colorFondo = const Color(0xFFFFFDF5);
      colorBorde = Colors.amber.shade400;
      colorIcono = const Color(0xFFD97706);
      colorFondoIcono = Colors.amber.shade100;
      badgeText = 'REGLA CLAVE';
      badgeColor = const Color(0xFFD97706);
    } else if (esWO) {
      colorFondo = const Color(0xFFFFF9F9);
      colorBorde = Colors.red.shade300;
      colorIcono = Colors.red.shade700;
      colorFondoIcono = Colors.red.shade50;
      badgeText = 'SANCIÓN';
      badgeColor = Colors.red.shade700;
    }

    return Card(
      elevation: sec.destacada ? 2 : 1,
      color: colorFondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorBorde, width: sec.destacada ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de la sección
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorFondoIcono,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(sec.icono, color: colorIcono, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '${sec.numero}. ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: sec.destacada ? colorIcono : const Color(0xFF0D233A),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          sec.titulo.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: sec.destacada ? colorIcono : const Color(0xFF0D233A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Artículos reglamentarios
            ...sec.articulos.map((art) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5, right: 8),
                        child: Icon(
                          Icons.circle,
                          size: 6,
                          color: sec.destacada ? colorIcono : AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          art,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            // Alerta especial si existe
            if (sec.alertaEspecial != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: badgeColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sec.alertaEspecial!,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
