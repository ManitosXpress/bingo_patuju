import 'package:flutter/material.dart';
import 'dart:math' as math;

class PrizeWheelWidget extends StatefulWidget {
  final List<int> cartillaNumbers;
  final Function(int)? onPrizeSelected;
  final VoidCallback? onClose;
  final VoidCallback? onSync; // Added sync callback
  
  const PrizeWheelWidget({
    super.key,
    required this.cartillaNumbers,
    this.onPrizeSelected,
    this.onClose,
    this.onSync, // Added sync parameter
  });

  @override
  State<PrizeWheelWidget> createState() => _PrizeWheelWidgetState();
}

class _PrizeWheelWidgetState extends State<PrizeWheelWidget>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  bool _isSpinning = false;
  int? _selectedCartilla;
  int _spinsCount = 0;
  List<int> _winners = []; // Lista de ganadores
  Set<int> _usedCartillas = {}; // Cartillas ya utilizadas
  
  // Crear grupos de cartillas para la ruleta (máximo 12 secciones)
  List<List<int>> get _cartillaGroups {
    final groups = <List<int>>[];
    final totalCartillas = widget.cartillaNumbers.length;
    final groupSize = (totalCartillas / 12).ceil();
    
    for (int i = 0; i < totalCartillas; i += groupSize) {
      final end = math.min(i + groupSize, totalCartillas);
      groups.add(widget.cartillaNumbers.sublist(i, end));
    }
    
    return groups;
  }

  // Obtener cartillas disponibles (no ganadas)
  List<int> get _availableCartillas {
    return widget.cartillaNumbers.where((cartilla) => !_usedCartillas.contains(cartilla)).toList();
  }

  // Crear grupos solo con cartillas disponibles
  List<List<int>> get _availableCartillaGroups {
    final available = _availableCartillas;
    if (available.isEmpty) return [];
    
    final groups = <List<int>>[];
    final groupSize = (available.length / 12).ceil();
    
    for (int i = 0; i < available.length; i += groupSize) {
      final end = math.min(i + groupSize, available.length);
      groups.add(available.sublist(i, end));
    }
    
    return groups;
  }

  // Obtener números individuales para la ruleta (máximo 12 números)
  List<int> get _wheelNumbers {
    final available = _availableCartillas;
    if (available.isEmpty) return [];
    
    // Si hay 12 o menos cartillas disponibles, mostrar todas
    if (available.length <= 12) {
      return available;
    }
    
    // Si hay más de 12, seleccionar 12 números distribuidos uniformemente
    final selected = <int>[];
    final step = available.length / 12;
    
    for (int i = 0; i < 12; i++) {
      final index = (i * step).round();
      if (index < available.length) {
        selected.add(available[index]);
      }
    }
    
    return selected;
  }

  // Obtener números visibles en la ruleta (solo los que están en _wheelNumbers)
  List<int> get _visibleWheelNumbers {
    return _wheelNumbers;
  }

  // Obtener todas las cartillas disponibles para la ruleta (máximo 500)
  List<int> get _allWheelNumbers {
    final available = _availableCartillas;
    if (available.isEmpty) return [];
    
    // Si hay más de 50 cartillas, mostrar solo 50 para que sean visibles
    if (available.length > 50) {
      final selected = <int>[];
      final step = available.length / 50;
      
      for (int i = 0; i < 50; i++) {
        final index = (i * step).round();
        if (index < available.length) {
          selected.add(available[index]);
        }
      }
      return selected;
    }
    
    // Si hay 50 o menos, mostrar todas
    return available;
  }

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 6), // Más duración
      vsync: this,
    );
    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.elasticOut, // Efecto de rebote
    ));
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;
    
    // Verificar si hay cartillas disponibles
    final allNumbers = _allWheelNumbers;
    if (allNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 ¡Todas las cartillas han sido ganadas!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    setState(() {
      _isSpinning = true;
      _selectedCartilla = null;
    });
    
    // Seleccionar un número directamente de todas las cartillas disponibles
    final random = math.Random();
    final selectedIndex = random.nextInt(allNumbers.length);
    final selectedCartilla = allNumbers[selectedIndex];
    
    // Resetear la animación para que siempre gire
    _spinController.reset();
    _spinController.forward().then((_) {
      setState(() {
        _isSpinning = false;
        _selectedCartilla = selectedCartilla;
        _spinsCount++;
        _winners.add(selectedCartilla);
        _usedCartillas.add(selectedCartilla);
      });
      
      // Llamar al callback con la cartilla seleccionada
      if (widget.onPrizeSelected != null) {
        widget.onPrizeSelected!(selectedCartilla);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.shade900,
            Colors.indigo.shade700,
            Colors.indigo.shade500,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header con controles
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '🎯 Ruleta de Cartillas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Botón de sincronización
                      if (widget.onSync != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            if (widget.onSync != null) {
                              widget.onSync!();
                              // Mostrar mensaje de confirmación
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🔄 Sincronizando cartillas con el juego...'),
                                  backgroundColor: Colors.blue,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.sync),
                          label: const Text('Sincronizar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      if (widget.onSync != null)
                        const SizedBox(width: 8),
                      
                      ElevatedButton.icon(
                        onPressed: _isSpinning ? null : _spinWheel,
                        icon: Icon(_isSpinning ? Icons.hourglass_empty : Icons.casino),
                        label: Text(_isSpinning ? 'Girando...' : _allWheelNumbers.isEmpty ? 'Reiniciar' : '¡Girar!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSpinning ? Colors.grey : _allWheelNumbers.isEmpty ? Colors.green : Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_allWheelNumbers.isEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _winners.clear();
                              _usedCartillas.clear();
                              _selectedCartilla = null;
                              _spinsCount = 0;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reiniciar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (widget.onClose != null) {
                            widget.onClose!();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Cerrar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Información de cartillas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildInfoCard('Cartillas Totales', widget.cartillaNumbers.length.toString(), Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInfoCard('Cartillas en juego', _availableCartillas.length.toString(), Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInfoCard('Ganadores', _winners.length.toString(), Colors.purple)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Ruleta centrada
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Contenedor de la ruleta (sin flecha)
                    AnimatedBuilder(
                      animation: _spinAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _spinAnimation.value * 50 * math.pi, // Más rotaciones
                          child: Container(
                            width: 280,
                            height: 280,
                            child: CustomPaint(
                              painter: CartillaWheelPainter(
                                wheelNumbers: _allWheelNumbers.isNotEmpty ? _allWheelNumbers : widget.cartillaNumbers,
                                selectedCartilla: _selectedCartilla,
                                isSpinning: _isSpinning,
                                showIndicator: false, // No mostrar indicador en la ruleta
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Lista de ganadores
                    if (_winners.isNotEmpty)
                      Container(
                        height: 80,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏆 Ganadores:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _winners.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Cartilla ${_winners[index]}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Resultado de la cartilla seleccionada
                    if (_selectedCartilla != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.celebration, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '¡Cartilla Ganadora: $_selectedCartilla!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    Text(
                      _isSpinning 
                        ? '🎯 La ruleta está girando...' 
                        : '🎯 ¡Gira la ruleta para seleccionar una cartilla ganadora!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class CartillaWheelPainter extends CustomPainter {
  final List<int> wheelNumbers;
  final int? selectedCartilla;
  final bool isSpinning;
  final bool showIndicator; // Nuevo parámetro para controlar la visibilidad del indicador

  CartillaWheelPainter({
    required this.wheelNumbers,
    this.selectedCartilla,
    required this.isSpinning,
    this.showIndicator = true, // Valor por defecto
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    // Dibujar el borde exterior
    final borderPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
    
    canvas.drawCircle(center, radius, borderPaint);

    // Dibujar las secciones de la ruleta
    final sectionAngle = 2 * math.pi / wheelNumbers.length;
    
    for (int i = 0; i < wheelNumbers.length; i++) {
      final startAngle = i * sectionAngle;
      final endAngle = (i + 1) * sectionAngle;
      final isWinningNumber = selectedCartilla != null && wheelNumbers[i] == selectedCartilla && !isSpinning;
      
      // Color de la sección
      final sectionPaint = Paint()
        ..color = isWinningNumber 
          ? Colors.orange 
          : Colors.primaries[i % Colors.primaries.length].withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 4),
        startAngle,
        sectionAngle,
        true,
        sectionPaint,
      );
      
      // Borde de la sección - más grueso para el número ganador
      final sectionBorderPaint = Paint()
        ..color = isWinningNumber ? Colors.yellow : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = isWinningNumber ? 4.0 : 1.0; // Reducido para secciones pequeñas
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 4),
        startAngle,
        sectionAngle,
        true,
        sectionBorderPaint,
      );
      
      // Solo mostrar texto si la sección es lo suficientemente grande
      if (sectionAngle > 0.1) { // Mínimo ángulo para mostrar texto
        // Texto del número
        final textAngle = startAngle + sectionAngle / 2;
        final textRadius = radius * 0.7;
        final textX = center.dx + textRadius * math.cos(textAngle);
        final textY = center.dy + textRadius * math.sin(textAngle);
        
        final numberText = '${wheelNumbers[i]}';
        
        // Hacer el texto más grande para el número ganador, pero ajustar según el tamaño de la sección
        final baseFontSize = math.min(12.0, 360.0 / wheelNumbers.length); // Ajustar según número de secciones
        final fontSize = isWinningNumber ? math.max(14.0, baseFontSize * 1.5) : baseFontSize;
        final fontWeight = isWinningNumber ? FontWeight.bold : FontWeight.normal;
        final textColor = isWinningNumber ? Colors.white : Colors.white;
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: numberText,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            textX - textPainter.width / 2,
            textY - textPainter.height / 2,
          ),
        );
        
        // Agregar un círculo de resplandor para el número ganador
        if (isWinningNumber) {
          final glowPaint = Paint()
            ..color = Colors.yellow.withOpacity(0.3)
            ..style = PaintingStyle.fill;
          
          canvas.drawCircle(
            Offset(textX, textY),
            fontSize + 4,
            glowPaint,
          );
        }
      }
    }
    
    // Centro de la ruleta
    final centerPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 20, centerPaint);
    
    // Mostrar el número ganador en el centro
    if (selectedCartilla != null && !isSpinning) {
      final centerText = '${selectedCartilla}';
      final centerTextPainter = TextPainter(
        text: TextSpan(
          text: centerText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      centerTextPainter.layout();
      centerTextPainter.paint(
        canvas,
        Offset(
          center.dx - centerTextPainter.width / 2,
          center.dy - centerTextPainter.height / 2,
        ),
      );
    }
    
    // Indicador - calcular la posición correcta basada en el número seleccionado
    if (selectedCartilla != null && !isSpinning && showIndicator) { // Solo mostrar si showIndicator es true
      final selectedIndex = wheelNumbers.indexOf(selectedCartilla!);
      if (selectedIndex != -1) {
        final indicatorAngle = selectedIndex * sectionAngle + sectionAngle / 2;
        final indicatorRadius = radius - 12;
        final indicatorX = center.dx + indicatorRadius * math.cos(indicatorAngle);
        final indicatorY = center.dy + indicatorRadius * math.sin(indicatorAngle);
        
        final indicatorPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        
        final indicatorPath = Path();
        indicatorPath.moveTo(indicatorX, indicatorY);
        indicatorPath.lineTo(indicatorX - 12, indicatorY - 12);
        indicatorPath.lineTo(indicatorX + 12, indicatorY - 12);
        indicatorPath.close();
        
        canvas.drawPath(indicatorPath, indicatorPaint);
      }
    } else if (!showIndicator) {
      // Si showIndicator es false, no mostrar el indicador
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 