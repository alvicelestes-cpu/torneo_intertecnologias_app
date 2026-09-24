import '../constants/api_constants.dart';

class ImageUtils {
  ImageUtils._();

  static bool isValidImageUrl(dynamic url) {
    if (url == null) return false;
    final valor = url.toString().trim();
    if (valor.isEmpty || valor.toLowerCase() == 'string' || valor.toLowerCase() == 'null') {
      return false;
    }
    return true;
  }

  static String resolveUrl(dynamic path) {
    if (!isValidImageUrl(path)) return '';

    final valor = path.toString().trim();
    if (valor.startsWith('http://') ||
        valor.startsWith('https://') ||
        valor.startsWith('data:') ||
        valor.startsWith('blob:')) {
      return valor;
    }

    if (valor.startsWith('assets/')) {
      return valor;
    }

    if (valor.startsWith('/')) {
      return '${ApiConstants.baseUrl}$valor';
    }

    return '${ApiConstants.baseUrl}/$valor';
  }

  static String? resolveTeamLogo(String? logo, {String? teamName, String? sigla}) {
    if (isValidImageUrl(logo)) {
      final clean = logo!.trim();
      if (clean.toLowerCase() != 'null' && clean.toLowerCase() != 'string') {
        return clean;
      }
    }

    final nameUpper = teamName?.toUpperCase() ?? '';
    final siglaUpper = sigla?.toUpperCase() ?? '';
    if (nameUpper.contains('RACING') || siglaUpper == 'TRF' || siglaUpper == 'TR') {
      return 'assets/logos/tienda_racing.png';
    }

    return null;
  }
}
