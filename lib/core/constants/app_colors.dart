import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1D4F7A);
  static const Color primaryLight = Color(0xFFEAF2FB);
  static const Color primaryDark = Color(0xFF0F2A42);
  static const Color headerBackground = Color(0xFFE8EEF7);
  static const Color scaffoldBackground = Color(0xFFF4F7FB);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Textos
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  // Estados de partidos / jornadas
  static const Color statusProgramado = Color(0xFF1976D2);
  static const Color statusEnCurso = Color(0xFFF57C00);
  static const Color statusFinalizado = Color(0xFF388E3C);
  static const Color statusCancelado = Color(0xFFD32F2F);
  static const Color statusDefault = Color(0xFF757575);

  // Tarjetas disciplinarias
  static const Color tarjetaAmarilla = Color(0xFFFFC107);
  static const Color tarjetaRoja = Color(0xFFD32F2F);

  // Métricas / Posiciones
  static const Color podioOro = Color(0xFFFFA000);
  static const Color podioPlata = Color(0xFF607D8B);
  static const Color podioBronce = Color(0xFF8D6E63);

  // Colores de carnets según categoría de edad
  static const Color carnetVerde = Color(0xFF2E7D32); // >= 40 años
  static const Color carnetNaranja = Color(0xFFE65100); // 35 - 39 años
  static const Color carnetAzul = Color(0xFF1565C0); // 18 - 34 años
  static const Color carnetNeutro = Color(0xFF546E7A); // null o default neutro elegante

  static Color getColorByAge(int? edad) => getCarnetColorByAge(edad);

  static Color getStatusColor(String? status) {
    switch (status?.toUpperCase().trim()) {
      case 'FINALIZADO':
      case 'FINALIZADA':
        return statusFinalizado;
      case 'EN_CURSO':
        return statusEnCurso;
      case 'PROGRAMADO':
      case 'PROGRAMADA':
        return statusProgramado;
      case 'CANCELADO':
      case 'CANCELADA':
        return statusCancelado;
      default:
        return statusDefault;
    }
  }
}

enum AgeGroup {
  over40,
  between35And39,
  between18And34,
  unknown,
}

AgeGroup getAgeGroup(int? edad) {
  if (edad == null) return AgeGroup.unknown;
  if (edad >= 40) return AgeGroup.over40;
  if (edad >= 35 && edad <= 39) return AgeGroup.between35And39;
  if (edad >= 18 && edad <= 34) return AgeGroup.between18And34;
  return AgeGroup.unknown;
}

int getAgeGroupOrder(int? edad) {
  final group = getAgeGroup(edad);
  switch (group) {
    case AgeGroup.over40:
      return 1;
    case AgeGroup.between35And39:
      return 2;
    case AgeGroup.between18And34:
      return 3;
    case AgeGroup.unknown:
      return 4;
  }
}

Color getColorByAge(int? edad) => getCarnetColorByAge(edad);

Color getCarnetColorByAge(int? edad) {
  final group = getAgeGroup(edad);
  switch (group) {
    case AgeGroup.over40:
      return AppColors.carnetVerde;
    case AgeGroup.between35And39:
      return AppColors.carnetNaranja;
    case AgeGroup.between18And34:
      return AppColors.carnetAzul;
    case AgeGroup.unknown:
      return AppColors.carnetNeutro;
  }
}

extension AgeGroupExtension on AgeGroup {
  int get order => getAgeGroupOrder(
        this == AgeGroup.over40
            ? 40
            : (this == AgeGroup.between35And39
                ? 35
                : (this == AgeGroup.between18And34 ? 20 : null)),
      );

  String get title {
    switch (this) {
      case AgeGroup.over40:
        return 'Mayores de 40 años';
      case AgeGroup.between35And39:
        return 'Entre 35 y 39 años';
      case AgeGroup.between18And34:
        return 'De 18 a 34 años';
      case AgeGroup.unknown:
        return 'Edad no disponible';
    }
  }

  Color get color {
    switch (this) {
      case AgeGroup.over40:
        return AppColors.carnetVerde;
      case AgeGroup.between35And39:
        return AppColors.carnetNaranja;
      case AgeGroup.between18And34:
        return AppColors.carnetAzul;
      case AgeGroup.unknown:
        return AppColors.carnetNeutro;
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case AgeGroup.over40:
        return const [
          Color(0xFF1B5E20),
          Color(0xFF2E7D32),
          Color(0xFF388E3C),
        ];
      case AgeGroup.between35And39:
        return const [
          Color(0xFFBF360C),
          Color(0xFFE65100),
          Color(0xFFF57C00),
        ];
      case AgeGroup.between18And34:
        return const [
          Color(0xFF0D47A1),
          Color(0xFF1565C0),
          Color(0xFF1E88E5),
        ];
      case AgeGroup.unknown:
        return const [
          Color(0xFF37474F),
          Color(0xFF546E7A),
          Color(0xFF78909C),
        ];
    }
  }
}

const List<AgeGroup> kAgeGroupsOrder = [
  AgeGroup.over40,
  AgeGroup.between35And39,
  AgeGroup.between18And34,
  AgeGroup.unknown,
];
