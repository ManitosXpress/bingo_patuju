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
    return Container(
      width: 65, // Reducido de 70 a 65 para mejor ajuste
      child: Column(
        children: List.generate(end - start + 1, (index) {
          int number = start + index;
          bool isCalled = calledNumbers.contains(number);
          return Container(
            width: 60, // Reducido de 60 a 55 para que se vean los últimos
            height: 34, // Reducido de 35 a 32 para que se vean los últimos
            margin: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 0.5), // Reducido más el espaciado
            decoration: BoxDecoration(
              gradient: isCalled 
                ? LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.grey.shade50, Colors.grey.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: BorderRadius.circular(8), // Aumentado de 6 a 8
              border: Border.all(
                color: isCalled ? Colors.red.shade600 : Colors.grey.shade300,
                width: isCalled ? 2.0 : 1.5, // Aumentado el grosor del borde
              ),
              boxShadow: isCalled ? [
                BoxShadow(
                  color: Colors.red.shade200,
                  blurRadius: 4,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 1),
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
                number.toString(),
                style: TextStyle(
                  fontSize: 14, // Reducido de 16 a 14 para mejor ajuste
                  fontWeight: FontWeight.bold,
                  color: isCalled ? Colors.white : Colors.grey.shade700,
                  shadows: isCalled ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ] : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
} 