import 'package:flutter/material.dart';
import 'dart:ui'; // IMPORTANTE: Necesario para BackdropFilter e ImageFilter

/// Widget reutilizable que simula un efecto de vidrio esmerilado (Glassmorphism)
/// sobre un fondo oscuro, creando una interfaz moderna y premium.
class GlassContainer extends StatelessWidget {
  /// El widget hijo que será envuelto con el efecto de vidrio
  final Widget child;
  
  /// Radio de borde personalizable (por defecto 20.0)
  final double borderRadius;
  
  /// Intensidad del desenfoque (por defecto 12.0)
  final double blurIntensity;
  
  /// Padding interno del contenedor (por defecto 0)
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.blurIntensity = 12.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurIntensity,
          sigmaY: blurIntensity,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // Gradiente lineal de topLeft a bottomRight con transparencia
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.20),
                Colors.white.withOpacity(0.05),
              ],
            ),
            // Borde fino simulando el canto del cristal
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          // Usar ClipRRect interno para asegurar que el contenido hijo respete las esquinas
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius - 2), // Ligeramente menor para evitar overflow
            child: child,
          ),
        ),
      ),
    );
  }
}
