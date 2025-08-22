import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/bingo_game.dart';
import '../models/firebase_cartilla.dart';
import 'cartillas_dialog.dart';
import 'control_panel_sections.dart';
import 'bingo_games_panel.dart';

class ControlPanel extends StatefulWidget {
  final BingoGame bingoGame;
  final VoidCallback onStateChanged;
  
  const ControlPanel({
    super.key,
    required this.bingoGame,
    required this.onStateChanged,
  });

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final bingoGame = appProvider.bingoGame;
        final calledNumbers = bingoGame.calledNumbers;
        final totalBalls = bingoGame.allNumbers.length;
        final remainingBalls = totalBalls - calledNumbers.length;
        
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bola actual llamada
                CurrentBallDisplay(
                  bingoGame: bingoGame,
                  calledNumbersCount: calledNumbers.length,
                  totalBalls: totalBalls,
                ),
                
                const SizedBox(height: 24),
                
                // Botones de acción principales
                ActionButtonsRow(
                  onCallNumber: () {
                    appProvider.callNumber();
                    widget.onStateChanged();
                    
                    // Solo verificar patrones, NO mostrar notificaciones automáticas
                    final bingoCheck = appProvider.checkBingoInRealTime();
                    if (bingoCheck['hasBingo'] == true) {
                      print('DEBUG: ¡BINGO detectado después de llamar número!');
                      // NO mostrar notificación automática - solo marcar patrones
                    }
                  },
                  onVerifyBingo: () {
                    _showBingoVerificationDialog(context);
                  },
                  onCheckBingoRealTime: () {
                    _checkBingoInRealTime(context);
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Botones secundarios
                SecondaryButtonsRow(
                  onViewCartillas: () {
                    print('DEBUG: Botón "Ver Cartillas" presionado');
                    print('DEBUG: Número de cartillas: ${bingoGame.cartillas.length}');
                    _showCartillasDialog(context, bingoGame);
                  },
                  onReset: () {
                    appProvider.resetGame();
                    widget.onStateChanged();
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Botón de barajar
                ShuffleButton(
                  onShuffle: () {
                    appProvider.bingoGame.shuffleNumbers();
                    widget.onStateChanged();
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Estadísticas del juego
                GameStatsCard(
                  calledNumbersCount: calledNumbers.length,
                  remainingBalls: remainingBalls,
                  cartillasCount: bingoGame.cartillas.length,
                ),
                
                const SizedBox(height: 24),
                
                // Lista de bolas cantadas
                CalledNumbersSection(calledNumbers: calledNumbers),
                
                // Espacio extra para evitar overflow
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCartillasDialog(BuildContext context, BingoGame bingoGame) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CartillasDialog(bingoGame: bingoGame);
      },
    );
  }

  void _showBingoVerificationDialog(BuildContext context) {
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


  void _checkBingoInRealTime(BuildContext context) {
    // Obtener la ronda actual desde el contexto del juego
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // Obtener los patrones de la ronda actual
    final currentRoundPatterns = _getCurrentRoundPatternsFromContext(context);
    
    if (currentRoundPatterns.isNotEmpty) {
      print('DEBUG: Verificando bingo en tiempo real para patrones de ronda: $currentRoundPatterns');
      
      // Verificar bingo SOLO para los patrones de la ronda actual
      final bingoCheck = appProvider.checkBingoForSpecificRoundPatterns(currentRoundPatterns);
      
      if (bingoCheck['hasBingo'] == true) {
        // Mostrar solo patrones completados de la ronda actual
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                const Text('Patrones Completados - Ronda Actual'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡BINGO! Se completaron patrones de la ronda actual:',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...currentRoundPatterns.map((pattern) {
                  final isCompleted = (bingoCheck['completedPatterns'] as Map<String, bool>)[pattern] ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isCompleted ? Colors.green : Colors.grey,
                          size: 16
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pattern, 
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isCompleted ? Colors.green.shade700 : Colors.grey.shade600,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          )
                        ),
                        if (isCompleted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              'COMPLETADO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
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
                      Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Progreso de la ronda: ${(bingoCheck['completedPatterns'] as Map<String, bool>).entries.where((e) => currentRoundPatterns.contains(e.key) && e.value).length}/${currentRoundPatterns.length} patrones completados',
                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
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
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      } else {
        // Mostrar mensaje de que no hay bingo para la ronda actual
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ No hay BINGO para los patrones de la ronda actual'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Si no hay patrones de ronda específica, usar verificación general
      print('DEBUG: No hay patrones de ronda específica, usando verificación general');
      final bingoCheck = appProvider.checkBingoInRealTime();
      
      if (bingoCheck['hasBingo'] == true) {
        // Mostrar solo patrones completados, NO cartillas ganadoras
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                const Text('Patrones Completados'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bingoCheck['message'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...(bingoCheck['completedPatterns'] as Map<String, bool>).entries.map((entry) {
                  if (entry.value == true) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total de patrones completados: ${(bingoCheck['completedPatterns'] as Map<String, bool>).entries.where((e) => e.value).length}',
                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
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
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${bingoCheck['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


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

    if (result['found'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔍 ${result['message']}'),
          backgroundColor: result['isWinning'] == true ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result['message']}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
                    Row(
                      children: [
                        Icon(
                          _searchResult!['isWinning'] == true 
                            ? Icons.emoji_events 
                            : Icons.info,
                          color: _searchResult!['isWinning'] == true 
                            ? Colors.amber 
                            : Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _searchResult!['message'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _searchResult!['isWinning'] == true 
                                ? Colors.green.shade700 
                                : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_searchResult!['found'] == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${(_searchResult!['cartilla'] as FirebaseCartilla).id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if ((_searchResult!['cartilla'] as FirebaseCartilla).assignedTo != null)
                        Text(
                          'Vendedor: ${widget.appProvider.getVendorName((_searchResult!['cartilla'] as FirebaseCartilla).assignedTo)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      
                      // Mostrar la cartilla visual si es ganadora
                      if (_searchResult!['isWinning'] == true) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Patrón Ganador: ${_searchResult!['pattern']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Cartilla visual con patrón resaltado
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300, width: 2),
                          ),
                          child: _buildCartillaVisual(
                            _searchResult!['winningNumbers'] as List<List<int>>,
                            _searchResult!['calledNumbers'] as List<int>,
                            _searchResult!['pattern'] as String,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            // Mostrar solo patrones de la ronda actual si están disponibles
            if (widget.currentRoundPatterns.isNotEmpty) ...[
              Text(
                'Patrones completados de la ronda actual:', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue.shade700)
              ),
              const SizedBox(height: 8),
              ...widget.currentRoundPatterns.map((pattern) {
                final isCompleted = (widget.bingoCheck['completedPatterns'] as Map<String, bool>)[pattern] ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isCompleted ? Colors.green : Colors.grey,
                        size: 16
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pattern, 
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isCompleted ? Colors.green.shade700 : Colors.grey.shade600,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        )
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            'COMPLETADO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Progreso de la ronda: ${(widget.bingoCheck['completedPatterns'] as Map<String, bool>).entries.where((e) => widget.currentRoundPatterns.contains(e.key) && e.value).length}/${widget.currentRoundPatterns.length} patrones completados',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Mostrar todos los patrones si no hay ronda específica
              Text('Patrones completados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...(widget.bingoCheck['completedPatterns'] as Map<String, bool>).entries.map((entry) {
                if (entry.value == true) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total de patrones completados: ${(widget.bingoCheck['completedPatterns'] as Map<String, bool>).entries.where((e) => e.value).length}',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${widget.bingoCheck['totalWinningCards']} BINGO${widget.bingoCheck['totalWinningCards'] > 1 ? 'S' : ''} VERIFICADO${widget.bingoCheck['totalWinningCards'] > 1 ? 'S' : ''}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Confirmar BINGO'),
        ),
      ],
    );
  }

  Widget _buildCartillaVisual(List<List<int>> winningNumbers, List<int> calledNumbers, String pattern) {
    final calledNumbersSet = Set<int>.from(calledNumbers);
    
    // Determinar qué celdas están en el patrón ganador
    final winningCells = _getWinningPatternCells(pattern);
    
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
                          color: _getCellColor(i, j, winningCells, calledNumbersSet, winningNumbers[i][j]),
                          border: Border.all(
                            color: _getCellBorderColor(i, j, winningCells),
                            width: _getCellBorderWidth(i, j, winningCells),
                          ),
                        ),
                        child: Text(
                          winningNumbers[i][j].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getCellTextColor(i, j, winningCells, calledNumbersSet, winningNumbers[i][j]),
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
                color: Colors.green.shade200,
                border: Border.all(color: Colors.green.shade600, width: 2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Patrón Ganador',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
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
          ],
        ),
      ],
    );
  }

  // Obtener las celdas que forman parte del patrón ganador
  Set<String> _getWinningPatternCells(String pattern) {
    final cells = <String>{};
    
    switch (pattern) {
      case 'Línea Horizontal':
        // Primera fila
        for (int j = 0; j < 5; j++) {
          cells.add('0,$j');
        }
        break;
      case 'Línea Vertical':
        // Primera columna
        for (int i = 0; i < 5; i++) {
          cells.add('$i,0');
        }
        break;
      case 'Diagonal Principal':
        // Diagonal de esquina a esquina
        for (int i = 0; i < 5; i++) {
          cells.add('$i,$i');
        }
        break;
      case 'Diagonal Secundaria':
        // Diagonal inversa
        for (int i = 0; i < 5; i++) {
          cells.add('$i,${4 - i}');
        }
        break;
      case 'Marco Completo':
        // Todas las celdas del borde
        for (int i = 0; i < 5; i++) {
          for (int j = 0; j < 5; j++) {
            if (i == 0 || i == 4 || j == 0 || j == 4) {
              cells.add('$i,$j');
            }
          }
        }
        break;
      case 'Marco Pequeño':
        // Marco interior (filas 1-3, columnas 1-3)
        for (int i = 1; i < 4; i++) {
          for (int j = 1; j < 4; j++) {
            cells.add('$i,$j');
          }
        }
        break;
      case 'Cartón Lleno':
        // Todas las celdas
        for (int i = 0; i < 5; i++) {
          for (int j = 0; j < 5; j++) {
            cells.add('$i,$j');
          }
        }
        break;
      default:
        // Para otros patrones, no resaltar nada específico
        break;
    }
    
    return cells;
  }

  // Obtener el color de fondo de la celda
  Color _getCellColor(int i, int j, Set<String> winningCells, Set<int> calledNumbers, int cellNumber) {
    final cellKey = '$i,$j';
    
    if (winningCells.contains(cellKey)) {
      // Celda del patrón ganador
      if (calledNumbers.contains(cellNumber)) {
        return Colors.green.shade200; // Patrón ganador + número llamado
      } else {
        return Colors.green.shade100; // Solo patrón ganador
      }
    } else if (calledNumbers.contains(cellNumber)) {
      return Colors.red.shade100; // Solo número llamado
    } else {
      return Colors.white; // Celda normal
    }
  }

  // Obtener el color del borde de la celda
  Color _getCellBorderColor(int i, int j, Set<String> winningCells) {
    final cellKey = '$i,$j';
    return winningCells.contains(cellKey) ? Colors.green.shade600 : Colors.grey.shade300;
  }

  // Obtener el grosor del borde de la celda
  double _getCellBorderWidth(int i, int j, Set<String> winningCells) {
    final cellKey = '$i,$j';
    return winningCells.contains(cellKey) ? 2.0 : 1.0;
  }

  // Obtener el color del texto de la celda
  Color _getCellTextColor(int i, int j, Set<String> winningCells, Set<int> calledNumbers, int cellNumber) {
    final cellKey = '$i,$j';
    
    if (winningCells.contains(cellKey)) {
      return Colors.green.shade800; // Patrón ganador
    } else if (calledNumbers.contains(cellNumber)) {
      return Colors.red.shade700; // Número llamado
    } else {
      return Colors.black; // Texto normal
    }
  }
} 