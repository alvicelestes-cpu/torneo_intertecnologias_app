import 'package:flutter/material.dart';

import '../../models/equipo.dart';
import '../constants/app_colors.dart';
import '../session/session_manager.dart';

enum TournamentType {
  intertecnologias,
  banquita,
  generico,
}

/// Sistema de tematización multi-torneo centralizado.
/// Permite que cada torneo (ej. Torneo Intertecnologías ID 1 vs Torneo Banquita Los Altos ID 2)
/// defina de forma desacoplada su propia identidad visual sin dispersar condicionales `if (id == 2)`.
class TournamentTheme {
  final int id;
  final String nombre;
  final String slug;
  final TournamentType type;

  /// Indica si el torneo maneja categorías deportivas por edad (18-34, 35-39, >40).
  /// En Torneo Intertecnologías (ID 1) es true.
  /// En Torneo Banquita Los Altos (ID 2) es false.
  final bool usaCategoriasEdad;

  // Paleta estructural
  final Color scaffoldBackground;
  final Color surface;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBorder;

  // Gradiente oficial para banners y cabeceras
  final List<Color> headerGradient;

  // Color distintivo por defecto para clubes sin color específico
  final Color defaultTeamColor;

  const TournamentTheme({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.type,
    required this.usaCategoriasEdad,
    required this.scaffoldBackground,
    required this.surface,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBorder,
    required this.headerGradient,
    required this.defaultTeamColor,
  });

  /// Tema oficial Torneo Intertecnologías (ID 1, slug intertecnologias)
  static const TournamentTheme intertecnologias = TournamentTheme(
    id: 1,
    nombre: 'Torneo Intertecnologías 2026',
    slug: 'intertecnologias',
    type: TournamentType.intertecnologias,
    usaCategoriasEdad: true,
    scaffoldBackground: Color(0xFFF4F7FB),
    surface: Colors.white,
    primary: Color(0xFF1D4F7A),
    primaryLight: Color(0xFFEAF2FB),
    primaryDark: Color(0xFF0F2A42),
    secondary: Color(0xFF1565C0),
    accent: Color(0xFF01BAEF),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    cardBorder: Color(0xFFE2E8F0),
    headerGradient: [
      Color(0xFF0D233A),
      Color(0xFF1565C0),
      Color(0xFF1E88E5),
    ],
    defaultTeamColor: Color(0xFF1976D2),
  );

  /// Tema oficial Torneo Banquita Los Altos (ID 2, slug torneo-demo)
  static const TournamentTheme banquita = TournamentTheme(
    id: 2,
    nombre: 'Torneo Banquita Los Altos',
    slug: 'torneo-demo',
    type: TournamentType.banquita,
    usaCategoriasEdad: false,
    scaffoldBackground: Color(0xFFF4F8F7), // Fondo suave Banquita
    surface: Colors.white,
    primary: Color(0xFF064E3B),        // Verde deportivo oscuro
    primaryLight: Color(0xFFECFDF5),
    primaryDark: Color(0xFF022C22),
    secondary: Color(0xFF047857),      // Verde deportivo profesional
    accent: Color(0xFFF59E0B),         // Ámbar / Dorado
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF64748B),
    cardBorder: Color(0xFFA7F3D0),
    headerGradient: [
      Color(0xFF064E3B),
      Color(0xFF047857),
    ],
    defaultTeamColor: Color(0xFF064E3B),
  );

  /// Determina si este tema corresponde al Torneo Banquita Los Altos (ID 2 o slug torneo-demo)
  bool get isBanquita =>
      type == TournamentType.banquita ||
      id == 2 ||
      slug == 'torneo-demo' ||
      slug == 'banquita' ||
      slug == 'banquita-los-altos' ||
      slug == 'torneo-banquita-los-altos' ||
      nombre.toLowerCase().contains('banquita');

  /// Determina si este tema corresponde al Torneo Intertecnologías (ID 1 o slug intertecnologias)
  bool get isIntertecnologias =>
      type == TournamentType.intertecnologias || id == 1 || slug == 'intertecnologias';

  /// Resuelve el color oficial para un equipo dentro del torneo:
  /// - En Banquita (ID 2): NUNCA permitir azul eléctrico genérico (#0d6efd, #1976D2, #1565C0, #0D47A1, #2563EB). Si tiene esos colores o no tiene color, asigna el verde deportivo oficial (#064E3B).
  /// - En Intertecnologías (ID 1): SIEMPRE respetar el color propio original del equipo (equipo.color).
  Color getTeamColor(Equipo? equipo) {
    if (equipo == null) return defaultTeamColor;

    if (isBanquita) {
      if (equipo.colorPrincipal != null && equipo.colorPrincipal!.trim().isNotEmpty) {
        final parsed = equipo.color;
        final argb = parsed.toARGB32();
        if (argb != 0xFF1976D2 &&
            argb != 0xFF0D47A1 &&
            argb != 0xFF0D6EFD &&
            argb != 0xFF1565C0 &&
            argb != 0xFF2563EB) {
          return parsed;
        }
      }
      return primary; // 0xFF064E3B
    }

    return equipo.color;
  }

  /// Color de acento / borde para la tarjeta de carnet de jugador
  Color getPlayerCardAccentColor(int? edad) {
    if (!usaCategoriasEdad) {
      return accent; // #F59E0B en Banquita
    }
    return getCarnetColorByAge(edad); // Verde (>40) / Naranja (35-39) / Azul (18-34) en Intertecnologías
  }

  /// Color base del encabezado del carnet
  Color getPlayerCardHeaderColor(int? edad) {
    if (!usaCategoriasEdad) {
      return primary; // #064E3B en Banquita
    }
    return getCarnetColorByAge(edad);
  }

  /// Gradiente del encabezado del carnet de jugador
  List<Color> getPlayerCardHeaderGradient(int? edad) {
    if (!usaCategoriasEdad) {
      return const [
        Color(0xFF064E3B),
        Color(0xFF047857),
      ];
    }
    final base = getCarnetColorByAge(edad);
    return [
      base,
      Color.lerp(base, const Color(0xFF0D233A), 0.35) ?? base,
    ];
  }

  /// Fondo del chip de dorsal en el carnet
  Color getPlayerDorsalBadgeColor(int? edad) {
    if (!usaCategoriasEdad) {
      return accent; // #F59E0B en Banquita
    }
    return Colors.black26;
  }

  /// Color de texto del chip de dorsal en el carnet
  Color getPlayerDorsalTextColor(int? edad) {
    if (!usaCategoriasEdad) {
      return Colors.white;
    }
    return Colors.white;
  }

  /// Color para el texto de la edad en el carnet
  Color getPlayerAgeTextColor(int? edad) {
    if (!usaCategoriasEdad) {
      return primary; // #064E3B en Banquita
    }
    return getCarnetColorByAge(edad);
  }

  /// Color de botón "Ver ficha" en la tarjeta
  Color getPlayerCardButtonColor(int? edad) {
    if (!usaCategoriasEdad) {
      return secondary; // #047857 en Banquita
    }
    return getCarnetColorByAge(edad);
  }

  /// Resuelve el tema a partir de ID o Slug
  static TournamentTheme fromIdOrSlug({int? id, String? slug, String? nombre}) {
    // 1. PRIORIDAD ESTRICTA: Intertecnologías (ID 1)
    if (id == 1) return intertecnologias;
    if (slug != null) {
      final s = slug.toLowerCase().trim();
      if (s == 'intertecnologias' || s == 'inter-tecnologias') {
        return intertecnologias;
      }
    }
    if (nombre != null) {
      final n = nombre.toLowerCase().trim();
      if (n.contains('intertecnologias') || n.contains('intertecnologías')) {
        return intertecnologias;
      }
    }

    // 2. Torneo Banquita Los Altos (ID 2)
    if (id == 2) return banquita;
    if (slug != null) {
      final s = slug.toLowerCase().trim();
      if (s == 'torneo-demo' ||
          s == 'banquita' ||
          s == 'banquita-los-altos' ||
          s == 'torneo-banquita-los-altos') {
        return banquita;
      }
    }
    if (nombre != null) {
      final n = nombre.toLowerCase().trim();
      if (n == 'torneo banquita los altos' || n.contains('banquita')) {
        return banquita;
      }
    }

    // 3. FALLBACK ESTRICTO: Intertecnologías (ID 1) - NUNCA Banquita
    return intertecnologias;
  }

  /// Resuelve el tema del torneo actualmente activo en SessionManager
  static TournamentTheme get current {
    final session = SessionManager();
    final id = session.selectedCampeonatoId;
    if (id == 1) return intertecnologias;
    if (id == 2) return banquita;
    return fromIdOrSlug(
      id: id,
      slug: session.selectedCampeonatoSlug,
      nombre: session.selectedCampeonatoNombre,
    );
  }

  /// Obtiene el tema desde el contexto (InheritedTournamentTheme) o recurre a current
  static TournamentTheme of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<InheritedTournamentTheme>();
    if (provider != null) {
      return provider.theme;
    }
    return current;
  }
}

/// Provider para inyectar TournamentTheme en sub-árboles de rutas específicas (ej. /t/torneo-demo)
class InheritedTournamentTheme extends InheritedWidget {
  final TournamentTheme theme;

  const InheritedTournamentTheme({
    super.key,
    required this.theme,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedTournamentTheme oldWidget) {
    return theme != oldWidget.theme;
  }
}
