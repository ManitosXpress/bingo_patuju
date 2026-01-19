import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/bingo_game.dart';
import '../models/firebase_cartilla.dart';
import 'cartillas_dialog.dart';
import 'control_panel_sections.dart';
import 'bingo_games_panel.dart';
import 'glass_container.dart'; // Importar componente de vidrio

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
        
        return GlassContainer(
          borderRadius: 24,
          blurIntensity: 12.0,
          padding: const EdgeInsets.all(20.0),
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
                    
                    // NO verificar bingo automáticamente al cantar bola
                    // La verificación solo se hace cuando se presiona "Verificar Bingo"
                    // Esto mejora significativamente el rendimiento
                  },
                  onVerifyBingo: () {
                    _showBingoVerificationDialog(context);
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Botones secundarios
                SecondaryButtonsRow(
                  onViewCartillas: () {
                    _showCartillasDialog(context, bingoGame);
                  },
                  onReset: () {
                    _showResetConfirmationDialog(context, appProvider);
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
                
                // Lista de bolas cantadas (con scroll interno)
              Expanded(
                child: CalledNumbersSection(calledNumbers: calledNumbers),
              ),
            ],
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

  void _showResetConfirmationDialog(BuildContext context, AppProvider appProvider) {
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
                widget.onStateChanged();
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      if (bingoCheck['totalWinningCards'] != null && bingoCheck['totalPatternsCompleted'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.style, color: Colors.blue.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cartillas ganadoras: ${bingoCheck['totalWinningCards']} (${bingoCheck['totalPatternsCompleted']} patrones totales)',
                                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
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