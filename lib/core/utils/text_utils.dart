class TextUtils {
  TextUtils._();

  static int toInt(dynamic valor, [int defaultValue = 0]) {
    if (valor == null) return defaultValue;
    if (valor is int) return valor;
    if (valor is double) return valor.toInt();
    return int.tryParse(valor.toString().trim()) ?? defaultValue;
  }

  static double toDouble(dynamic valor, [double defaultValue = 0.0]) {
    if (valor == null) return defaultValue;
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    return double.tryParse(valor.toString().trim()) ?? defaultValue;
  }

  static String formatGoalDifference(dynamic valor) {
    final diferencia = toInt(valor);
    if (diferencia > 0) return '+$diferencia';
    return diferencia.toString();
  }

  static String formatFase(dynamic fase) {
    if (fase == null) return 'Sin fase';
    final texto = fase.toString().replaceAll('_', ' ').trim();
    return texto.isEmpty ? 'Sin fase' : texto;
  }

  static String getInitials(String? nombre, {String? sigla, String fallback = 'FC'}) {
    final siglaValida = sigla?.trim() ?? '';
    if (siglaValida.isNotEmpty) {
      return siglaValida.length >= 2
          ? siglaValida.substring(0, 2).toUpperCase()
          : siglaValida.toUpperCase();
    }

    final nombreValido = nombre?.trim() ?? '';
    if (nombreValido.isEmpty) return fallback;

    final partes = nombreValido.split(' ').where((p) => p.trim().isNotEmpty).toList();
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }

    return nombreValido.length >= 2
        ? nombreValido.substring(0, 2).toUpperCase()
        : nombreValido.toUpperCase();
  }
}
