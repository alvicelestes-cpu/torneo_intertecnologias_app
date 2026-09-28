// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Implementación web para manipular la URL usando la Web History API sin recargar
void setBrowserUrl(String path) {
  try {
    html.window.history.pushState(null, '', path);
  } catch (_) {
    // Manejo seguro si el entorno web no permite pushState
  }
}

String getBrowserUrl() {
  try {
    return html.window.location.href;
  } catch (_) {
    return '';
  }
}
