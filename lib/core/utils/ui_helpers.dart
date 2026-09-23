import 'package:flutter/material.dart';

class UiHelpers {
  UiHelpers._();

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message, isError: false);
  }

  static void showError(BuildContext context, String message) {
    showSnackBar(context, message, isError: true);
  }
}
