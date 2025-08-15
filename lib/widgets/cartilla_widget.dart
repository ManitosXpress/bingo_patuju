import 'package:flutter/material.dart';

class CartillaWidget extends StatelessWidget {
  final List<List<int>> numbers;
  final String? cardNumber;
  final String? date;
  final String? price;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool compact; // Nuevo parámetro para modo compacto

  const CartillaWidget({
    super.key,
    required this.numbers,
    this.cardNumber,
    this.date,
    this.price,
    this.isSelected = false,
    this.onTap,
    this.compact = false, // Por defecto no es compacto
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: compact ? null : 612, // Ancho fijo para modo completo - hoja carta (8.5" x 72 DPI)
        height: compact ? null : null, // Altura flexible para evitar overflow
        constraints: compact ? null : const BoxConstraints(
          maxHeight: 792, // Altura máxima para hoja carta
        ),
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
        child: compact ? _buildCompactLayout() : _buildFullLayout(),
      ),
    );
  }

  // Layout completo para visualización y descarga
  Widget _buildFullLayout() {
    return RepaintBoundary(
      child: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Marca de agua de fondo - bingo_imperial.png
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.25, // Opacidad reducida para impresión
                  child: Image.asset(
                    'assets/images/bingo_imperial.png',
                    fit: BoxFit.contain,
                    width: 350, // Tamaño reducido para evitar overflow
                    height: 350,
                  ),
                ),
              ),
            ),
            
            // Contenido principal de la cartilla con scroll
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(40), // Márgenes reducidos para evitar overflow
                child: Column(
                  mainAxisSize: MainAxisSize.min, // No expandir más del necesario
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20), // Espaciado reducido
                    _buildBingoGrid(),
                    const SizedBox(height: 20), // Espacio adicional al final
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16), // Padding reducido para evitar overflow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero, // Sin bordes redondeados para impresión
      ),
      child: Row(
        children: [
          // Left side - Card number box
          Container(
            width: 80, // Tamaño reducido para evitar overflow
            height: 70, // Altura reducida para evitar overflow
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
                    fontSize: 12, // Fuente reducida para evitar overflow
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cardNumber ?? "#",
                  style: TextStyle(
                    fontSize: 20, // Fuente reducida para evitar overflow
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16), // Espaciado reducido
          
          // Center - Logo and title
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 10), // Espaciado reducido
                
                // Logo con imagen bingo_imperial.png (más grande, sin texto)
                Center(
                  child: Image.asset(
                    'assets/images/bingo_imperial.png',
                    height: 140, // Tamaño reducido para evitar overflow
                    width: 140,
                  ),
                ),
                
                const SizedBox(height: 10), // Espaciado reducido
              ],
            ),
          ),
          
          const SizedBox(width: 16), // Espaciado reducido
          
          // Right side - Date and Price labels
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "FECHA:",
                style: TextStyle(
                  fontSize: 16, // Fuente reducida para evitar overflow
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                date ?? "N/A",
                style: TextStyle(
                  fontSize: 14, // Fuente reducida para evitar overflow
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8), // Espaciado reducido
              Text(
                "PRECIO:",
                style: TextStyle(
                  fontSize: 16, // Fuente reducida para evitar overflow
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                price ?? "N/A",
                style: TextStyle(
                  fontSize: 14, // Fuente reducida para evitar overflow
                  color: Colors.black87,
                ),
              ),
            ],
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
  Widget _buildBingoGrid() {
    return Container(
      padding: const EdgeInsets.all(16), // Padding reducido para evitar overflow
      child: Stack(
        children: [
          // Background watermark - B premium con anillos (parte superior izquierda)
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              width: 80, // Tamaño reducido para evitar overflow
              height: 80,
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
                      fontSize: 40, // Fuente reducida para evitar overflow
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
                children: [
                  for (String letter in ['B', 'I', 'N', 'G', 'O'])
                    Expanded(
                      child: Container(
                        height: 50, // Altura reducida para evitar overflow
                        margin: const EdgeInsets.all(2), // Margen reducido para evitar overflow
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C00),
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            letter,
                            style: const TextStyle(
                              fontSize: 22, // Fuente reducida para evitar overflow
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
                          height: 50, // Altura reducida para evitar overflow
                          margin: const EdgeInsets.all(2), // Margen reducido para evitar overflow
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: _buildCellContent(row, col),
                          ),
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
    final cellHeight = 30.0;
    final letterFontSize = 14.0;
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Header row with B I N G O
          Row(
            children: [
              for (String letter in ['B', 'I', 'N', 'G', 'O'])
                Expanded(
                  child: Container(
                    height: cellHeight,
                    margin: const EdgeInsets.all(2),
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
                      margin: const EdgeInsets.all(2),
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
  Widget _buildCellContent(int row, int col) {
    // Center cell (free space) - Logo bingo_imperial.png
    if (row == 2 && col == 2) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/bingo_imperial.png',
            height: 28, // Tamaño reducido para evitar overflow
            width: 28,
          ),
          const SizedBox(height: 1), // Espaciado reducido
          const Text(
            "#CARTILLA",
            style: TextStyle(
              fontSize: 8, // Fuente reducida para evitar overflow
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      );
    }
    
    // Number cells
    if (row < numbers.length && col < numbers[row].length) {
      final number = numbers[row][col];
      return Text(
        number.toString(),
        style: const TextStyle(
          fontSize: 20, // Fuente reducida para evitar overflow
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  // Contenido de celda compacta
  Widget _buildCompactCellContent(int row, int col) {
    // Center cell (free space)
    if (row == 2 && col == 2) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C00),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                "B",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "#CART",
            style: TextStyle(
              fontSize: 6,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      );
    }
    
    // Number cells
    if (row < numbers.length && col < numbers[row].length) {
      final number = numbers[row][col];
      return Text(
        number.toString(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
} 