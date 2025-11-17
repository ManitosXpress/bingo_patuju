import 'package:flutter/material.dart';
import '../models/bingo_game.dart';

class CurrentBallDisplay extends StatefulWidget {
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
  State<CurrentBallDisplay> createState() => _CurrentBallDisplayState();
}

class _CurrentBallDisplayState extends State<CurrentBallDisplay>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  int _previousBall = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _previousBall = widget.bingoGame.currentBall;
  }

  @override
  void didUpdateWidget(CurrentBallDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bingoGame.currentBall != _previousBall && widget.bingoGame.currentBall > 0) {
      _previousBall = widget.bingoGame.currentBall;
      _rotationController.forward(from: 0);
      _pulseController.forward(from: 0).then((_) {
        _pulseController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ballSize = screenWidth > 1200 ? 150.0 : 120.0;
    
    return Column(
      children: [
        // Bola actual con animaciones
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: ballSize,
                        height: ballSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.red.shade600,
                              Colors.red.shade800,
                              Colors.red.shade900,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Efecto de brillo (shimmer)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.3),
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Contenido centrado
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.bingoGame.currentBall > 0 
                                    ? _getBallLabel(widget.bingoGame.currentBall)
                                    : '',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: ballSize * 0.2,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        offset: const Offset(2, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.calledNumbersCount}/${widget.totalBalls}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: ballSize * 0.12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
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