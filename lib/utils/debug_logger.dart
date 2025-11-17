import 'package:flutter/foundation.dart';

/// Helper para controlar los mensajes de depuración verbosos.
/// Cambia el valor de [enableVerboseLogs] a `true` para reactivar logs detallados.
const bool enableVerboseLogs = false;

void debugLog(String message) {
  if (!enableVerboseLogs) return;
  if (kDebugMode) {
    debugPrint(message);
  }
}

