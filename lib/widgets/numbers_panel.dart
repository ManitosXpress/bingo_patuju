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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Números del Bingo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Expanded(
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
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String letter, String range) {
    return Container(
      width: 60,
      child: Column(
        children: [
          Text(
            letter,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          Text(
            range,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberColumn(String letter, int start, int end) {
    return Container(
      width: 60,
      child: Column(
        children: List.generate(end - start + 1, (index) {
          int number = start + index;
          bool isCalled = calledNumbers.contains(number);
          return Container(
            width: 50,
            height: 30,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isCalled ? Colors.red.shade400 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isCalled ? Colors.red.shade600 : Colors.grey.shade300,
                width: isCalled ? 2.0 : 1.0,
              ),
              boxShadow: isCalled ? [
                BoxShadow(
                  color: Colors.red.shade200,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCalled ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
} 