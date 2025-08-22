import 'package:flutter/material.dart';
import '../models/bingo_game.dart';
import '../widgets/numbers_panel.dart';
import '../widgets/control_panel.dart';
import '../widgets/crystal_ball_widget.dart';
import '../widgets/prize_wheel_widget.dart';
import '../widgets/bingo_games_panel.dart';
import 'dart:math' as math;
import '../screens/crm_screen.dart'; // Added import for CRM screen
import '../providers/app_provider.dart'; // Added import for AppProvider
import 'package:provider/provider.dart'; // Added import for Provider

class BingoGameScreen extends StatefulWidget {
  const BingoGameScreen({super.key});

  @override
  State<BingoGameScreen> createState() => _BingoGameScreenState();
}

class _BingoGameScreenState extends State<BingoGameScreen> {
  late BingoGame _bingoGame;
  bool _showCrystalBall = false;
  bool _isShuffling = false;
  bool _isAutoCalling = false;
  bool _showPrizeWheel = false;
  


  @override
  void initState() {
    super.initState();
    _bingoGame = BingoGame();
  }

  void _onGameStateChanged() {
    setState(() {});
    
    // También notificar al AppProvider si es necesario
    if (mounted) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      // Forzar actualización del AppProvider
      appProvider.notifyListeners();
    }
  }

  void _toggleCrystalBall() {
    setState(() {
      _showCrystalBall = !_showCrystalBall;
      if (!_showCrystalBall) {
        _isAutoCalling = false;
      }
    });
  }

  void _togglePrizeWheel() {
    setState(() {
      _showPrizeWheel = !_showPrizeWheel;
    });
  }

  void _toggleShuffling() {
    setState(() {
      _isShuffling = !_isShuffling;
    });
  }

  void _toggleAutoCall() {
    setState(() {
      _isAutoCalling = !_isAutoCalling;
    });
    
    if (_isAutoCalling) {
      _startAutoCalling();
    }
  }

  void _startAutoCalling() {
    if (_isAutoCalling) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final bingoGame = appProvider.bingoGame;
      final remainingBalls = bingoGame.allNumbers
          .where((number) => !bingoGame.calledNumbers.contains(number))
          .toList();
      
      if (remainingBalls.isNotEmpty) {
        final random = math.Random();
        final randomBall = remainingBalls[random.nextInt(remainingBalls.length)];
        
        // Llamar el número con un pequeño delay para efecto dramático
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (_isAutoCalling && mounted) {
            appProvider.callSpecificNumber(randomBall);
            _onGameStateChanged();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🔮 La esfera mágica revela el número $randomBall'),
                backgroundColor: Colors.purple,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Continuar auto-llamando
            _startAutoCalling();
          }
        });
      } else {
        setState(() {
          _isAutoCalling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 ¡Todos los números han sido llamados!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _callSpecificNumber(int number) {
    if (!_bingoGame.calledNumbers.contains(number)) {
      // Usar el AppProvider para llamar el número específico y mantener sincronización
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.callSpecificNumber(number);
      
      print('DEBUG: Número específico $number solicitado desde la pantalla');
      
      // Verificar si el número fue llamado correctamente
      if (_bingoGame.calledNumbers.contains(number)) {
        print('DEBUG: Número $number llamado exitosamente');
      } else {
        print('DEBUG: Error al llamar número $number');
      }
      
      // Forzar actualización del estado local también
      setState(() {});
    }
  }

  String _getFormattedBallNumber(int number) {
    String letter;
    if (number >= 1 && number <= 15) letter = 'B';
    else if (number >= 16 && number <= 30) letter = 'I';
    else if (number >= 31 && number <= 45) letter = 'N';
    else if (number >= 46 && number <= 60) letter = 'G';
    else letter = 'O';
    
    return '$letter$number';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bingo 5x5 - 75 Números'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CrmScreen()),
              );
            },
            tooltip: 'CRM Vendedores',
          ),
          IconButton(
            icon: Icon(_showCrystalBall ? Icons.visibility_off : Icons.visibility),
            onPressed: _toggleCrystalBall,
            tooltip: 'Mostrar/Ocultar Esfera de Cristal',
          ),
          IconButton(
            icon: Icon(Icons.casino),
            onPressed: _togglePrizeWheel,
            tooltip: 'Ruleta de Premios',
          ),
        ],
      ),
      body: _showCrystalBall 
        ? _buildCrystalBallView()
        : _showPrizeWheel
          ? _buildPrizeWheelView()
          : _buildNormalView(),
    );
  }

  Widget _buildNormalView() {
    return Row(
      children: [
        // Panel izquierdo - Todos los números del bingo
        Expanded(
          flex: 1,
          child: Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return NumbersPanel(
                allNumbers: appProvider.bingoGame.allNumbers,
                calledNumbers: appProvider.bingoGame.calledNumbers,
              );
            },
          ),
        ),
        // Panel central - Bola actual y controles
        Expanded(
          flex: 1,
          child: ControlPanel(
            bingoGame: _bingoGame,
            onStateChanged: _onGameStateChanged,
          ),
        ),
        // Panel derecho - Juegos de bingo
        Expanded(
          flex: 1,
          child: BingoGamesPanel(),
        ),
      ],
    );
  }

  Widget _buildCrystalBallView() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final bingoGame = appProvider.bingoGame;
        final calledNumbers = bingoGame.calledNumbers;
        final totalBalls = bingoGame.allNumbers.length;
        final remainingBalls = totalBalls - calledNumbers.length;
        final completedPatterns = bingoGame.getCompletedPatterns(calledNumbers).values.where((completed) => completed).length;
        
        // Obtener las bolas que no han sido llamadas
        final availableBalls = bingoGame.allNumbers
            .where((number) => !calledNumbers.contains(number))
            .toList();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade900,
                Colors.blue.shade700,
                Colors.blue.shade500,
              ],
            ),
          ),
          child: Column(
            children: [
              // Header con controles
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Esfera de Cristal Mágica',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _toggleShuffling,
                          icon: Icon(_isShuffling ? Icons.pause : Icons.shuffle),
                          label: Text(_isShuffling ? 'Pausar' : 'Barajar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isShuffling ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _toggleAutoCall,
                          icon: Icon(_isAutoCalling ? Icons.stop : Icons.auto_fix_high),
                          label: Text(_isAutoCalling ? 'Detener' : 'Auto-Llamar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAutoCalling ? Colors.red : Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _toggleCrystalBall,
                          icon: const Icon(Icons.close),
                          label: const Text('Cerrar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Información del juego
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoCard('Números Llamados', calledNumbers.length.toString(), Colors.green),
                    _buildInfoCard('Bolas Restantes', remainingBalls.toString(), Colors.orange),
                    _buildInfoCard('Patrones Completados', completedPatterns.toString(), Colors.purple),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Esfera de cristal centrada
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CrystalBallWidget(
                        key: ValueKey('crystal_ball_${appProvider.bingoGame.calledNumbers.length}'),
                        balls: availableBalls,
                        isShuffling: _isShuffling,
                        currentBall: bingoGame.currentBallNumber > 0 ? bingoGame.currentBallNumber : null,
                        onBallSelected: (int ballNumber) {
                          // Llamar el número seleccionado en el juego
                          if (!calledNumbers.contains(ballNumber)) {
                            _callSpecificNumber(ballNumber);
                            _onGameStateChanged();
                            
                            // Mostrar mensaje de confirmación
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('¡Número $ballNumber llamado desde la esfera mágica!'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('El número $ballNumber ya fue llamado'),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      // Información de la bola actual
                      if (bingoGame.currentBallNumber > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Bola actual: ${_getFormattedBallNumber(bingoGame.currentBallNumber)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        _isShuffling 
                          ? '🔮 Las bolas se están barajando...' 
                          : _isAutoCalling
                            ? '🔮 La esfera mágica está revelando números...'
                            : '🔮 Las bolas flotan mágicamente',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isAutoCalling 
                          ? 'La esfera mágica revelará números automáticamente'
                          : 'Toca una bola para seleccionarla o usa Auto-Llamar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrizeWheelView() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Obtener el estado actual del juego desde AppProvider
        final currentBingoGame = appProvider.bingoGame;
        
        // Crear lista de números de cartillas basada en el estado real
        final cartillaNumbers = List.generate(currentBingoGame.cartillas.length, (index) => index + 1);
        
        return PrizeWheelWidget(
          cartillaNumbers: cartillaNumbers,
          onPrizeSelected: (int selectedCartilla) {
            // Mostrar mensaje de la cartilla ganadora
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎯 ¡Cartilla $selectedCartilla es la ganadora!'),
                backgroundColor: Colors.indigo,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Aquí podrías agregar lógica adicional para la cartilla ganadora
            // Por ejemplo, destacarla, guardarla, etc.
          },
          onSync: () {
            // Sincronizar las cartillas con el estado actual del juego
            setState(() {
              // Obtener el estado actual del AppProvider
              final currentAppProvider = Provider.of<AppProvider>(context, listen: false);
              final currentBingoGame = currentAppProvider.bingoGame;
              
              // Actualizar el estado local con el estado real del juego
              _bingoGame = currentBingoGame;
              
              // Forzar actualización del AppProvider
              currentAppProvider.notifyListeners();
            });
            
            // Mostrar mensaje de confirmación
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Sincronización completada. Cartillas actuales: ${currentBingoGame.cartillas.length}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          onClose: () {
            setState(() {
              _showPrizeWheel = false;
            });
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
} 