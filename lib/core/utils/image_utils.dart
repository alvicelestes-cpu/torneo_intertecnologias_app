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
    if (valor.startsWith('http://') || valor.startsWith('https://')) {
      return valor;
    }

    if (valor.startsWith('/')) {
      return '${ApiConstants.baseUrl}$valor';
    }

    return '${ApiConstants.baseUrl}/$valor';
  }
}
