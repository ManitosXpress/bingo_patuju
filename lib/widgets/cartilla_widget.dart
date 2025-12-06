import 'package:flutter/material.dart';

/// Widget para mostrar cartillas de bingo con soporte para impresión
/// 
/// Uso básico:
/// ```dart
/// CartillaWidget(
///   numbers: bingoNumbers,
///   cardNumber: "15",
///   date: "2025-08-25",
///   price: "Bs. 20",
/// )
/// ```
/// 
/// Para impresión (sin márgenes exteriores):
/// ```dart
/// CartillaWidget.createForPrint(
///   numbers: bingoNumbers,
///   cardNumber: "15",
///   date: "2025-08-25",
///   price: "Bs. 20",
/// )
/// ```
/// 
/// Para modo compacto:
/// ```dart
/// CartillaWidget.createCompact(
///   numbers: bingoNumbers,
///   cardNumber: "15",
///   date: "2025-08-25",
///   price: "Bs. 20",
/// )
/// ```
class CartillaWidget extends StatelessWidget {
  final List<List<int>> numbers;
  final String? cardNumber;
  final String? date;
  final String? price;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool compact; // Nuevo parámetro para modo compacto
  final bool forPrint; // Nuevo parámetro para impresión

  const CartillaWidget({
    super.key,
    required this.numbers,
    this.cardNumber,
    this.date,
    this.price,
    this.isSelected = false,
    this.onTap,
    this.compact = false, // Por defecto no es compacto
    this.forPrint = false, // Por defecto no es para impresión
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: compact ? null : (forPrint ? double.infinity : 550), // Ocupar todo el ancho si es para impresión
        height: compact ? null : (forPrint ? null : null), // Altura automática para impresión
        constraints: compact ? null : (forPrint ? null : const BoxConstraints(
          maxHeight: 800, // Altura máxima solo para visualización normal
        )),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: compact ? BorderRadius.circular(12) : BorderRadius.zero, // Sin bordes redondeados para impresión
          border: compact ? Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ) : null, // Sin borde para impresión
          boxShadow: compact ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null, // Sin sombra para impresión
        ),
        child: compact ? _buildCompactLayout() : (forPrint ? _buildPrintLayout() : _buildFullLayout()),
      ),
    );
  }

  // Layout completo para visualización y descarga
  Widget _buildFullLayout() {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 2), // Borde principal de toda la cartilla
          borderRadius: BorderRadius.circular(16), // Bordes redondeados para toda la cartilla
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: _buildCartillaContent(isForPrint: false),
      ),
    );
  }

  // Layout para impresión (sin márgenes exteriores)
  Widget _buildPrintLayout() {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 2), // Borde principal de toda la cartilla
          borderRadius: BorderRadius.circular(16), // Bordes redondeados para toda la cartilla
        ),
        child: _buildCartillaContent(isForPrint: true),
      ),
    );
  }

  // Contenido de la cartilla (reutilizable)
  Widget _buildCartillaContent({bool isForPrint = false}) {
    if (isForPrint) {
      // Para impresión: layout simple con Stack pero sin Positioned.fill que limite el tamaño
      return Container(
        color: Colors.white,
        child: Stack(
          clipBehavior: Clip.none, // No recortar contenido que se salga
          children: [
            // Marca de agua de fondo - bingo_imperial.png (sin Positioned.fill para no limitar)
            Center(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/images/bingo_imperial.png',
                  fit: BoxFit.contain,
                  width: 320,
                  height: 320,
                ),
              ),
            ),
            // Contenido principal sin restricciones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min, // No expandir más del necesario
                children: [
                  _buildHeader(isForPrint: true),
                  const SizedBox(height: 0.1),
                  _buildBingoGrid(isForPrint: true),
                  const SizedBox(height: 0.1),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Para visualización normal: usar Stack con Positioned.fill
    return Stack(
      children: [
        // Marca de agua de fondo - bingo_imperial.png
        Positioned.fill(
          child: Center(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/bingo_imperial.png',
                fit: BoxFit.contain,
                width: 280,
                height: 280,
              ),
            ),
          ),
        ),
        
        // Contenido principal de la cartilla
        Positioned.fill(
          child: ClipRect(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 1),
                    Transform.translate(
                      offset: const Offset(0, -14),
                      child: _buildBingoGrid(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Layout compacto para listas
  Widget _buildCompactLayout() {
    return Column(
      children: [
        _buildCompactHeader(),
        _buildCompactBingoGrid(),
      ],
    );
  }

  // Header para modo completo
  Widget _buildHeader({bool isForPrint = false}) {
    // Para formato carta vertical, usar tamaños más grandes pero proporcionados
    final double headerScale = isForPrint ? 1.6 : 1.2; // Escala aumentada para mejor presencia en descargas
    final double cardBoxWidth = (isForPrint ? 82 : 70) * headerScale;
    final double cardBoxHeight = (isForPrint ? 68 : 60) * headerScale;
    final double centerWidth = 165 * headerScale;
    // Usar un ancho común para los lados para asegurar que el logo quede centrado
    final double sideWidth = 110 * headerScale; 
    final double spacing = 18 * headerScale;
    final double labelFont = 11.5 * headerScale;
    final double numberFont = 21.5 * headerScale;
    final double infoLabelFont = 13.5 * headerScale;
    final double infoValueFont = 12.5 * headerScale;
    final double logoSize = 165 * headerScale;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isForPrint ? 8 : 10,
        vertical: isForPrint ? 0 : 10, // Padding vertical eliminado para impresión
      ), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero, // Sin bordes redondeados para impresión
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Cambiar a center para agrupar elementos
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left side - Card number box (centrado en su contenedor)
          SizedBox(
            width: sideWidth,
            child: Center(
              child: Container(
                width: cardBoxWidth,
                height: cardBoxHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "CARTILLA",
                      style: TextStyle(
                        fontSize: labelFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 1), // Espaciado reducido
                    Text(
                      cardNumber ?? "#",
                      style: TextStyle(
                        fontSize: numberFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(width: spacing),
          
          // Center - Logo and title (más grande)
          Container(
            width: centerWidth,
            child: Column(
              children: [
                // Logo con imagen logo.png
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: logoSize,
                    width: logoSize,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: spacing),
          
          // Right side - Date and Price labels (centrado en su contenedor)
          SizedBox(
            width: sideWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Centrar texto
              children: [
                Text(
                  "FECHA:",
                  style: TextStyle(
                    fontSize: infoLabelFont,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  date ?? "N/A",
                  style: TextStyle(
                    fontSize: infoValueFont,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: spacing / 3),
                Text(
                  "PRECIO:",
                  style: TextStyle(
                    fontSize: infoLabelFont,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  price ?? "N/A",
                  style: TextStyle(
                    fontSize: infoValueFont,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header para modo compacto
  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // Card number box más pequeño
          Container(
            width: 50,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cardNumber ?? "#",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "CART",
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Título más pequeño
       
          
          const SizedBox(width: 8),
          
          // Logo pequeño

        ],
      ),
    );
  }

  // Grid completo de bingo
  Widget _buildBingoGrid({bool isForPrint = false}) {
    // Para formato carta vertical (850x1100), ajustar tamaños para que quepa bien
    // Cálculo: 850px - 50px padding = 800px / 5 celdas = ~160px máximo por celda
    // Usamos 130px para dejar margen de seguridad y que quepa en altura
    final cellSize = isForPrint ? 130.0 : 90.0; // Celdas ajustadas para evitar overflow
    final cellMargin = isForPrint ? 1.5 : 2.0; // Márgenes reducidos
    
    return Container(
      padding: EdgeInsets.all(isForPrint ? 0 : 10), // Padding reducido a 0 para formato carta
      margin: EdgeInsets.all(isForPrint ? 0 : 4), // Sin margen para aprovechar espacio
      child: Stack(
        children: [
          // Background watermark - B premium con anillos (parte superior izquierda)
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              width: 50, // Tamaño reducido para ahorrar espacio
              height: 50, // Tamaño reducido para ahorrar espacio
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.25),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 0.8,
                    colors: [
                      const Color(0xFFFFD700).withValues(alpha: 0.15),
                      const Color(0xFFFF8C00).withValues(alpha: 0.15),
                      const Color(0xFFFF6B35).withValues(alpha: 0.15),
                      const Color(0xFFFF5722).withValues(alpha: 0.15),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Center(
                  child: Text(
                    "B",
                    style: TextStyle(
                      fontSize: 25, // Fuente reducida para ahorrar espacio
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.2),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Bingo grid completo
          Column(
            children: [
              // Header row with B I N G O
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (String letter in ['B', 'I', 'N', 'G', 'O'])
                    Container(
                      height: cellSize,
                      width: cellSize,
                      margin: EdgeInsets.all(cellMargin),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C00),
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: isForPrint ? 38 : 28, // Fuente ajustada para formato carta
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      ),
                    ),
                ],
              ),
              
              // Number rows
              for (int row = 0; row < 5; row++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int col = 0; col < 5; col++)
                      Container(
                        height: cellSize,
                        width: cellSize,
                        margin: EdgeInsets.all(cellMargin),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: _buildCellContent(row, col, isForPrint: isForPrint),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Grid compacto para listas
  Widget _buildCompactBingoGrid() {
    final cellHeight = 35.0; // Altura aumentada proporcionalmente
    final letterFontSize = 16.0; // Fuente aumentada proporcionalmente
    
    return Container(
      padding: const EdgeInsets.all(12), // Padding para mejor presentación
      margin: const EdgeInsets.all(6), // Margen interior de la cuadrícula compacta
      child: Column(
        children: [
          // Header row with B I N G O
          Row(
            children: [
              for (String letter in ['B', 'I', 'N', 'G', 'O'])
                Expanded(
                  child: Container(
                    height: cellHeight,
                    margin: const EdgeInsets.all(2.5), // Margen ajustado para modo compacto
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00),
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: letterFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // Number rows
          for (int row = 0; row < 5; row++)
            Row(
              children: [
                for (int col = 0; col < 5; col++)
                  Expanded(
                    child: Container(
                      height: cellHeight,
                      margin: const EdgeInsets.all(2.5), // Margen ajustado para modo compacto
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: _buildCompactCellContent(row, col),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // Contenido de celda para modo completo
  Widget _buildCellContent(int row, int col, {bool isForPrint = false}) {
    // Center cell (free space) - Mostrar "FREE"
    if (row == 2 && col == 2) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isForPrint ? 8.0 : 6.0),
          child: Image.asset(
            'assets/images/free.png',
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    
    // Number cells
    if (row < numbers.length && col < numbers[row].length) {
      final number = numbers[row][col];
      return Text(
        number.toString(),
        style: TextStyle(
          fontSize: isForPrint ? 40 : 30, // Fuente ajustada para formato carta
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  // Contenido de celda compacta
  Widget _buildCompactCellContent(int row, int col) {
    // Center cell (free space) - Mostrar "FREE"
    if (row == 2 && col == 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            'assets/images/free.png',
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    
    // Number cells
    if (row < numbers.length && col < numbers[row].length) {
      final number = numbers[row][col];
      return Text(
        number.toString(),
        style: TextStyle(
          fontSize: 14, // Fuente aumentada proporcionalmente
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  // Método estático para crear una cartilla optimizada para impresión
  static Widget createForPrint({
    required List<List<int>> numbers,
    String? cardNumber,
    String? date,
    String? price,
  }) {
    return CartillaWidget(
      numbers: numbers,
      cardNumber: cardNumber,
      date: date,
      price: price,
      forPrint: true,
    );
  }

  // Método estático para crear una cartilla compacta
  static Widget createCompact({
    required List<List<int>> numbers,
    String? cardNumber,
    String? date,
    String? price,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return CartillaWidget(
      numbers: numbers,
      cardNumber: cardNumber,
      date: date,
      price: price,
      compact: true,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}