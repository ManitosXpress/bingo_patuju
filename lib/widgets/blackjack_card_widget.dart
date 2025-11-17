import 'package:flutter/material.dart';

class BlackjackCardWidget extends StatelessWidget {
  final String suit;
  final String value;
  final bool isFaceUp;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const BlackjackCardWidget({
    super.key,
    required this.suit,
    required this.value,
    this.isFaceUp = true,
    this.width = 60,
    this.height = 84,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: isFaceUp ? _buildFaceUpCard() : _buildFaceDownCard(),
      ),
    );
  }

  Widget _buildFaceUpCard() {
    Color cardColor = _getCardColor();
    Color textColor = _getTextColor();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Patrón de fondo sutil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
              ),
            ),
          ),
          // Contenido principal de la carta
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Valor superior grande
                Text(
                  value,
                  style: TextStyle(
                    fontSize: width * 0.25,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 1,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Palo grande
                Text(
                  suit,
                  style: TextStyle(
                    fontSize: width * 0.3,
                    color: cardColor,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 1,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Valor inferior (rotado)
                Transform.rotate(
                  angle: 3.14159, // 180 grados
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: width * 0.25,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 1,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Esquinas decorativas
          Positioned(
            top: 4,
            left: 4,
            child: Text(
              value,
              style: TextStyle(
                fontSize: width * 0.15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Transform.rotate(
              angle: 3.14159,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: width * 0.15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          // Palo en esquinas
          Positioned(
            top: 4,
            right: 4,
            child: Text(
              suit,
              style: TextStyle(
                fontSize: width * 0.18,
                color: cardColor,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Transform.rotate(
              angle: 3.14159,
              child: Text(
                suit,
                style: TextStyle(
                  fontSize: width * 0.18,
                  color: cardColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceDownCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade600,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.casino,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'CASINO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardColor() {
    switch (suit) {
      case '♥':
      case '♦':
        return Colors.red;
      case '♠':
      case '♣':
        return Colors.black;
      default:
        return Colors.black;
    }
  }

  Color _getTextColor() {
    switch (suit) {
      case '♥':
      case '♦':
        return Colors.red;
      case '♠':
      case '♣':
        return Colors.black;
      default:
        return Colors.black;
    }
  }
}

class CardHandWidget extends StatelessWidget {
  final List<Map<String, String>> cards;
  final bool isFaceUp;
  final double cardSpacing;
  final double cardWidth;
  final double cardHeight;

  const CardHandWidget({
    super.key,
    required this.cards,
    this.isFaceUp = true,
    this.cardSpacing = 15,
    this.cardWidth = 50,
    this.cardHeight = 70,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Container(
        height: cardHeight,
        width: 100,
        child: Center(
          child: Text(
            'Sin cartas',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Container(
      height: cardHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: cards.take(5).map((card) {
            return Padding(
              padding: EdgeInsets.only(right: 5),
              child: BlackjackCardWidget(
                suit: card['suit'] ?? '♠',
                value: card['value'] ?? 'A',
                isFaceUp: isFaceUp,
                width: cardWidth,
                height: cardHeight,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
