import 'package:flutter/material.dart';
import '../widgets/blackjack_card_widget.dart';
import '../widgets/blackjack_avatar_widget.dart';

class BlackjackScreen extends StatefulWidget {
  const BlackjackScreen({super.key});

  @override
  State<BlackjackScreen> createState() => _BlackjackScreenState();
}

class _BlackjackScreenState extends State<BlackjackScreen> {
  // Estado del juego
  List<Map<String, String>> dealerCards = [];
  List<Map<String, String>> player1Cards = [];
  List<Map<String, String>> player2Cards = [];
  int dealerScore = 0;
  int player1Score = 0;
  int player2Score = 0;
  int currentPlayer = 1; // 1 o 2
  bool gameStarted = false;
  bool gameEnded = false;
  
  // Sistema de apuestas
  int player1Bet = 0;
  int player1Chips = 1000;
  int player2Chips = 1000;
  
  // Baraja sin repetición
  List<Map<String, String>> deck = [];
  int deckIndex = 0;
  
  // Estado del juego automático
  bool isDealerTurn = false;
  bool isPlayer2Turn = false;
  bool isPlayer1Turn = false; // Turno del Jugador 1
  String gameStatus = 'Haz tu apuesta';
  bool showDealerCards = false; // Para mostrar cartas del crupier boca abajo
  bool player1Finished = false; // Si el Jugador 1 terminó su turno

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesa de Blackjack'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade700,
                Colors.green.shade900,
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade100,
              Colors.green.shade200,
            ],
          ),
        ),
        child: _buildBlackjackTable(),
      ),
    );
  }

  Widget _buildBlackjackTable() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.green.shade100,
            Colors.green.shade300,
            Colors.green.shade500,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Mesa isométrica
          _buildIsometricTable(),
          // Controles flotantes
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildFloatingControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildIsometricTable() {
    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0008) // Perspectiva más sutil
          ..rotateX(-0.15) // Mayor inclinación
          ..rotateY(0.1), // Más rotación para efecto isométrico
        child: Container(
          width: 700,
          height: 500,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade600,
                Colors.green.shade800,
                Colors.green.shade900,
                Colors.green.shade700,
              ],
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.green.shade900.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(-5, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Patrón de la mesa mejorado
              _buildTablePattern(),
              // Borde decorativo
              _buildTableBorder(),
              // Posiciones de los jugadores
              _buildPlayerPositions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTablePattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: TablePatternPainter(),
      ),
    );
  }

  Widget _buildTableBorder() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.green.shade400,
            width: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerPositions() {
    return Stack(
      children: [
        // Crupier (arriba)
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DealerAvatarWidget(
                  score: dealerScore,
                  isActive: !gameStarted,
                ),
                const SizedBox(height: 15),
                // Cartas del crupier
                CardHandWidget(
                  cards: dealerCards,
                  isFaceUp: showDealerCards || gameEnded,
                  cardWidth: 50,
                  cardHeight: 70,
                  cardSpacing: 10,
                ),
              ],
            ),
          ),
        ),
        // Jugador 1 (izquierda) - Solo apuesta
        Positioned(
          left: 40,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlackjackAvatarWidget(
                name: 'JUGADOR 1',
                score: player1Score,
                isActive: isPlayer1Turn, // Activo cuando es su turno
                size: 70,
              ),
              const SizedBox(height: 10),
              CardHandWidget(
                cards: player1Cards,
                isFaceUp: true,
                cardWidth: 45,
                cardHeight: 65,
                cardSpacing: 8,
              ),
              const SizedBox(height: 8),
              // Mostrar fichas y apuesta
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Fichas: $player1Chips',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (player1Bet > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Apuesta: $player1Bet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Jugador 2 (derecha) - Bot
        Positioned(
          right: 40,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlackjackAvatarWidget(
                name: 'BOT',
                score: player2Score,
                isActive: isPlayer2Turn,
                size: 70,
              ),
              const SizedBox(height: 10),
              CardHandWidget(
                cards: player2Cards,
                isFaceUp: true,
                cardWidth: 45,
                cardHeight: 65,
                cardSpacing: 8,
              ),
              const SizedBox(height: 8),
              // Indicador de bot
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPlayer2Turn ? Colors.orange.withOpacity(0.8) : Colors.purple.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPlayer2Turn ? 'PENSANDO...' : 'AUTOMÁTICO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildFloatingControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Estado del juego
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              gameStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          
          // Controles de apuestas (antes del juego)
          if (!gameStarted && !gameEnded) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _placeBet(50),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('50'),
                ),
                ElevatedButton(
                  onPressed: () => _placeBet(100),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('100'),
                ),
                ElevatedButton(
                  onPressed: () => _placeBet(200),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('200'),
                ),
                ElevatedButton(
                  onPressed: () => _placeBet(500),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('500'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: player1Bet > 0 ? _startGame : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Comenzar Juego'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
          
          // Controles del Jugador 1 (durante el juego)
          if (isPlayer1Turn && !player1Finished) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _player1Hit,
                  icon: const Icon(Icons.add),
                  label: const Text('Pedir Carta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _player1Stand,
                  icon: const Icon(Icons.stop),
                  label: const Text('Plantarse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
          
          // Controles de nueva partida
          if (gameEnded || (!gameStarted && player1Bet == 0)) ...[
            ElevatedButton.icon(
              onPressed: _newGame,
              icon: const Icon(Icons.refresh),
              label: const Text('Nueva Partida'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Métodos del juego
  void _newGame() {
    setState(() {
      dealerCards.clear();
      player1Cards.clear();
      player2Cards.clear();
      dealerScore = 0;
      player1Score = 0;
      player2Score = 0;
      currentPlayer = 1;
      gameStarted = false;
      gameEnded = false;
      isDealerTurn = false;
      isPlayer2Turn = false;
      isPlayer1Turn = false;
      player1Finished = false;
      gameStatus = 'Haz tu apuesta';
      player1Bet = 0;
      showDealerCards = false; // Resetear cartas del crupier
    });
    
    // Crear nueva baraja
    _createDeck();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Nueva partida! Haz tu apuesta.'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _createDeck() {
    deck.clear();
    deckIndex = 0;
    
    final suits = ['♠', '♥', '♦', '♣'];
    final values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
    
    // Crear 6 barajas (312 cartas)
    for (int deckNum = 0; deckNum < 6; deckNum++) {
      for (String suit in suits) {
        for (String value in values) {
          deck.add({'suit': suit, 'value': value});
        }
      }
    }
    
    // Mezclar la baraja
    deck.shuffle();
  }
  
  Map<String, String> _dealCard() {
    if (deckIndex >= deck.length) {
      _createDeck(); // Recrear baraja si se agotan las cartas
    }
    
    final card = deck[deckIndex];
    deckIndex++;
    return card;
  }

  void _dealInitialCards() {
    if (player1Bet == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes hacer una apuesta primero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      gameStarted = true;
      gameStatus = 'Repartiendo cartas...';
    });
    
    // Repartir cartas una por una como en casino real
    _dealCardsSequentially();
  }
  
  void _dealCardsSequentially() async {
    // Primera ronda: una carta a cada uno
    await _dealCardToPlayer(1); // Jugador 1
    await Future.delayed(const Duration(milliseconds: 800));
    
    await _dealCardToPlayer(2); // Jugador 2 (Bot)
    await Future.delayed(const Duration(milliseconds: 800));
    
    await _dealCardToDealer(); // Crupier
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Segunda ronda: otra carta a cada uno
    await _dealCardToPlayer(1); // Jugador 1
    await Future.delayed(const Duration(milliseconds: 800));
    
    await _dealCardToPlayer(2); // Jugador 2 (Bot)
    await Future.delayed(const Duration(milliseconds: 800));
    
    await _dealCardToDealer(); // Crupier (boca abajo)
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Calcular puntuaciones
    player1Score = _calculateScore(player1Cards);
    player2Score = _calculateScore(player2Cards);
    dealerScore = _calculateScore(dealerCards);
    
    setState(() {
      gameStatus = 'Cartas repartidas. Verificando...';
    });
    
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Verificar Blackjack natural
    _checkNaturalBlackjack();
    
    // Iniciar turno del Jugador 1
    if (!gameEnded) {
      _startPlayer1Turn();
    }
  }
  
  Future<void> _dealCardToPlayer(int player) async {
    final card = _dealCard();
    setState(() {
      if (player == 1) {
        player1Cards.add(card);
        player1Score = _calculateScore(player1Cards);
      } else {
        player2Cards.add(card);
        player2Score = _calculateScore(player2Cards);
      }
    });
  }
  
  Future<void> _dealCardToDealer() async {
    final card = _dealCard();
    setState(() {
      dealerCards.add(card);
      dealerScore = _calculateScore(dealerCards);
    });
  }
  
  void _checkNaturalBlackjack() {
    bool player1Blackjack = player1Score == 21;
    bool player2Blackjack = player2Score == 21;
    bool dealerBlackjack = dealerScore == 21;
    
    if (dealerBlackjack) {
      setState(() {
        gameEnded = true;
        if (player1Blackjack) {
          gameStatus = 'Empate - Blackjack natural';
          player1Chips += player1Bet; // Devolver apuesta
        } else {
          gameStatus = 'Crupier gana - Blackjack natural';
        }
      });
    } else if (player1Blackjack) {
      setState(() {
        gameEnded = true;
        gameStatus = '¡Blackjack! Ganas ${(player1Bet * 2.5).round()} fichas';
        player1Chips += (player1Bet * 2.5).round();
      });
    } else if (player2Blackjack) {
      setState(() {
        gameEnded = true;
        gameStatus = 'Jugador 2 - Blackjack natural';
      });
    }
  }

  void _startPlayer1Turn() {
    setState(() {
      isPlayer1Turn = true;
      gameStatus = 'Tu turno - ¿Pedir carta o plantarte?';
    });
  }
  
  void _startPlayer2Turn() {
    setState(() {
      isPlayer2Turn = true;
      gameStatus = 'Turno del Jugador 2 (Bot)';
    });
    
    // El bot juega automáticamente
    _player2BotPlay();
  }
  
  void _player2BotPlay() async {
    setState(() {
      gameStatus = 'Bot pensando...';
    });
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Estrategia básica del bot
    while (player2Score < 17 && player2Score < 21) {
      setState(() {
        gameStatus = 'Bot pide carta...';
      });
      
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final card = _dealCard();
      setState(() {
        player2Cards.add(card);
        player2Score = _calculateScore(player2Cards);
      });
      
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    
    // El bot se planta o se pasa
    setState(() {
      isPlayer2Turn = false;
      isDealerTurn = true;
      gameStatus = 'Bot se planta. Turno del Crupier...';
    });
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Iniciar turno del crupier
    _dealerPlay();
  }
  
  void _dealerPlay() async {
    setState(() {
      gameStatus = 'Crupier revela cartas...';
    });
    
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // Mostrar cartas del crupier
    setState(() {
      showDealerCards = true;
      gameStatus = 'Crupier muestra sus cartas...';
    });
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // El crupier debe mostrar su carta oculta y jugar
    while (dealerScore < 17) {
      setState(() {
        gameStatus = 'Crupier pide carta...';
      });
      
      await Future.delayed(const Duration(milliseconds: 1500));
      
      final card = _dealCard();
      setState(() {
        dealerCards.add(card);
        dealerScore = _calculateScore(dealerCards);
      });
      
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    
    setState(() {
      gameStatus = 'Crupier se planta. Calculando resultados...';
    });
    
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // Determinar ganadores
    _determineWinners();
  }
  
  void _determineWinners() {
    setState(() {
      gameEnded = true;
      
      // Verificar si alguien se pasó
      bool player1Bust = player1Score > 21;
      bool player2Bust = player2Score > 21;
      bool dealerBust = dealerScore > 21;
      
      if (dealerBust) {
        // Crupier se pasó, todos los que no se pasaron ganan
        if (!player1Bust) {
          gameStatus = '¡Ganas! Crupier se pasó. +${player1Bet * 2} fichas';
          player1Chips += player1Bet * 2;
        } else {
          gameStatus = 'Crupier se pasó, pero tú también';
        }
      } else {
        // Comparar puntuaciones
        if (player1Bust) {
          gameStatus = 'Te pasaste. Pierdes ${player1Bet} fichas';
        } else if (player1Score > dealerScore) {
          gameStatus = '¡Ganas! +${player1Bet * 2} fichas';
          player1Chips += player1Bet * 2;
        } else if (player1Score == dealerScore) {
          gameStatus = 'Empate. Recuperas ${player1Bet} fichas';
          player1Chips += player1Bet;
        } else {
          gameStatus = 'Crupier gana. Pierdes ${player1Bet} fichas';
        }
      }
    });
  }

  // Métodos de apuestas
  void _placeBet(int amount) {
    if (player1Chips >= amount && !gameStarted) {
      setState(() {
        player1Bet = amount;
        player1Chips -= amount;
        gameStatus = 'Apuesta: $amount fichas. Presiona "Comenzar"';
      });
    }
  }
  
  void _startGame() {
    if (player1Bet > 0) {
      _dealInitialCards();
    }
  }
  
  // Métodos de control del Jugador 1
  void _player1Hit() {
    if (!isPlayer1Turn || player1Finished) return;
    
    final card = _dealCard();
    setState(() {
      player1Cards.add(card);
      player1Score = _calculateScore(player1Cards);
    });
    
    // Verificar si se pasó
    if (player1Score > 21) {
      setState(() {
        player1Finished = true;
        isPlayer1Turn = false;
        gameStatus = 'Te pasaste! Turno del Bot...';
      });
      
      // Continuar con el Bot
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _startPlayer2Turn();
        }
      });
    }
  }
  
  void _player1Stand() {
    if (!isPlayer1Turn || player1Finished) return;
    
    setState(() {
      player1Finished = true;
      isPlayer1Turn = false;
      gameStatus = 'Te plantas. Turno del Bot...';
    });
    
    // Continuar con el Bot
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _startPlayer2Turn();
      }
    });
  }

  int _calculateScore(List<Map<String, String>> cards) {
    int score = 0;
    int aces = 0;
    
    for (var card in cards) {
      String value = card['value']!;
      if (value == 'A') {
        aces++;
        score += 11;
      } else if (['J', 'Q', 'K'].contains(value)) {
        score += 10;
      } else {
        score += int.parse(value);
      }
    }
    
    // Ajustar ases
    while (score > 21 && aces > 0) {
      score -= 10;
      aces--;
    }
    
    return score;
  }
}

// Painter para el patrón de la mesa
class TablePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Dibujar líneas decorativas más elegantes
    for (int i = 0; i < 6; i++) {
      double y = size.height * 0.15 + (i * size.height * 0.12);
      canvas.drawLine(
        Offset(20, y),
        Offset(size.width - 20, y),
        paint..strokeWidth = 2,
      );
    }

    // Dibujar círculos decorativos más grandes
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        double x = size.width * 0.08 + (j * size.width * 0.21);
        double y = size.height * 0.2 + (i * size.height * 0.15);
        
        // Círculo exterior
        canvas.drawCircle(
          Offset(x, y),
          20,
          paint..style = PaintingStyle.stroke,
        );
        // Círculo interior
        canvas.drawCircle(
          Offset(x, y),
          12,
          paint..style = PaintingStyle.fill,
        );
      }
    }

    // Dibujar líneas diagonales decorativas
    final diagonalPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      double startX = size.width * 0.1 + (i * size.width * 0.1);
      double startY = size.height * 0.1;
      double endX = size.width * 0.9 - (i * size.width * 0.1);
      double endY = size.height * 0.9;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        diagonalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
