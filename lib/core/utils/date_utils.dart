class AppDateUtils {
  AppDateUtils._();

  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    return DateTime.tryParse(str);
  }

  static String formatDateTime(dynamic fechaHora, {String defaultText = 'Fecha por definir'}) {
    if (fechaHora == null) return defaultText;

    final valor = fechaHora.toString().trim();
    if (valor.isEmpty) return defaultText;

    final fecha = DateTime.tryParse(valor);
    if (fecha == null) return valor;

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio - $hora:$minuto';
  }

  static String formatDate(dynamic fecha, {String defaultText = 'Sin fecha'}) {
    if (fecha == null) return defaultText;

    final valor = fecha.toString().trim();
    if (valor.isEmpty) return defaultText;

    final dt = DateTime.tryParse(valor);
    if (dt == null) return valor;

    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final anio = dt.year.toString();

    return '$dia/$mes/$anio';
  }

  static int? calculateAge(dynamic fechaNacimiento) {
    final dt = tryParse(fechaNacimiento);
    if (dt == null) return null;
    final now = DateTime.now();
    int age = now.year - dt.year;
    if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }
}
