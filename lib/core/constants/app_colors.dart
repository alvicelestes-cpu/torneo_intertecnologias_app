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
