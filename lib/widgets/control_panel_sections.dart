import 'package:flutter/material.dart';
import '../models/bingo_game.dart';

class CurrentBallDisplay extends StatelessWidget {
  final BingoGame bingoGame;
  final int calledNumbersCount;
  final int totalBalls;

  const CurrentBallDisplay({
    super.key,
    required this.bingoGame,
    required this.calledNumbersCount,
    required this.totalBalls,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              bingoGame.currentBall > 0 
                ? _getBallLabel(bingoGame.currentBall)
                : '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$calledNumbersCount/$totalBalls',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBallLabel(int number) {
    if (number >= 1 && number <= 15) return 'B$number';
    if (number >= 16 && number <= 30) return 'I$number';
    if (number >= 31 && number <= 45) return 'N$number';
    if (number >= 46 && number <= 60) return 'G$number';
    if (number >= 61 && number <= 75) return 'O$number';
    return number.toString();
  }
}

class ActionButtonsRow extends StatelessWidget {
  final VoidCallback onCallNumber;
  final VoidCallback onVerifyBingo;

  const ActionButtonsRow({
    super.key,
    required this.onCallNumber,
    required this.onVerifyBingo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCallNumber,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Cantar Bola'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onVerifyBingo,
                icon: const Icon(Icons.check),
                label: const Text('Verificar Bingo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

      ],
    );
  }
}

class SecondaryButtonsRow extends StatelessWidget {
  final VoidCallback onViewCartillas;
  final VoidCallback onReset;

  const SecondaryButtonsRow({
    super.key,
    required this.onViewCartillas,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onViewCartillas,
            icon: const Icon(Icons.grid_on),
            label: const Text('Ver Cartillas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh),
            label: const Text('Resetear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class ShuffleButton extends StatelessWidget {
  final VoidCallback onShuffle;

  const ShuffleButton({
    super.key,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onShuffle,
            icon: const Icon(Icons.shuffle),
            label: const Text('Barajar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class GameStatsCard extends StatelessWidget {
  final int calledNumbersCount;
  final int remainingBalls;
  final int cartillasCount;

  const GameStatsCard({
    super.key,
    required this.calledNumbersCount,
    required this.remainingBalls,
    required this.cartillasCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bolas cantadas: $calledNumbersCount',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Bolas restantes: $remainingBalls',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Cartillas generadas: $cartillasCount',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class CalledNumbersSection extends StatelessWidget {
  final List<int> calledNumbers;

  const CalledNumbersSection({
    super.key,
    required this.calledNumbers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bolas Cantadas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Grid de bolas cantadas
        if (calledNumbers.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: calledNumbers.map((number) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getBallLabel(number),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _getBallLabel(int number) {
    if (number >= 1 && number <= 15) return 'B$number';
    if (number >= 16 && number <= 30) return 'I$number';
    if (number >= 31 && number <= 45) return 'N$number';
    if (number >= 46 && number <= 60) return 'G$number';
    if (number >= 61 && number <= 75) return 'O$number';
    return number.toString();
  }
} 