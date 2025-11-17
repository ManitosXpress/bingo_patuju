import 'package:flutter/material.dart';

class NumbersPanel extends StatelessWidget {
  final List<int> allNumbers;
  final List<int> calledNumbers;

  const NumbersPanel({
    super.key,
    required this.allNumbers,
    required this.calledNumbers,
  });

  String _getColumnLetter(int number) {
    if (number >= 1 && number <= 15) return 'B';
    if (number >= 16 && number <= 30) return 'I';
    if (number >= 31 && number <= 45) return 'N';
    if (number >= 46 && number <= 60) return 'G';
    if (number >= 61 && number <= 75) return 'O';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(8), // Reducido de 8 a 6 para mejor ajuste
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Aumentado de 8 a 12
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Aumentado el padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.circular(8), // Aumentado de 6 a 8
            ),
            child: const Text(
              'Números del Bingo',
              style: TextStyle(
                fontSize: 18, // Aumentado de 16 a 18
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8), // Reducido de 10 a 8 para mejor ajuste
          // Encabezados de columnas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColumnHeader('B', '1-15'),
              _buildColumnHeader('I', '16-30'),
              _buildColumnHeader('N', '31-45'),
              _buildColumnHeader('G', '46-60'),
              _buildColumnHeader('O', '61-75'),
            ],
          ),
          const SizedBox(height: 8), // Reducido de 10 a 8 para mejor ajuste
          // Números del bingo
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberColumn('B', 1, 15),
                      _buildNumberColumn('I', 16, 30),
                      _buildNumberColumn('N', 31, 45),
                      _buildNumberColumn('G', 46, 60),
                      _buildNumberColumn('O', 61, 75),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String letter, String range) {
    return Container(
      width: 65, // Reducido de 70 a 65 para coincidir con las columnas
      padding: const EdgeInsets.symmetric(vertical: 6), // Aumentado de 4 a 6
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.blue.shade200],
        ),
        borderRadius: BorderRadius.circular(8), // Aumentado de 5 a 8
        border: Border.all(color: Colors.blue.shade300, width: 1.5), // Aumentado de 1 a 1.5
      ),
      child: Column(
        children: [
          Text(
            letter,
            style: TextStyle(
              fontSize: 18, // Reducido de 20 a 18 para mejor ajuste
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          Text(
            range,
            style: TextStyle(
              fontSize: 10, // Reducido de 11 a 10 para mejor ajuste
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberColumn(String letter, int start, int end) {
    // Colores vibrantes por columna
    final columnColors = {
      'B': [Colors.blue.shade400, Colors.blue.shade600],
      'I': [Colors.cyan.shade400, Colors.cyan.shade600],
      'N': [Colors.grey.shade400, Colors.grey.shade600],
      'G': [Colors.green.shade400, Colors.green.shade600],
      'O': [Colors.orange.shade400, Colors.orange.shade600],
    };
    
    final colors = columnColors[letter] ?? [Colors.grey.shade400, Colors.grey.shade600];
    
    return Container(
      width: 65,
      child: Column(
        children: List.generate(end - start + 1, (index) {
          int number = start + index;
          bool isCalled = calledNumbers.contains(number);
          return _AnimatedNumberTile(
            number: number,
            isCalled: isCalled,
            colors: colors,
            letter: letter,
          );
        }),
      ),
    );
  }
}

// Widget animado para cada número
class _AnimatedNumberTile extends StatefulWidget {
  final int number;
  final bool isCalled;
  final List<Color> colors;
  final String letter;

  const _AnimatedNumberTile({
    required this.number,
    required this.isCalled,
    required this.colors,
    required this.letter,
  });

  @override
  State<_AnimatedNumberTile> createState() => _AnimatedNumberTileState();
}

class _AnimatedNumberTileState extends State<_AnimatedNumberTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  bool _wasCalled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _wasCalled = widget.isCalled;
  }

  @override
  void didUpdateWidget(_AnimatedNumberTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCalled && !_wasCalled) {
      _wasCalled = true;
      _pulseController.forward(from: 0).then((_) {
        _pulseController.reverse();
      });
    } else if (!widget.isCalled && _wasCalled) {
      _wasCalled = false;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, _) {
        return Transform.scale(
          scale: widget.isCalled ? _scaleAnimation.value : 1.0,
          child: Container(
            width: 60,
            height: 34,
            margin: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 0.5),
            decoration: BoxDecoration(
              gradient: widget.isCalled 
                ? LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      widget.colors[0].withValues(alpha: 0.3),
                      widget.colors[1].withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isCalled 
                  ? Colors.red.shade700 
                  : widget.colors[1].withValues(alpha: 0.5),
                width: widget.isCalled ? 2.5 : 1.5,
              ),
              boxShadow: widget.isCalled ? [
                BoxShadow(
                  color: Colors.red.shade300,
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.number.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.isCalled ? Colors.white : Colors.grey.shade700,
                  shadows: widget.isCalled ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ] : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 