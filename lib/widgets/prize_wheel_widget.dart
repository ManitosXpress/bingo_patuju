import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
    
    // Si hay 12 o menos cartillas disponibles, mostrar todas mezcladas
    if (available.length <= 12) {
      final shuffled = List<int>.from(available);
      final random = math.Random.secure();
      shuffled.shuffle(random);
      return shuffled;
    }
    
    // Si hay más de 12, seleccionar 12 números completamente aleatorios
    final shuffled = List<int>.from(available);
    final random = math.Random.secure();
    shuffled.shuffle(random);
    
    // Tomar los primeros 12 después de mezclar
    return shuffled.take(12).toList();
  }

  // Obtener números visibles en la ruleta (solo los que están en _wheelNumbers)
  List<int> get _visibleWheelNumbers {
    return _wheelNumbers;
  }

  // Obtener todas las cartillas disponibles para la ruleta (máximo 500)
  List<int> get _allWheelNumbers {
    final available = _availableCartillas;
    if (available.isEmpty) return [];
    
    // Si hay más de 500 cartillas, seleccionar 500 completamente aleatorias
    if (available.length > 500) {
      // Crear una copia y mezclarla completamente
      final shuffled = List<int>.from(available);
      final random = math.Random.secure();
      shuffled.shuffle(random);
      
      // Tomar las primeras 500 después de mezclar
      return shuffled.take(500).toList();
    }
    
    // Si hay 500 o menos, devolver todas mezcladas para aleatoriedad completa
    final shuffled = List<int>.from(available);
    final random = math.Random.secure();
    shuffled.shuffle(random);
    return shuffled;
  }

  static const String _winnersKey = 'prize_wheel_winners';
  static const String _usedCartillasKey = 'prize_wheel_used_cartillas';

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Reducido a 2 segundos para más rapidez
      vsync: this,
    );
    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic, // Acelera rápido y desacelera suavemente (más emocionante)
    ));
    
    // Cargar ganadores guardados
    _loadWinners();
  }

  // Cargar ganadores desde SharedPreferences
  Future<void> _loadWinners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final winnersJson = prefs.getString(_winnersKey);
      final usedCartillasJson = prefs.getString(_usedCartillasKey);
      
      if (winnersJson != null) {
        final winnersList = jsonDecode(winnersJson) as List<dynamic>;
        setState(() {
          _winners = winnersList.map((e) => e as int).toList();
        });
      }
      
      if (usedCartillasJson != null) {
        final usedList = jsonDecode(usedCartillasJson) as List<dynamic>;
        setState(() {
          _usedCartillas = usedList.map((e) => e as int).toSet();
        });
      }
    } catch (e) {
      print('Error cargando ganadores: $e');
    }
  }

  // Guardar ganadores en SharedPreferences
  Future<void> _saveWinners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_winnersKey, jsonEncode(_winners));
      await prefs.setString(_usedCartillasKey, jsonEncode(_usedCartillas.toList()));
    } catch (e) {
      print('Error guardando ganadores: $e');
    }
  }

  // Eliminar todos los ganadores
  Future<void> _clearWinners() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Ganadores'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar todos los ganadores registrados?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_winnersKey);
        await prefs.remove(_usedCartillasKey);
        
        setState(() {
          _winners = [];
          _usedCartillas = {};
          _selectedCartilla = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Ganadores eliminados correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error eliminando ganadores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      _spinningSequence = null; // Resetear la secuencia para cada nuevo giro
    });
    
    // Crear una copia de la lista y mezclarla completamente para aleatoriedad real
    final shuffledNumbers = List<int>.from(allNumbers);
    final random = math.Random.secure(); // Usar Random.secure() para mejor aleatoriedad
    shuffledNumbers.shuffle(random);
    
    // Seleccionar un número completamente aleatorio de la lista mezclada
    final selectedCartilla = shuffledNumbers[random.nextInt(shuffledNumbers.length)];
    
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
      
      // Guardar ganadores después de agregar uno nuevo
      _saveWinners();
      
      // Llamar al callback con la cartilla seleccionada
      if (widget.onPrizeSelected != null) {
        widget.onPrizeSelected!(selectedCartilla);
      }
    });
  }

  // Lista de números mezclados para mostrar durante el giro
  List<int>? _spinningSequence;
  
  // Método para obtener el número que se muestra mientras gira
  String _getSpinningNumber() {
    if (!_isSpinning) return '';
    
    final allNumbers = _allWheelNumbers;
    if (allNumbers.isEmpty) return '';
    
    // Crear una secuencia aleatoria mezclada al inicio del giro
    if (_spinningSequence == null || _spinningSequence!.isEmpty) {
      _spinningSequence = List<int>.from(allNumbers);
      final random = math.Random.secure();
      _spinningSequence!.shuffle(random);
    }
    
    // Calcular qué número mostrar basado en el progreso de la animación
    final progress = _spinAnimation.value;
    final totalNumbers = _spinningSequence!.length;
    
    // Optimización: Usar la misma curva que la animación para consistencia
    // Crear efecto de ruleta que acelera rápido al inicio y desacelera al final
    // Usar más ciclos al inicio (rápido) y menos al final (lento)
    final speedMultiplier = 1.0 + (1.0 - progress) * 2.0; // Más rápido al inicio
    final cycles = 20.0 * speedMultiplier; // Ciclos dinámicos que se reducen con el tiempo
    final index = ((progress * totalNumbers * cycles) % totalNumbers).floor();
    
    return '${_spinningSequence![index]}';
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
                            _saveWinners(); // Guardar después de reiniciar
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reiniciar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      if (_allWheelNumbers.isEmpty)
                        const SizedBox(width: 8),
                      // Botón para eliminar ganadores (solo se muestra si hay ganadores)
                      if (_winners.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _clearWinners,
                          icon: const Icon(Icons.delete_sweep),
                          label: const Text('Eliminar Ganadores'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      if (_winners.isNotEmpty)
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
            
            // Ruleta centrada con números girando en el centro
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Contenedor de la ruleta
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ruleta giratoria (solo colores, sin números) - Optimizada con RepaintBoundary
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _spinAnimation,
                            builder: (context, child) {
                              // Optimización: Calcular el ángulo una sola vez
                              // Reducir rotaciones para mejor rendimiento (de 50 a 30)
                              final rotationAngle = _spinAnimation.value * 30 * math.pi;
                              return Transform.rotate(
                                angle: rotationAngle,
                                child: Container(
                                  width: 280,
                                  height: 280,
                                  child: CustomPaint(
                                    painter: CartillaWheelPainter(
                                      wheelNumbers: _allWheelNumbers.isNotEmpty ? _allWheelNumbers : widget.cartillaNumbers,
                                      selectedCartilla: _selectedCartilla,
                                      isSpinning: _isSpinning,
                                      showNumbers: false, // No mostrar números en la ruleta
                                      showIndicator: false,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Números girando en el centro - Optimizado con RepaintBoundary
                        if (_isSpinning)
                          RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _spinAnimation,
                              builder: (context, _) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.orange.shade400,
                                        Colors.orange.shade600,
                                        Colors.orange.shade800,
                                      ],
                                    ),
                                    border: Border.all(color: Colors.orange.shade900, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.5),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getSpinningNumber(),
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.3),
                                            offset: const Offset(2, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        
                        // Número ganador final en el centro
                        if (!_isSpinning && _selectedCartilla != null)
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.orange.shade300,
                                  Colors.orange.shade700,
                                ],
                              ),
                              border: Border.all(color: Colors.white, width: 6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '$_selectedCartilla',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
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
  final bool showNumbers; // Nuevo parámetro para controlar si mostrar números

  CartillaWheelPainter({
    required this.wheelNumbers,
    this.selectedCartilla,
    required this.isSpinning,
    this.showIndicator = true, // Valor por defecto
    this.showNumbers = true, // Valor por defecto
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    // Dibujar el borde exterior más grueso y colorido
    final borderPaint = Paint()
      ..color = Colors.orange.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;
    
    canvas.drawCircle(center, radius, borderPaint);

    // Dibujar las secciones de la ruleta con colores más vibrantes
    final sectionAngle = 2 * math.pi / wheelNumbers.length;
    
    // Colores vibrantes para las secciones
    final vibrantColors = [
      Colors.red.shade500,
      Colors.orange.shade500,
      Colors.yellow.shade500,
      Colors.green.shade500,
      Colors.blue.shade500,
      Colors.purple.shade500,
      Colors.pink.shade500,
      Colors.teal.shade500,
      Colors.cyan.shade500,
      Colors.lime.shade500,
      Colors.indigo.shade500,
      Colors.amber.shade500,
    ];
    
    for (int i = 0; i < wheelNumbers.length; i++) {
      final startAngle = i * sectionAngle;
      final endAngle = (i + 1) * sectionAngle;
      final isWinningNumber = selectedCartilla != null && wheelNumbers[i] == selectedCartilla && !isSpinning;
      
      // Color de la sección - más vibrante
      final sectionPaint = Paint()
        ..color = isWinningNumber 
          ? Colors.orange.shade600
          : vibrantColors[i % vibrantColors.length]
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        startAngle,
        sectionAngle,
        true,
        sectionPaint,
      );
      
      // Borde de la sección - más grueso y visible
      final sectionBorderPaint = Paint()
        ..color = isWinningNumber ? Colors.yellow.shade300 : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = isWinningNumber ? 3.0 : 2.0;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        startAngle,
        sectionAngle,
        true,
        sectionBorderPaint,
      );
      
      // Solo mostrar texto si showNumbers es true y la sección es lo suficientemente grande
      if (showNumbers && sectionAngle > 0.1) { // Mínimo ángulo para mostrar texto
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
    
    // Centro de la ruleta con gradiente
    final centerGradient = RadialGradient(
      colors: [
        Colors.orange.shade400,
        Colors.orange.shade700,
      ],
    );
    
    final centerPaint = Paint()
      ..shader = centerGradient.createShader(Rect.fromCircle(center: center, radius: 25))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 25, centerPaint);
    
    // Borde del centro
    final centerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(center, 25, centerBorderPaint);
    
    // Mostrar el número ganador en el centro
    if (selectedCartilla != null && !isSpinning) {
      final centerText = '${selectedCartilla}';
      final centerTextPainter = TextPainter(
        text: TextSpan(
          text: centerText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
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
