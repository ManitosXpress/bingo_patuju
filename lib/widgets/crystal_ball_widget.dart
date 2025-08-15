import 'package:flutter/material.dart';
import 'dart:math' as math;

class CrystalBallWidget extends StatefulWidget {
  final List<int> balls;
  final bool isShuffling;
  final Function(int)? onBallSelected;
  final int? currentBall; // Agregar la bola actual
  
  const CrystalBallWidget({
    super.key,
    required this.balls,
    this.isShuffling = false,
    this.onBallSelected,
    this.currentBall,
  });

  @override
  State<CrystalBallWidget> createState() => _CrystalBallWidgetState();
}

class _CrystalBallWidgetState extends State<CrystalBallWidget>
    with TickerProviderStateMixin {
  late AnimationController _shuffleController;
  late AnimationController _floatController;
  late Animation<double> _shuffleAnimation;
  late Animation<double> _floatAnimation;
  
  final List<BallData> _ballData = [];
  final math.Random _random = math.Random();
  int? _selectedBallIndex;

  @override
  void initState() {
    super.initState();
    
    _shuffleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _shuffleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shuffleController,
      curve: Curves.easeInOut,
    ));
    
    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.linear,
    ));
    
    _initializeBalls();
    
    if (widget.isShuffling) {
      _startShuffling();
    }
    
    _floatController.repeat();
  }

  String _getColumnLetter(int number) {
    if (number >= 1 && number <= 15) return 'B';
    if (number >= 16 && number <= 30) return 'I';
    if (number >= 31 && number <= 45) return 'N';
    if (number >= 46 && number <= 60) return 'G';
    if (number >= 61 && number <= 75) return 'O';
    return '';
  }

  String _formatBallNumber(int number) {
    String letter = _getColumnLetter(number);
    return '$letter$number';
  }

  void _initializeBalls() {
    _ballData.clear();
    for (int i = 0; i < widget.balls.length; i++) {
      _ballData.add(BallData(
        number: widget.balls[i],
        initialX: _random.nextDouble() * 0.8 - 0.4,
        initialY: _random.nextDouble() * 0.8 - 0.4,
        initialZ: _random.nextDouble() * 0.6 - 0.3,
        velocityX: (_random.nextDouble() - 0.5) * 0.02,
        velocityY: (_random.nextDouble() - 0.5) * 0.02,
        velocityZ: (_random.nextDouble() - 0.5) * 0.01,
        color: _getBallColor(widget.balls[i]),
        index: i,
      ));
    }
  }

  Color _getBallColor(int number) {
    if (number <= 15) return Colors.red;
    if (number <= 30) return Colors.blue;
    if (number <= 45) return Colors.green;
    if (number <= 60) return Colors.yellow;
    return Colors.purple;
  }

  void _startShuffling() {
    _shuffleController.repeat();
  }

  void _stopShuffling() {
    _shuffleController.stop();
  }

  @override
  void didUpdateWidget(CrystalBallWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isShuffling != oldWidget.isShuffling) {
      if (widget.isShuffling) {
        _startShuffling();
      } else {
        _stopShuffling();
      }
    }
    
    if (widget.balls != oldWidget.balls) {
      _initializeBalls();
    }
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      child: AnimatedBuilder(
        animation: Listenable.merge([_shuffleAnimation, _floatAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: CrystalBallPainter(
              ballData: _ballData,
              shuffleProgress: _shuffleAnimation.value,
              floatProgress: _floatAnimation.value,
              isShuffling: widget.isShuffling,
              selectedBallIndex: _selectedBallIndex,
              formatBallNumber: _formatBallNumber,
              currentBall: widget.currentBall,
            ),
            child: GestureDetector(
              onTapDown: (details) {
                _handleTap(details.localPosition);
              },
            ),
          );
        },
      ),
    );
  }

  void _handleTap(Offset position) {
    if (widget.onBallSelected != null) {
      // Encontrar la bola más cercana al tap
      double minDistance = double.infinity;
      BallData? closestBall;
      
      for (var ball in _ballData) {
        final ballPosition = _getBallScreenPosition(ball);
        final distance = (position - ballPosition).distance;
        
        if (distance < minDistance && distance < 25) {
          minDistance = distance;
          closestBall = ball;
        }
      }
      
      if (closestBall != null) {
        setState(() {
          _selectedBallIndex = closestBall!.index;
        });
        
        // Llamar al callback con el número de la bola
        widget.onBallSelected!(closestBall!.number);
        
        // Resetear la selección después de un momento
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _selectedBallIndex = null;
            });
          }
        });
      }
    }
  }

  Offset _getBallScreenPosition(BallData ball) {
    final center = Offset(125, 125);
    final x = center.dx + ball.currentX * 100;
    final y = center.dy + ball.currentY * 100;
    return Offset(x, y);
  }
}

class BallData {
  final int number;
  final double initialX;
  final double initialY;
  final double initialZ;
  final double velocityX;
  final double velocityY;
  final double velocityZ;
  final Color color;
  final int index;
  
  double get currentX => initialX + velocityX;
  double get currentY => initialY + velocityY;
  double get currentZ => initialZ + velocityZ;
  
  BallData({
    required this.number,
    required this.initialX,
    required this.initialY,
    required this.initialZ,
    required this.velocityX,
    required this.velocityY,
    required this.velocityZ,
    required this.color,
    required this.index,
  });
}

class CrystalBallPainter extends CustomPainter {
  final List<BallData> ballData;
  final double shuffleProgress;
  final double floatProgress;
  final bool isShuffling;
  final int? selectedBallIndex;
  final String Function(int) formatBallNumber;
  final int? currentBall; // Agregar la bola actual

  CrystalBallPainter({
    required this.ballData,
    required this.shuffleProgress,
    required this.floatProgress,
    required this.isShuffling,
    this.selectedBallIndex,
    required this.formatBallNumber,
    this.currentBall,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    // Dibujar el contorno de la esfera de cristal
    _drawCrystalBall(canvas, center, radius);
    
    // Dibujar las bolas
    _drawBalls(canvas, center, radius);
    
    // Dibujar efectos de luz
    _drawLightEffects(canvas, center, radius);
  }

  void _drawCrystalBall(Canvas canvas, Offset center, double radius) {
    // Contorno exterior
    final outerPaint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(center, radius, outerPaint);
    
    // Contorno interior
    final innerPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawCircle(center, radius - 3, innerPaint);
    
    // Gradiente de fondo
    final gradient = RadialGradient(
      colors: [
        Colors.blue.withOpacity(0.15),
        Colors.blue.withOpacity(0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.7, 1.0],
    );
    
    final backgroundPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, backgroundPaint);
  }

  void _drawBalls(Canvas canvas, Offset center, double radius) {
    for (var ball in ballData) {
      final ballPosition = _calculateBallPosition(ball, center, radius);
      final ballRadius = _calculateBallRadius(ball);
      final isSelected = ball.index == selectedBallIndex;
      final isCurrentBall = ball.number == currentBall;
      
      // Efecto de selección
      if (isSelected) {
        final selectionPaint = Paint()
          ..color = Colors.yellow.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        
        canvas.drawCircle(ballPosition, ballRadius + 5, selectionPaint);
        
        // Efecto de pulso
        final pulsePaint = Paint()
          ..color = Colors.yellow.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        
        canvas.drawCircle(ballPosition, ballRadius + 8, pulsePaint);
      }
      
      // Efecto especial para la bola actual
      if (isCurrentBall) {
        // Efecto de resplandor dorado
        final glowPaint = Paint()
          ..color = Colors.orange.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;
        
        canvas.drawCircle(ballPosition, ballRadius + 8, glowPaint);
        
        // Efecto de pulso dorado
        final pulsePaint = Paint()
          ..color = Colors.orange.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        
        canvas.drawCircle(ballPosition, ballRadius + 12, pulsePaint);
      }
      
      // Sombra de la bola
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(ballPosition.dx + 3, ballPosition.dy + 3),
        ballRadius,
        shadowPaint,
      );
      
      // Bola principal
      final ballPaint = Paint()
        ..color = isCurrentBall 
          ? ball.color.withOpacity(0.9) // Más brillante para la bola actual
          : isSelected 
            ? ball.color.withOpacity(0.8) 
            : ball.color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(ballPosition, ballRadius, ballPaint);
      
      // Brillo de la bola
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(ballPosition.dx - ballRadius * 0.3, ballPosition.dy - ballRadius * 0.3),
        ballRadius * 0.4,
        highlightPaint,
      );
      
      // Número en la bola
      final textPainter = TextPainter(
        text: TextSpan(
          text: formatBallNumber(ball.number),
          style: TextStyle(
            color: Colors.white,
            fontSize: ballRadius * 0.6, // Reducido para que quepa mejor
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          ballPosition.dx - textPainter.width / 2,
          ballPosition.dy - textPainter.height / 2,
        ),
      );
    }
  }

  Offset _calculateBallPosition(BallData ball, Offset center, double radius) {
    double x, y;
    
    if (isShuffling) {
      // Movimiento de barajado más caótico
      final shuffleX = math.sin(shuffleProgress * 2 * math.pi + ball.number) * 0.6;
      final shuffleY = math.cos(shuffleProgress * 2 * math.pi + ball.number) * 0.6;
      
      x = center.dx + (ball.initialX + shuffleX) * radius * 0.8;
      y = center.dy + (ball.initialY + shuffleY) * radius * 0.8;
    } else {
      // Movimiento flotante suave
      final floatX = math.sin(floatProgress + ball.number * 0.5) * 0.15;
      final floatY = math.cos(floatProgress + ball.number * 0.3) * 0.15;
      
      x = center.dx + (ball.initialX + floatX) * radius * 0.8;
      y = center.dy + (ball.initialY + floatY) * radius * 0.8;
    }
    
    return Offset(x, y);
  }

  double _calculateBallRadius(BallData ball) {
    final baseRadius = 12.0; // Aumentado de 10.0 a 12.0
    if (isShuffling) {
      // Las bolas se hacen más grandes durante el barajado
      return baseRadius + math.sin(shuffleProgress * 2 * math.pi + ball.number) * 3;
    } else {
      // Tamaño normal con ligera variación
      return baseRadius + math.sin(floatProgress + ball.number) * 1.5;
    }
  }

  void _drawLightEffects(Canvas canvas, Offset center, double radius) {
    // Efecto de luz superior
    final lightGradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.4),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    );
    
    final lightPaint = Paint()
      ..shader = lightGradient.createShader(
        Rect.fromCircle(
          center: Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
          radius: radius * 0.5,
        ),
      );
    
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.5,
      lightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 