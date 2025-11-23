import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bingo_game.dart';
import '../widgets/numbers_panel.dart';
import '../widgets/control_panel.dart';
import '../widgets/crystal_ball_widget.dart';
import '../widgets/prize_wheel_widget.dart';
import '../widgets/bingo_games_panel.dart';
import 'dart:math' as math;
import '../screens/crm_screen.dart'; // Added import for CRM screen
import '../screens/blackjack_screen.dart'; // Added import for Blackjack screen
import '../providers/app_provider.dart'; // Added import for AppProvider
import 'package:provider/provider.dart'; // Added import for Provider
import '../widgets/cartillas_dialog.dart';
import '../models/firebase_cartilla.dart';
import '../widgets/bingo_games_panel.dart';

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

  void _showCartillasDialog() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final bingoGame = appProvider.bingoGame;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CartillasDialog(bingoGame: bingoGame);
      },
    );
  }

  void _showResetConfirmationDialog() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final bingoGame = appProvider.bingoGame;
    final calledCount = bingoGame.calledNumbers.length;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Confirmar Reseteo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que quieres resetear el juego?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (calledCount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Se perderá el progreso actual:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('• $calledCount números llamados'),
                      Text('• Todas las cartillas marcadas'),
                      Text('• Estado actual del juego'),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                appProvider.resetGame();
                _onGameStateChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Juego reseteado exitosamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sí, Resetear'),
            ),
          ],
        );
      },
    );
  }

  void _showBingoVerificationDialog() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    print('DEBUG: === INICIANDO VERIFICACIÓN DE BINGO ===');
    
    // Obtener los patrones de la ronda actual desde el panel de juegos
    List<String> currentRoundPatterns = _getCurrentRoundPatternsFromContext(context);
    
    print('DEBUG: - Patrones de ronda obtenidos: $currentRoundPatterns');
    print('DEBUG: - Cantidad de patrones: ${currentRoundPatterns.length}');
    
    if (currentRoundPatterns.isNotEmpty) {
      print('DEBUG: ✅ Hay patrones de ronda, verificando bingo específico...');
      
      // Verificar bingo SOLO para los patrones de la ronda actual
      final bingoCheck = appProvider.checkBingoForSpecificRoundPatterns(currentRoundPatterns);
      
      print('DEBUG: - Resultado de verificación: ${bingoCheck['hasBingo']}');
      print('DEBUG: - Mensaje: ${bingoCheck['message']}');
      print('DEBUG: - Patrones completados: ${bingoCheck['completedPatterns']}');
      
      if (bingoCheck['hasBingo'] == true) {
        print('DEBUG: 🎉 ¡BINGO detectado para la ronda actual!');
        // Mostrar directamente el diálogo de BINGO con buscador de cartilla
        showDialog(
          context: context,
          builder: (context) => _BingoVerificationDialog(
            bingoCheck: bingoCheck,
            appProvider: appProvider,
            currentRoundPatterns: currentRoundPatterns,
          ),
        );
      } else {
        print('DEBUG: ❌ No hay bingo para la ronda actual');
        // Mostrar mensaje de que no hay bingo para la ronda actual
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 28),
                const SizedBox(width: 8),
                const Text('Verificación de BINGO - Ronda Actual'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No hay BINGO para los patrones de la ronda actual:',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...currentRoundPatterns.map((pattern) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                      Text(pattern, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Continúa llamando números para completar los patrones de esta ronda',
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } else {
      print('DEBUG: ❌ No hay patrones de ronda específica, usando verificación general');
      // Si no hay patrones de ronda específica, usar verificación general
      final bingoCheck = appProvider.checkBingoInRealTime();
      
      print('DEBUG: - Resultado de verificación general: ${bingoCheck['hasBingo']}');
      print('DEBUG: - Mensaje: ${bingoCheck['message']}');
      
      if (bingoCheck['hasBingo'] == true) {
        showDialog(
          context: context,
          builder: (context) => _BingoVerificationDialog(
            bingoCheck: bingoCheck,
            appProvider: appProvider,
            currentRoundPatterns: [],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 28),
                const SizedBox(width: 8),
                const Text('Verificación de BINGO'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bingoCheck['message'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Continúa llamando números para completar patrones de BINGO',
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    }
    
    print('DEBUG: === FINALIZADA VERIFICACIÓN DE BINGO ===');
  }

  // Método para obtener los patrones de la ronda actual desde el contexto
  List<String> _getCurrentRoundPatternsFromContext(BuildContext context) {
    // Importar la clase estática del BingoGamesPanel
    try {
      // Usar la variable estática del BingoGamesPanel
      final patterns = BingoGamesPanelState.getCurrentRoundPatterns();
      final roundIndex = BingoGamesPanelState.getCurrentRoundIndex();
      final gameId = BingoGamesPanelState.getSelectedGameId();
      
      print('DEBUG: === OBTENIENDO PATRONES DE RONDA ACTUAL ===');
      print('DEBUG: - Patrones obtenidos: $patterns');
      print('DEBUG: - Índice de ronda: $roundIndex');
      print('DEBUG: - ID del juego: $gameId');
      print('DEBUG: ===========================================');
      
      return patterns;
    } catch (e) {
      print('DEBUG: Error al obtener patrones de ronda actual: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.space): const _CallNumberIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyV): const _VerifyBingoIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyR): const _ResetGameIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyC): const _ViewCartillasIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _CloseDialogIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CallNumberIntent: CallbackAction<_CallNumberIntent>(
            onInvoke: (_) {
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              appProvider.callNumber();
              _onGameStateChanged();
              return null;
            },
          ),
          _VerifyBingoIntent: CallbackAction<_VerifyBingoIntent>(
            onInvoke: (_) {
              _showBingoVerificationDialog();
              return null;
            },
          ),
          _ResetGameIntent: CallbackAction<_ResetGameIntent>(
            onInvoke: (_) {
              _showResetConfirmationDialog();
              return null;
            },
          ),
          _ViewCartillasIntent: CallbackAction<_ViewCartillasIntent>(
            onInvoke: (_) {
              _showCartillasDialog();
              return null;
            },
          ),
          _CloseDialogIntent: CallbackAction<_CloseDialogIntent>(
            onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Bingo 5x5 - 75 Números'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade800,
                    ],
                  ),
                ),
              ),
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
                IconButton(
                  icon: const Icon(Icons.spa),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BlackjackScreen()),
                    );
                  },
                  tooltip: 'Mesa de Blackjack',
                ),
                // Indicador de atajos de teclado
                PopupMenuButton<String>(
                  icon: const Icon(Icons.keyboard),
                  tooltip: 'Atajos de Teclado',
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'help',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Atajos de Teclado:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Espacio: Llamar número'),
                          Text('V: Verificar bingo'),
                          Text('R: Resetear juego'),
                          Text('C: Ver cartillas'),
                          Text('Esc: Cerrar diálogos'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade50,
                    Colors.grey.shade100,
                  ],
                ),
              ),
              child: _showCrystalBall 
                ? _buildCrystalBallView()
                : _showPrizeWheel
                  ? _buildPrizeWheelView()
                  : _buildNormalView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalView() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          // Panel izquierdo - Todos los números del bingo
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return NumbersPanel(
                    allNumbers: appProvider.bingoGame.allNumbers,
                    calledNumbers: appProvider.bingoGame.calledNumbers,
                  );
                },
              ),
            ),
          ),
          // Panel central - Bola actual y controles
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ControlPanel(
                bingoGame: _bingoGame,
                onStateChanged: _onGameStateChanged,
              ),
            ),
          ),
          // Panel derecho - Juegos de bingo
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: BingoGamesPanel(),
            ),
          ),
        ],
      ),
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

// Intents para los atajos de teclado
class _CallNumberIntent extends Intent {
  const _CallNumberIntent();
}

class _VerifyBingoIntent extends Intent {
  const _VerifyBingoIntent();
}

class _ResetGameIntent extends Intent {
  const _ResetGameIntent();
}

class _ViewCartillasIntent extends Intent {
  const _ViewCartillasIntent();
}

class _CloseDialogIntent extends Intent {
  const _CloseDialogIntent();
}

// Diálogo personalizado para verificación de BINGO con buscador
class _BingoVerificationDialog extends StatefulWidget {
  final Map<String, dynamic> bingoCheck;
  final AppProvider appProvider;
  final List<String> currentRoundPatterns;
  
  const _BingoVerificationDialog({
    required this.bingoCheck,
    required this.appProvider,
    required this.currentRoundPatterns,
  });

  @override
  State<_BingoVerificationDialog> createState() => _BingoVerificationDialogState();
}

class _BingoVerificationDialogState extends State<_BingoVerificationDialog> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _searchResult;
  bool _isSearching = false;

  void _searchCartilla() {
    final cardNumber = int.tryParse(_searchController.text);
    if (cardNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Ingresa un número válido'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Obtener los patrones de la ronda actual desde el widget
    final currentRoundPatterns = widget.currentRoundPatterns;
    
    // Buscar la cartilla con patrones específicos de la ronda si están disponibles
    final result = currentRoundPatterns.isNotEmpty
        ? widget.appProvider.checkSpecificCartilla(cardNumber, roundPatterns: currentRoundPatterns)
        : widget.appProvider.checkSpecificCartilla(cardNumber);
    
    setState(() {
      _searchResult = result;
      _isSearching = false;
    });

    // No mostrar mensajes de SnackBar para mantener la interfaz limpia
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.celebration, color: Colors.amber, size: 28),
          const SizedBox(width: 8),
          const Text('¡BINGO VERIFICADO!'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bingoCheck['message'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Buscador por número de cartilla
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buscar Cartilla por Número:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Ej: 1, 2, 3...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isSearching ? null : _searchCartilla,
                        icon: _isSearching 
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.search, size: 18),
                        label: Text(_isSearching ? 'Buscando...' : 'Buscar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa el número de cartilla para verificar si es ganadora',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            // Resultado de la búsqueda
            if (_searchResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _searchResult!['isWinning'] == true 
                    ? Colors.green.shade50 
                    : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _searchResult!['isWinning'] == true 
                      ? Colors.green.shade200 
                      : Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                                         if (_searchResult!['found'] == true) ...[
                       const SizedBox(height: 8),
                       if ((_searchResult!['cartilla'] as FirebaseCartilla).assignedTo != null)
                         Text(
                           'Vendedor: ${widget.appProvider.getVendorName((_searchResult!['cartilla'] as FirebaseCartilla).assignedTo)}',
                           style: TextStyle(
                             fontSize: 12,
                             color: Colors.grey.shade600,
                           ),
                         ),
                      
                                             // Mostrar la cartilla visual siempre que se encuentre la cartilla
                       const SizedBox(height: 16),
                       
                       if (widget.appProvider.bingoGame.calledNumbers.isNotEmpty) ...[
                         const SizedBox(height: 8),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: Colors.orange.shade100,
                             borderRadius: BorderRadius.circular(4),
                             border: Border.all(color: Colors.orange.shade300),
                           ),
                           child: Text(
                             'Última bola cantada: ${widget.appProvider.bingoGame.calledNumbers.last}',
                             style: TextStyle(
                               fontSize: 12,
                               fontWeight: FontWeight.w500,
                               color: Colors.orange.shade800,
                             ),
                           ),
                         ),
                       ],
                       const SizedBox(height: 12),
                       
                       // Cartilla visual simplificada (solo números llamados y última bola)
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: Colors.green.shade300, width: 2),
                         ),
                         child: _buildSimpleCartillaVisual(
                           (_searchResult!['cartilla'] as FirebaseCartilla).numbers,
                           widget.appProvider.bingoGame.calledNumbers,
                         ),
                       ),
                    ],
                  ],
                ),
              ),
            ],
            

          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Mostrar mensaje de confirmación
            final totalWinningCards = widget.bingoCheck['totalWinningCards'] ?? 0;
            final totalPatternsCompleted = widget.bingoCheck['totalPatternsCompleted'] ?? 0;
            
            String message;
            if (totalPatternsCompleted > totalWinningCards) {
              message = '✅ ${totalWinningCards} CARTILLA${totalWinningCards > 1 ? 'S' : ''} GANADORA${totalWinningCards > 1 ? 'S' : ''} CON ${totalPatternsCompleted} PATRÓN${totalPatternsCompleted > 1 ? 'ES' : ''}';
            } else {
              message = '✅ ${totalWinningCards} BINGO${totalWinningCards > 1 ? 'S' : ''} VERIFICADO${totalWinningCards > 1 ? 'S' : ''}';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Confirmar BINGO'),
        ),
      ],
    );
  }

  Widget _buildSimpleCartillaVisual(List<List<int>> winningNumbers, List<int> calledNumbers) {
    final calledNumbersSet = Set<int>.from(calledNumbers);
    
    return Column(
      children: [
        // Título de la cartilla
        Text(
          'Cartilla ${(_searchResult!['cartilla'] as FirebaseCartilla).cardNo ?? 'N/A'}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 12),
        
        // Tabla de la cartilla
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.shade300, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            children: [
              for (int i = 0; i < 5; i++) ...[
                TableRow(
                  children: [
                    for (int j = 0; j < 5; j++) ...[
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getCellColor(i, j, winningNumbers[i][j], calledNumbersSet),
                          border: Border.all(
                            color: _getCellBorderColor(i, j),
                            width: _getCellBorderWidth(i, j),
                          ),
                        ),
                        child: Text(
                          winningNumbers[i][j].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getCellTextColor(i, j, winningNumbers[i][j], calledNumbersSet),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Leyenda
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                border: Border.all(color: Colors.red.shade400),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Número Llamado',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.orange.shade300,
                border: Border.all(color: Colors.orange.shade600, width: 2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Última Bola',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Obtener el color de fondo de la celda
  Color _getCellColor(int i, int j, int cellNumber, Set<int> calledNumbers) {
    final calledNumbersList = calledNumbers.toList();
    final lastCalledNumber = calledNumbersList.isNotEmpty ? calledNumbersList.last : null;
    
    if (cellNumber == lastCalledNumber) {
      return Colors.orange.shade200; // Última bola cantada
    } else if (calledNumbers.contains(cellNumber)) {
      return Colors.red.shade100; // Solo número llamado
    } else {
      return Colors.white; // Texto normal
    }
  }

  // Obtener el color del borde de la celda
  Color _getCellBorderColor(int i, int j) {
    return Colors.grey.shade300;
  }

  // Obtener el grosor del borde de la celda
  double _getCellBorderWidth(int i, int j) {
    return 1.0;
  }

  // Obtener el color del texto de la celda
  Color _getCellTextColor(int i, int j, int cellNumber, Set<int> calledNumbers) {
    final calledNumbersList = calledNumbers.toList();
    final lastCalledNumber = calledNumbersList.isNotEmpty ? calledNumbersList.last : null;
    
    if (cellNumber == lastCalledNumber) {
      return Colors.orange.shade800; // Última bola cantada
    } else if (calledNumbers.contains(cellNumber)) {
      return Colors.red.shade700; // Número llamado
    } else {
      return Colors.black; // Texto normal
    }
  }
} 