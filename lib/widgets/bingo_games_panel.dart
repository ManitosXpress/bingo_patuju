import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bingo_game_config.dart';
import 'bingo_patterns_dialog.dart';
import '../models/bingo_game.dart';
import '../providers/app_provider.dart';
import '../services/rounds_persistence_service.dart';

class BingoGamesPanel extends StatefulWidget {
  final VoidCallback? onGameStateChanged;
  
  const BingoGamesPanel({
    super.key,
    this.onGameStateChanged,
  });

  @override
  State<BingoGamesPanel> createState() => _BingoGamesPanelState();
}

// Variable global para acceder a los patrones de la ronda actual
class BingoGamesPanelState {
  static List<String> _currentRoundPatterns = [];
  static int _currentRoundIndex = 0;
  static String? _selectedGameId;
  
  static void updateCurrentRoundPatterns(List<String> patterns, int roundIndex, String? gameId) {
    _currentRoundPatterns = patterns;
    _currentRoundIndex = roundIndex;
    _selectedGameId = gameId;
    print('DEBUG: Patrones de ronda actual actualizados: $_currentRoundPatterns (Ronda $_currentRoundIndex del juego $_selectedGameId)');
  }
  
  static List<String> getCurrentRoundPatterns() {
    return List.from(_currentRoundPatterns);
  }
  
  static int getCurrentRoundIndex() {
    return _currentRoundIndex;
  }
  
  static String? getSelectedGameId() {
    return _selectedGameId;
  }
}

class _BingoGamesPanelState extends State<BingoGamesPanel> {
  BingoGameConfig? _selectedGame;
  int _currentRoundIndex = 0;
  
  // Lista de juegos disponibles
  List<BingoGameConfig> _games = [];
  
  // Mapa local para patrones marcados manualmente por el usuario
  final Map<String, bool> _manuallyMarkedPatterns = {};

  @override
  void initState() {
    super.initState();
    
    // Cargar juegos predefinidos
    _loadDefaultGames();
    
    // Cargar rondas guardadas y seleccionar el juego correspondiente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedRounds();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }



  // Método para cargar juegos predefinidos
  void _loadDefaultGames() {
    _games = BingoGamePresets.defaultGames;
  }

  // Método para cargar rondas guardadas
  Future<void> _loadSavedRounds() async {
    try {
      // Verificar si hay datos guardados
      final hasData = await RoundsPersistenceService.hasSavedData();
      
      if (hasData) {
        // Obtener el ID del juego actual
        final currentGameId = await RoundsPersistenceService.getCurrentGameId();
        
        if (currentGameId != null) {
          // Buscar el juego en la lista de juegos disponibles
          final savedGame = _games.firstWhere(
            (game) => game.id == currentGameId,
            orElse: () => _games.first,
          );
          
          // Cargar las rondas guardadas
          final savedRounds = await RoundsPersistenceService.loadGameRounds(currentGameId);
          
          if (savedRounds != null && savedRounds.rounds.isNotEmpty) {
            // Actualizar el juego seleccionado con las rondas guardadas
            setState(() {
              _selectedGame = savedRounds;
              // Actualizar el juego en la lista de juegos
              final gameIndex = _games.indexWhere((game) => game.id == currentGameId);
              if (gameIndex != -1) {
                _games[gameIndex] = savedRounds;
              }
            });
            
                         // Cargar el índice de la ronda actual
             final currentRoundIndex = await RoundsPersistenceService.loadCurrentRoundIndex();
             await _updateCurrentRoundIndex(currentRoundIndex);
            
            print('DEBUG: Rondas guardadas cargadas para el juego: ${savedRounds.name}');
          } else {
            // No hay rondas guardadas, seleccionar el primer juego
            _selectDefaultGame();
          }
        } else {
          // No hay juego actual guardado, seleccionar el primer juego
          _selectDefaultGame();
        }
      } else {
        // No hay datos guardados, seleccionar el primer juego
        _selectDefaultGame();
      }
    } catch (e) {
      print('ERROR: Error cargando rondas guardadas: $e');
      // En caso de error, seleccionar el primer juego
      _selectDefaultGame();
    }
  }

  // Método para seleccionar el juego por defecto
  Future<void> _selectDefaultGame() async {
    if (_games.isNotEmpty) {
      setState(() {
        _selectedGame = _games.first;
      });
      await _updateCurrentRoundIndex(0);
    }
  }

  // Método para limpiar todos los datos guardados
  void _clearSavedData(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text('Limpiar Datos Guardados'),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que quieres limpiar todos los datos guardados?\n\n'
            'Esto eliminará todas las rondas creadas y el progreso del juego actual.\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Limpiar datos guardados
                await RoundsPersistenceService.clearAllData();
                
                // Resetear el estado local
                setState(() {
                  _selectedGame = _games.first;
                  _currentRoundIndex = 0;
                });
                
                // Actualizar la variable estática
                await _updateCurrentRoundIndex(0);
                
                Navigator.of(context).pop();
                
                // Mostrar mensaje de confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Todos los datos han sido limpiados'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Limpiar Todo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }



  void _showPatternsDialog(BuildContext context) {
    // Crear un BingoGame temporal para mostrar en el diálogo
    final tempBingoGame = BingoGame();
    
    // Si hay un juego seleccionado y una ronda actual, mostrar solo las figuras de esa ronda
    BingoGameRound? currentRound;
    if (_selectedGame != null && _currentRoundIndex < _selectedGame!.rounds.length) {
      currentRound = _selectedGame!.rounds[_currentRoundIndex];
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BingoPatternsDialog(
          bingoGame: tempBingoGame,
          currentRound: currentRound,
        );
      },
    );
  }

  void _showGameSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _GameSelectorDialog(
          currentGame: _selectedGame,
          onGameSelected: (game) async {
            setState(() {
              _selectedGame = game;
            });
            
            // Guardar las rondas del juego seleccionado
            await RoundsPersistenceService.saveGameRounds(game);
            
            // Usar el método que actualiza la variable estática
            await _updateCurrentRoundIndex(0);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _showCreateGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _CreateGameDialog(
          onGameCreated: (newGame) async {
            setState(() {
              _selectedGame = newGame;
            });
            
            // Guardar las rondas del nuevo juego
            await RoundsPersistenceService.saveGameRounds(newGame);
            
            // Usar el método que actualiza la variable estática
            await _updateCurrentRoundIndex(0);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _showEditGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _EditGameDialog(
          game: _selectedGame!,
          onGameUpdated: (updatedGame) async {
            setState(() {
              _selectedGame = updatedGame;
            });
            
            // Guardar las rondas del juego actualizado
            await RoundsPersistenceService.saveGameRounds(updatedGame);
            
            // Usar el método que actualiza la variable estática
            await _updateCurrentRoundIndex(0);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _loadGamesWithLegendaryFigures() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text('Cargar Figuras Legendarias'),
            ],
          ),
          content: const Text(
            '¿Deseas cargar automáticamente todos los juegos con las nuevas figuras legendarias incluidas?\n\n'
            'Esto creará juegos predefinidos para cada día de la semana con figuras legendarias distribuidas en todas las rondas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _loadLegendaryGames();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Cargar Figuras Legendarias'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _loadLegendaryGames() async {
    final legendaryGames = BingoGamePresets.getGamesWithLegendaryFigures();
    
    setState(() {
      _games = legendaryGames;
      _selectedGame = legendaryGames.first;
      _currentRoundIndex = 0;
    });
    
    // Guardar las rondas del primer juego legendario
    if (legendaryGames.isNotEmpty) {
      await RoundsPersistenceService.saveGameRounds(legendaryGames.first);
    }
    
    // Mostrar mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white),
            const SizedBox(width: 8),
            const Text('¡Figuras legendarias cargadas exitosamente!'),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Actualizar la variable estática
    await _updateCurrentRoundIndex(0);
  }

  void _markCurrentRoundAsCompleted() async {
    if (_selectedGame != null && _currentRoundIndex < _selectedGame!.rounds.length) {
      setState(() {
        _selectedGame!.rounds[_currentRoundIndex].isCompleted = true;
      });
      
      // Guardar el estado del juego
      await RoundsPersistenceService.saveGameRounds(_selectedGame!);
      
      // Avanzar automáticamente a la siguiente ronda si no es la última
      if (_currentRoundIndex < _selectedGame!.rounds.length - 1) {
        await _updateCurrentRoundIndex(_currentRoundIndex + 1);
      }
    }
  }

  void _resetGame() async {
    if (_selectedGame != null) {
      setState(() {
        for (var round in _selectedGame!.rounds) {
          round.isCompleted = false;
        }
      });
      
      // Limpiar todos los patrones marcados manualmente
      _clearAllManuallyMarkedPatterns();
      
      // Guardar el estado del juego reseteado
      await RoundsPersistenceService.saveGameRounds(_selectedGame!);
      
      // Usar el método que actualiza la variable estática
      await _updateCurrentRoundIndex(0);
    }
  }

  bool get _isGameCompleted {
    if (_selectedGame == null) return false;
    return _selectedGame!.rounds.every((round) => round.isCompleted);
  }

  // Método para forzar la actualización del estado
  void _forceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  // Método para actualizar la variable estática cuando cambie la ronda
  Future<void> _updateCurrentRoundIndex(int newIndex) async {
    print('DEBUG: Cambiando ronda de $_currentRoundIndex a $newIndex');
    
    // Limpiar patrones marcados manualmente de la ronda anterior
    _clearManuallyMarkedPatternsForRound(_currentRoundIndex);
    
    setState(() {
      _currentRoundIndex = newIndex;
    });
    
    // Guardar el índice de la ronda actual
    await RoundsPersistenceService.saveCurrentRoundIndex(newIndex);
    
    // Actualizar la variable estática después de cambiar la ronda
    final patterns = getCurrentRoundPatterns();
    print('DEBUG: Patrones actualizados después del cambio de ronda: $patterns');
  }

  // Método para limpiar patrones marcados manualmente de una ronda específica
  void _clearManuallyMarkedPatternsForRound(int roundIndex) {
    if (_selectedGame == null || roundIndex >= _selectedGame!.rounds.length) return;
    
    final round = _selectedGame!.rounds[roundIndex];
    final allRoundPatterns = _getAllPatternsForRound(round);
    
    print('DEBUG: Limpiando patrones marcados manualmente de ronda ${round.name}');
    
    // Limpiar solo los patrones de esta ronda específica
    for (var pattern in allRoundPatterns) {
      final patternName = _getPatternName(pattern);
      if (_manuallyMarkedPatterns.containsKey(patternName)) {
        print('DEBUG: Limpiando patrón manual: $patternName');
        _manuallyMarkedPatterns.remove(patternName);
      }
    }
    
    print('DEBUG: Patrones manuales limpiados para ronda ${round.name}');
  }

  // Método para limpiar todos los patrones marcados manualmente
  void _clearAllManuallyMarkedPatterns() {
    print('DEBUG: Limpiando todos los patrones marcados manualmente');
    _manuallyMarkedPatterns.clear();
    setState(() {});
  }

  // Método para obtener todos los patrones de una ronda (incluyendo consuelo si existe)
  // Con reglas especiales: Cartón Lleno siempre penúltimo, Consuelo siempre último
  List<BingoPattern> _getAllPatternsForRound(BingoGameRound round) {
    List<BingoPattern> allPatterns = List.from(round.patterns);
    
    // Buscar si hay un juego consuelo para esta ronda
    if (_selectedGame != null) {
      final roundIndex = _selectedGame!.rounds.indexOf(round);
      if (roundIndex != -1 && roundIndex + 1 < _selectedGame!.rounds.length) {
        final nextRound = _selectedGame!.rounds[roundIndex + 1];
        if (nextRound.name.toLowerCase().contains('consuelo')) {
          allPatterns.addAll(nextRound.patterns);
          print('DEBUG: Agregando patrones de consuelo para ${round.name}: ${nextRound.patterns}');
        }
      }
    }
    
    // Aplicar reglas de orden: Cartón Lleno penúltimo, Consuelo último
    return _reorderPatternsForDisplay(allPatterns);
  }

  // Método para reordenar patrones según reglas especiales
  List<BingoPattern> _reorderPatternsForDisplay(List<BingoPattern> patterns) {
    final normalPatterns = <BingoPattern>[];
    final cartonLlenoPatterns = <BingoPattern>[];
    final consueloPatterns = <BingoPattern>[];
    
    // Separar patrones según su tipo
    for (final pattern in patterns) {
      if (pattern == BingoPattern.cartonLleno) {
        cartonLlenoPatterns.add(pattern);
      } else if (pattern == BingoPattern.consuelo) {
        consueloPatterns.add(pattern);
      } else {
        normalPatterns.add(pattern);
      }
    }
    
    // Construir lista final con orden correcto
    final orderedPatterns = <BingoPattern>[];
    orderedPatterns.addAll(normalPatterns);        // Patrones normales primero
    orderedPatterns.addAll(cartonLlenoPatterns);   // Cartón Lleno penúltimo
    orderedPatterns.addAll(consueloPatterns);      // Consuelo último
    
    return orderedPatterns;
  }

  // Método para obtener TODAS las figuras disponibles (no solo las de la ronda)
  List<String> getAllAvailablePatterns() {
    return BingoPattern.values.map((pattern) => _getPatternDisplayName(pattern)).toList();
  }

  // Método para obtener los patrones de la ronda actual
  List<String> getCurrentRoundPatterns() {
    if (_selectedGame != null && _currentRoundIndex < _selectedGame!.rounds.length) {
      final currentRound = _selectedGame!.rounds[_currentRoundIndex];
      final patterns = currentRound.patterns.map((p) => _getPatternDisplayName(p)).toList();
      
      // Buscar si hay un juego consuelo para esta ronda
      List<String> consueloPatterns = [];
      if (_currentRoundIndex + 1 < _selectedGame!.rounds.length) {
        final nextRound = _selectedGame!.rounds[_currentRoundIndex + 1];
        if (nextRound.name.toLowerCase().contains('consuelo')) {
          consueloPatterns = nextRound.patterns.map((p) => _getPatternDisplayName(p)).toList();
          print('DEBUG: Juego consuelo encontrado para la ronda actual: $consueloPatterns');
        }
      }
      
      // Combinar patrones principales y de consuelo
      final allPatterns = [...patterns, ...consueloPatterns];
      
      print('DEBUG: Obteniendo patrones de ronda actual:');
      print('DEBUG: - Juego seleccionado: ${_selectedGame!.name}');
      print('DEBUG: - Ronda actual: ${currentRound.name} (índice: $_currentRoundIndex)');
      print('DEBUG: - Patrones principales: $patterns');
      print('DEBUG: - Patrones de consuelo: $consueloPatterns');
      print('DEBUG: - Patrones totales: $allPatterns');
      
      // Actualizar la variable estática para que esté disponible globalmente
      BingoGamesPanelState.updateCurrentRoundPatterns(
        allPatterns, 
        _currentRoundIndex, 
        _selectedGame!.id
      );
      
      return allPatterns;
    }
    
    print('DEBUG: No hay juego seleccionado o ronda válida');
    // Si no hay juego seleccionado, limpiar la variable estática
    BingoGamesPanelState.updateCurrentRoundPatterns([], 0, null);
    return [];
  }

  String _getPatternName(BingoPattern pattern) {
    switch (pattern) {
      case BingoPattern.diagonalPrincipal:
        return 'Diagonal Principal';
      case BingoPattern.diagonalSecundaria:
        return 'Diagonal Secundaria';
      case BingoPattern.lineaHorizontal:
        return 'Línea Horizontal';
      case BingoPattern.marcoCompleto:
        return 'Marco Completo';
      case BingoPattern.marcoPequeno:
        return 'Marco Pequeño';
      case BingoPattern.spoutnik:
        return 'Spoutnik';
      case BingoPattern.corazon:
        return 'Corazón';
      case BingoPattern.cartonLleno:
        return 'Cartón Lleno';
      case BingoPattern.consuelo:
        return 'Consuelo';
      case BingoPattern.x:
        return 'X';
      // Nuevas figuras legendarias
      case BingoPattern.relojArena:
        return 'Reloj de Arena';
      case BingoPattern.dobleLineaV:
        return 'Doble Línea V';
      case BingoPattern.figuraSuegra:
        return 'Figura la Suegra';
      case BingoPattern.figuraComodin:
        return 'Figura Comodín';
      case BingoPattern.letraFE:
        return 'Letra FE';
      case BingoPattern.figuraCLoca:
        return 'Figura C Loca';
      case BingoPattern.figuraBandera:
        return 'Figura Bandera';
      case BingoPattern.figuraTripleLinea:
        return 'Figura Triple Línea';
      case BingoPattern.diagonalDerecha:
        return 'Diagonal Derecha';
    }
  }

  String _getPatternDisplayName(BingoPattern pattern) {
    switch (pattern) {
      case BingoPattern.diagonalPrincipal:
        return 'Diagonal Principal';
      case BingoPattern.diagonalSecundaria:
        return 'Diagonal Secundaria';
      case BingoPattern.lineaHorizontal:
        return 'Línea Horizontal';
      case BingoPattern.marcoCompleto:
        return 'Marco Completo';
      case BingoPattern.marcoPequeno:
        return 'Marco Pequeño';
      case BingoPattern.spoutnik:
        return 'Spoutnik';
      case BingoPattern.corazon:
        return 'Corazón';
      case BingoPattern.cartonLleno:
        return 'Cartón Lleno';
      case BingoPattern.consuelo:
        return 'Consuelo';
      case BingoPattern.x:
        return 'X';
      // Nuevas figuras legendarias
      case BingoPattern.relojArena:
        return 'Reloj de Arena';
      case BingoPattern.dobleLineaV:
        return 'Doble Línea V';
      case BingoPattern.figuraSuegra:
        return 'Figura la Suegra';
      case BingoPattern.figuraComodin:
        return 'Figura Comodín';
      case BingoPattern.letraFE:
        return 'Letra FE';
      case BingoPattern.figuraCLoca:
        return 'Figura C Loca';
      case BingoPattern.figuraBandera:
        return 'Figura Bandera';
      case BingoPattern.figuraTripleLinea:
        return 'Figura Triple Línea';
      case BingoPattern.diagonalDerecha:
        return 'Diagonal Derecha';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {

        
        return Card(
          margin: const EdgeInsets.all(4.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título del panel con selector de juego
                Row(
                  children: [
                    Icon(Icons.games, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Juegos de Bingo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    // Botón para cambiar de juego
                    IconButton(
                      onPressed: () => _showGameSelectorDialog(context),
                      icon: Icon(Icons.swap_horiz, color: Colors.blue.shade600, size: 20),
                      tooltip: 'Cambiar Juego',
                    ),
                    // Botón para crear nuevo juego
                    IconButton(
                      onPressed: () => _showCreateGameDialog(context),
                      icon: Icon(Icons.add_circle_outline, color: Colors.green.shade600, size: 20),
                      tooltip: 'Crear Nuevo Juego',
                    ),
                    // Botón para cargar juegos con figuras legendarias
                    IconButton(
                      onPressed: () => _loadGamesWithLegendaryFigures(),
                      icon: Icon(Icons.auto_awesome, color: Colors.orange.shade600, size: 20),
                      tooltip: 'Cargar Figuras Legendarias',
                    ),
                  ],
                ),
                                 const SizedBox(height: 8),
                 
                 // Botón para ver todas las figuras de bingo
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton.icon(
                     onPressed: () => _showPatternsDialog(context),
                     icon: const Icon(Icons.grid_view, size: 14),
                     label: const Text(
                       'Ver Todas las Figuras de Bingo',
                       style: TextStyle(fontSize: 11),
                     ),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.purple.shade600,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 6),
                       minimumSize: const Size(0, 32),
                     ),
                   ),
                 ),
                 
                 const SizedBox(height: 6),
                
                // Indicador de estado de cartillas
                Consumer<AppProvider>(
                  builder: (context, appProvider, child) {
                    if (appProvider.isLoadingFirebase) {
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cargando cartillas...',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (appProvider.totalCartillas > 0) {
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${appProvider.totalCartillas} cartillas disponibles',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Botón de actualizar
                            IconButton(
                              onPressed: () async {
                                await appProvider.loadFirebaseCartillas(reset: true);
                              },
                              icon: Icon(
                                Icons.refresh,
                                color: Colors.green.shade600,
                                size: 12,
                              ),
                              tooltip: 'Actualizar cartillas',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              iconSize: 12,
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.orange.shade600,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'No hay cartillas cargadas',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Botón de cargar cartillas
                            IconButton(
                              onPressed: () async {
                                await appProvider.loadFirebaseCartillas(reset: true);
                              },
                              icon: Icon(
                                Icons.download,
                                color: Colors.orange.shade600,
                                size: 12,
                              ),
                              tooltip: 'Cargar cartillas',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              iconSize: 12,
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                
                                 const SizedBox(height: 6),
                 
                 // Información del juego seleccionado
                 if (_selectedGame != null) ...[
                   _buildGameInfo(),
                   const SizedBox(height: 6),
                   
                   // Lista de rondas - Hacer flexible
                   Expanded(
                     child: _buildRoundsList(),
                   ),
                   
                   const SizedBox(height: 6),
                   
                   // Indicador de figuras necesarias para la ronda actual
                   if (!_isGameCompleted && _selectedGame != null && _currentRoundIndex < _selectedGame!.rounds.length)
                     _buildCurrentRoundInfo(),
                   
                   const SizedBox(height: 6),
                   
                   // Controles del juego
                   _buildGameControls(),
                 ],
              ],
            ),
          ),
        );
      },
    );
  }




  Widget _buildGameInfo() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _isGameCompleted ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _isGameCompleted ? Colors.green.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _isGameCompleted ? Icons.celebration : Icons.info_outline,
                color: _isGameCompleted ? Colors.green.shade700 : Colors.blue.shade700,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _selectedGame!.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isGameCompleted ? Colors.green.shade700 : Colors.blue.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
              // Botón para editar el juego
              IconButton(
                onPressed: () => _showEditGameDialog(context),
                icon: Icon(
                  Icons.edit,
                  color: _isGameCompleted ? Colors.green.shade600 : Colors.blue.shade600,
                  size: 16,
                ),
                tooltip: 'Editar Juego',
              ),
            ],
          ),
                     const SizedBox(height: 3),
           Text(
             'Fecha: ${_selectedGame!.date}',
             style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
           ),
           Text(
             'Total de Rondas: ${_selectedGame!.rounds.length}',
             style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
           ),
           // Mostrar información de cartillas cargadas
           Consumer<AppProvider>(
             builder: (context, appProvider, child) {
               final totalCartillas = appProvider.totalCartillas;
               return Text(
                 'Cartillas Cargadas: $totalCartillas',
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                   fontSize: 10,
                   color: totalCartillas > 0 ? Colors.green.shade700 : Colors.orange.shade700,
                   fontWeight: totalCartillas > 0 ? FontWeight.bold : FontWeight.normal,
                 ),
               );
             },
           ),
          if (_isGameCompleted)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.celebration, color: Colors.green.shade700, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '¡Juego Completado!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoundsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // No expandir más del necesario
      children: [
        Text(
          'Rondas del Juego:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Hacer la lista flexible para evitar overflow
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _selectedGame!.rounds.isEmpty
                ? _buildEmptyRoundsMessage()
                : ListView.builder(
                    shrinkWrap: true, // Importante para evitar overflow
                    physics: const ClampingScrollPhysics(), // Scroll suave
                    itemCount: _selectedGame!.rounds.length,
                    itemBuilder: (context, index) {
                      final round = _selectedGame!.rounds[index];
                      final isCurrentRound = index == _currentRoundIndex;
                      final isCompleted = round.isCompleted;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrentRound 
                            ? Colors.green.shade50 
                            : isCompleted 
                              ? Colors.grey.shade100
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrentRound 
                              ? Colors.green.shade300 
                              : isCompleted
                                ? Colors.grey.shade400
                                : Colors.grey.shade300,
                            width: isCurrentRound ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isCurrentRound 
                                ? Colors.green.shade100 
                                : isCompleted
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: isCompleted
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isCurrentRound 
                                        ? Colors.green.shade700 
                                        : Colors.grey.shade700,
                                    ),
                                  ),
                            ),
                          ),
                          title: Text(
                            round.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isCurrentRound 
                                ? Colors.green.shade700 
                                : isCompleted
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, // No expandir más del necesario
                            children: [
                              Text(
                                round.patternsDisplay,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isCurrentRound 
                                    ? Colors.green.shade600 
                                    : isCompleted
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (round.description != null)
                                Text(
                                  round.description!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: isCurrentRound 
                                      ? Colors.green.shade600 
                                      : isCompleted
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade600,
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botón para editar esta ronda específica
                              IconButton(
                                onPressed: () => _showEditRoundDialog(context, round, index),
                                icon: Icon(
                                  Icons.edit,
                                  color: isCurrentRound ? Colors.orange.shade600 : Colors.grey.shade600,
                                  size: 16,
                                ),
                                tooltip: 'Editar Ronda',
                              ),
                              // Botón para ver figuras de esta ronda
                              IconButton(
                                onPressed: () => _showRoundPatternsDialog(context, round),
                                icon: Icon(
                                  Icons.visibility,
                                  color: isCurrentRound ? Colors.blue.shade600 : Colors.grey.shade600,
                                  size: 18,
                                ),
                                tooltip: 'Ver Figuras de esta Ronda',
                              ),
                              // Botón para eliminar esta ronda
                              IconButton(
                                onPressed: () => _deleteRound(index),
                                icon: Icon(
                                  Icons.delete,
                                  color: isCurrentRound ? Colors.red.shade600 : Colors.grey.shade600,
                                  size: 16,
                                ),
                                tooltip: 'Eliminar Ronda',
                              ),
                              // Indicador de completado
                              if (isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '✓',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                                                     onTap: isCompleted ? null : () async {
                             await _updateCurrentRoundIndex(index);
                           },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _showRoundPatternsDialog(BuildContext context, BingoGameRound round) {
    final tempBingoGame = BingoGame();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BingoPatternsDialog(
          bingoGame: tempBingoGame,
          currentRound: round,
        );
      },
    );
  }

  // Método para eliminar una ronda específica
  void _deleteRound(int roundIndex) {
    if (_selectedGame == null) return;
    
    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 8),
              const Text('Confirmar Eliminación'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que quieres eliminar la ronda "${_selectedGame!.rounds[roundIndex].name}"?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción no se puede deshacer. Se eliminarán todos los patrones y configuraciones de esta ronda.',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
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
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmDeleteRound(roundIndex);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Método para confirmar y ejecutar la eliminación de la ronda
  void _confirmDeleteRound(int roundIndex) {
    if (_selectedGame == null) return;
    
    try {
      final roundToDelete = _selectedGame!.rounds[roundIndex];
      print('DEBUG: Eliminando ronda: ${roundToDelete.name}');
      
      setState(() {
        // Eliminar la ronda
        _selectedGame!.rounds.removeAt(roundIndex);
        
        // Ajustar el índice de la ronda actual si es necesario
        if (_currentRoundIndex >= _selectedGame!.rounds.length) {
          _currentRoundIndex = _selectedGame!.rounds.length - 1;
        }
        if (_currentRoundIndex < 0) {
          _currentRoundIndex = 0;
        }
        
        // Actualizar la variable estática después de la eliminación
        if (_selectedGame!.rounds.isNotEmpty) {
          getCurrentRoundPatterns();
        } else {
          BingoGamesPanelState.updateCurrentRoundPatterns([], 0, null);
        }
      });
      
      // Mostrar notificación de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Ronda "${roundToDelete.name}" eliminada exitosamente'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Notificar cambios
      if (widget.onGameStateChanged != null) {
        widget.onGameStateChanged!();
      }
      
    } catch (e) {
      print('DEBUG: Error al eliminar ronda: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al eliminar la ronda: $e'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildGameControls() {
    // Solo mostrar controles si hay rondas disponibles
    if (_selectedGame == null || _selectedGame!.rounds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, color: Colors.grey.shade600, size: 32),
            const SizedBox(height: 8),
            Text(
              'Sin rondas para jugar',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Agrega rondas para habilitar los controles del juego',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // No expandir más del necesario
      children: [
        // Controles de navegación
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _currentRoundIndex > 0
                  ? () async {
                      await _updateCurrentRoundIndex(_currentRoundIndex - 1);
                    }
                  : null,
              icon: const Icon(Icons.arrow_back, size: 14), // Reducir tamaño
              label: const Text('Anterior', style: TextStyle(fontSize: 11)), // Reducir tamaño
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // Reducir padding
                minimumSize: const Size(0, 28), // Reducir altura
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Reducir padding
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(
                'Ronda ${_currentRoundIndex + 1} de ${_selectedGame!.rounds.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 10, // Reducir tamaño de fuente
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _currentRoundIndex < _selectedGame!.rounds.length - 1
                  ? () async {
                      await _updateCurrentRoundIndex(_currentRoundIndex + 1);
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward, size: 14), // Reducir tamaño
              label: const Text('Siguiente', style: TextStyle(fontSize: 11)), // Reducir tamaño
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // Reducir padding
                minimumSize: const Size(0, 28), // Reducir altura
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // Reducir espacio
        
        // Botón para marcar ronda como completada
        if (!_isGameCompleted && _selectedGame != null && _currentRoundIndex < _selectedGame!.rounds.length)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showRoundCompletionDialog(context),
              icon: const Icon(Icons.check_circle, size: 14), // Reducir tamaño
              label: Text(
                'Completar "${_selectedGame!.rounds[_currentRoundIndex].name}"',
                style: const TextStyle(fontSize: 11), // Reducir tamaño
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reducir padding
                minimumSize: const Size(0, 32), // Reducir altura
              ),
            ),
          ),
        
        // Botón para limpiar todos los patrones del juego
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _clearAllManuallyMarkedPatterns();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🧹 Todos los patrones del juego "${_selectedGame!.name}" han sido limpiados'),
                  backgroundColor: Colors.orange.shade600,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.clear_all, size: 14),
            label: const Text(
              'Limpiar Todos los Patrones',
              style: TextStyle(fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
      ],
    );
  }

  void _showRoundCompletionDialog(BuildContext context) {
    final round = _selectedGame!.rounds[_currentRoundIndex];
    final patternsToComplete = round.patterns.map((p) => _getPatternDisplayName(p)).join(', ');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Figuras Necesarias'),
          content: Text(
            'Para completar la ronda "${round.name}", necesitas completar los siguientes patrones:\n\n$patternsToComplete\n\n¿Estás seguro de que quieres marcar esta ronda como completada?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _markCurrentRoundAsCompleted();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sí, Marcar Completada'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentRoundInfo() {
    // Solo mostrar información de ronda si hay rondas disponibles
    if (_selectedGame == null || _selectedGame!.rounds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.blue.shade600, size: 32),
            const SizedBox(height: 8),
            Text(
              'No hay rondas disponibles',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crea una nueva ronda para comenzar a jugar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final round = _selectedGame!.rounds[_currentRoundIndex];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.yellow.shade700, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Figuras para "${round.name}"',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Mostrar solo las figuras de la ronda actual (incluyendo consuelo si existe)
          ..._getAllPatternsForRound(round).map((pattern) {
            final patternName = _getPatternDisplayName(pattern);
            final patternKey = _getPatternName(pattern);
            
            // Solo usar el estado manual
            final isCompleted = _manuallyMarkedPatterns[patternKey] ?? false;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  // Botón de toggle manual para tachar/des-tachar la figura
                  GestureDetector(
                    onTap: () {
                      // Toggle manual del estado de la figura
                      _toggleFigureManually(pattern, !isCompleted);
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCompleted ? Colors.green.shade600 : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(
                                Icons.check,
                                color: Colors.green.shade700,
                                size: 14,
                              )
                            : Icon(
                                Icons.add,
                                color: Colors.grey.shade600,
                                size: 14,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nombre de la figura
                  Expanded(
                    child: Text(
                      patternName,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCompleted ? Colors.green.shade700 : Colors.yellow.shade700,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Indicador de estado (solo Manual)
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'MANUAL',
                        style: TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          
          // Mostrar progreso general
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.yellow.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // Progreso manual
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Progreso Manual: ',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow.shade800,
                      ),
                    ),
                    Text(
                      '${_getAllPatternsForRound(round).where((p) => _manuallyMarkedPatterns[_getPatternName(p)] ?? false).length}/${_getAllPatternsForRound(round).length} figuras completadas',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow.shade800,
                      ),
                    ),
                  ],
                ),
                
                // Botón para limpiar patrones de la ronda actual
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _clearManuallyMarkedPatternsForRound(_currentRoundIndex);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🧹 Patrones de "${round.name}" limpiados'),
                            backgroundColor: Colors.blue.shade600,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(Icons.clear, size: 12),
                      label: Text(
                        'Limpiar Patrones',
                        style: TextStyle(fontSize: 8),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: const Size(0, 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Instrucciones para el usuario
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, color: Colors.blue.shade600, size: 10),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Toca cada figura para tacharla/des-tacharla manualmente',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFigureManually(BingoPattern pattern, bool isCompleted) async {
    try {
      final patternName = _getPatternName(pattern);
      
      print('DEBUG: Toggle manual de figura "$patternName" a estado: $isCompleted');
      
      // Actualizar el estado en el mapa local
      _manuallyMarkedPatterns[patternName] = isCompleted;
      
      print('DEBUG: Figura "$patternName" actualizada manualmente');
      
      // Verificar si la ronda actual se puede completar después de este cambio
      if (_selectedGame != null && _currentRoundIndex < _selectedGame!.rounds.length) {
        final currentRound = _selectedGame!.rounds[_currentRoundIndex];
        
        // Verificar si todos los patrones de la ronda están completados manualmente
        bool allPatternsCompleted = true;
        final allRoundPatterns = _getAllPatternsForRound(currentRound);
        
        for (var roundPattern in allRoundPatterns) {
          final roundPatternName = _getPatternName(roundPattern);
          final isManuallyCompleted = _manuallyMarkedPatterns[roundPatternName] ?? false;
          
          if (!isManuallyCompleted) {
            allPatternsCompleted = false;
            break;
          }
        }
        
        // Si todos los patrones están completados, marcar la ronda como completada
        if (allPatternsCompleted && !currentRound.isCompleted) {
          print('DEBUG: Ronda "${currentRound.name}" completada después de toggle manual');
          
          final updatedGame = _selectedGame!.copyWith();
          updatedGame.rounds[_currentRoundIndex] = updatedGame.rounds[_currentRoundIndex].copyWith(
            isCompleted: true,
          );
          
          // Avanzar automáticamente a la siguiente ronda si no es la última
          int newCurrentRoundIndex = _currentRoundIndex;
          if (_currentRoundIndex < updatedGame.rounds.length - 1) {
            newCurrentRoundIndex = _currentRoundIndex + 1;
          }
          
          if (mounted) {
            setState(() {
              _selectedGame = updatedGame;
            });
            
                         // Usar el método que actualiza la variable estática
             await _updateCurrentRoundIndex(newCurrentRoundIndex);
            
            // Mostrar notificación de ronda completada
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 ¡Ronda "${currentRound.name}" completada!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
      
      // Forzar la actualización del widget
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('DEBUG: Error al toggle manual de figura: $e');
    }
  }

  void _showEditRoundDialog(BuildContext context, BingoGameRound round, int roundIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _EditRoundDialog(
          round: round,
          onRoundUpdated: (updatedRound) {
            setState(() {
              _selectedGame!.rounds[roundIndex] = updatedRound;
            });
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Widget _buildEmptyRoundsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 40),
          const SizedBox(height: 10),
          Text(
            'No hay rondas definidas para este juego. ¡Agrega una para comenzar!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showCreateGameDialog(context),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Crear Nueva Ronda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _clearSavedData(context),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Limpiar Datos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}

// Diálogo para seleccionar un juego existente
class _GameSelectorDialog extends StatelessWidget {
  final BingoGameConfig? currentGame;
  final Function(BingoGameConfig) onGameSelected;

  const _GameSelectorDialog({
    required this.currentGame,
    required this.onGameSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Seleccionar Juego',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Lista de juegos disponibles
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: BingoGamePresets.defaultGames.length,
                itemBuilder: (context, index) {
                  final game = BingoGamePresets.defaultGames[index];
                  final isSelected = currentGame?.id == game.id;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.games,
                          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                        ),
                      ),
                      title: Text(
                        game.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue.shade700 : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${game.rounds.length} rondas',
                        style: TextStyle(
                          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                        ),
                      ),
                      onTap: () => onGameSelected(game),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPatternName(BingoPattern pattern) {
    switch (pattern) {
      case BingoPattern.diagonalPrincipal:
        return 'Diagonal Principal';
      case BingoPattern.diagonalSecundaria:
        return 'Diagonal Secundaria';
      case BingoPattern.lineaHorizontal:
        return 'Línea Horizontal';
      case BingoPattern.marcoCompleto:
        return 'Marco Completo';
      case BingoPattern.marcoPequeno:
        return 'Marco Pequeño';
      case BingoPattern.spoutnik:
        return 'Spoutnik';
      case BingoPattern.corazon:
        return 'Corazón';
      case BingoPattern.cartonLleno:
        return 'Cartón Lleno';
      case BingoPattern.consuelo:
        return 'Consuelo';
      case BingoPattern.x:
        return 'X';
      // Nuevas figuras legendarias
      case BingoPattern.relojArena:
        return 'Reloj de Arena';
      case BingoPattern.dobleLineaV:
        return 'Doble Línea V';
      case BingoPattern.figuraSuegra:
        return 'Figura la Suegra';
      case BingoPattern.figuraComodin:
        return 'Figura Comodín';
      case BingoPattern.letraFE:
        return 'Letra FE';
      case BingoPattern.figuraCLoca:
        return 'Figura C Loca';
      case BingoPattern.figuraBandera:
        return 'Figura Bandera';
      case BingoPattern.figuraTripleLinea:
        return 'Figura Triple Línea';
      case BingoPattern.diagonalDerecha:
        return 'Diagonal Derecha';
    }
  }
}

// Diálogo para crear un nuevo juego
class _CreateGameDialog extends StatefulWidget {
  final Function(BingoGameConfig) onGameCreated;

  const _CreateGameDialog({required this.onGameCreated});

  @override
  State<_CreateGameDialog> createState() => _CreateGameDialogState();
}

class _CreateGameDialogState extends State<_CreateGameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedDay = 'Lunes';
  final List<BingoGameRound> _rounds = [];
  
  final List<String> _availableDays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    // Agregar una ronda por defecto
    _addRound();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addRound() {
    setState(() {
      _rounds.add(BingoGameRound(
        id: 'ronda_${_rounds.length + 1}',
        name: 'Ronda ${_rounds.length + 1}',
        patterns: [BingoPattern.cartonLleno],
      ));
    });
  }

  void _removeRound(int index) {
    if (_rounds.length > 1) {
      setState(() {
        _rounds.removeAt(index);
      });
    }
  }

  void _updateRound(int index, BingoGameRound round) {
    setState(() {
      _rounds[index] = round;
    });
  }

  void _createGame() {
    if (_formKey.currentState!.validate() && _rounds.isNotEmpty) {
      final newGame = BingoGameConfig(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        date: _selectedDay,
        rounds: List.from(_rounds),
      );
      
      // Agregar el nuevo juego a la lista de presets
      BingoGamePresets.defaultGames.add(newGame);
      
      widget.onGameCreated(newGame);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.green.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Crear Nuevo Juego',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del juego
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Juego',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Día de la semana
                      DropdownButtonFormField<String>(
                        value: _selectedDay,
                        decoration: const InputDecoration(
                          labelText: 'Día de la Semana',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableDays.map((day) {
                          return DropdownMenuItem(
                            value: day,
                            child: Text(day),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedDay = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Título de las rondas
                      Row(
                        children: [
                          Text(
                            'Rondas del Juego',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _addRound,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Agregar Ronda'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Lista de rondas
                      ...(_rounds.asMap().entries.map((entry) {
                        final index = entry.key;
                        final round = entry.value;
                        return _RoundEditor(
                          round: round,
                          onUpdate: (updatedRound) => _updateRound(index, updatedRound),
                          onRemove: () => _removeRound(index),
                          canRemove: _rounds.length > 1,
                        );
                      }).toList()),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _createGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Crear Juego'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Editor de ronda individual
class _RoundEditor extends StatefulWidget {
  final BingoGameRound round;
  final Function(BingoGameRound) onUpdate;
  final VoidCallback onRemove;
  final bool canRemove;

  const _RoundEditor({
    required this.round,
    required this.onUpdate,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  State<_RoundEditor> createState() => _RoundEditorState();
}

class _RoundEditorState extends State<_RoundEditor> {
  late TextEditingController _nameController;
  late List<BingoPattern> _selectedPatterns;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.round.name);
    _selectedPatterns = List.from(widget.round.patterns);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateRound() {
    final updatedRound = widget.round.copyWith(
      name: _nameController.text.trim(),
      patterns: _selectedPatterns,
    );
    widget.onUpdate(updatedRound);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Ronda',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateRound(),
                  ),
                ),
                if (widget.canRemove) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(Icons.delete, color: Colors.red.shade600),
                    tooltip: 'Eliminar Ronda',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              'Patrones:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BingoPattern.values.map((pattern) {
                final isSelected = _selectedPatterns.contains(pattern);
                return FilterChip(
                  label: Text(_getPatternDisplayName(pattern)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPatterns.add(pattern);
                      } else {
                        _selectedPatterns.remove(pattern);
                      }
                    });
                    _updateRound();
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade600,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getPatternDisplayName(BingoPattern pattern) {
    switch (pattern) {
      case BingoPattern.diagonalPrincipal:
        return 'Diagonal Principal';
      case BingoPattern.diagonalSecundaria:
        return 'Diagonal Secundaria';
      case BingoPattern.lineaHorizontal:
        return 'Línea Horizontal';
      case BingoPattern.marcoCompleto:
        return 'Marco Completo';
      case BingoPattern.marcoPequeno:
        return 'Marco Pequeño';
      case BingoPattern.spoutnik:
        return 'Spoutnik';
      case BingoPattern.corazon:
        return 'Corazón';
      case BingoPattern.cartonLleno:
        return 'Cartón Lleno';
      case BingoPattern.consuelo:
        return 'Consuelo';
      case BingoPattern.x:
        return 'X';
      // Nuevas figuras legendarias
      case BingoPattern.relojArena:
        return 'Reloj de Arena';
      case BingoPattern.dobleLineaV:
        return 'Doble Línea V';
      case BingoPattern.figuraSuegra:
        return 'Figura la Suegra';
      case BingoPattern.figuraComodin:
        return 'Figura Comodín';
      case BingoPattern.letraFE:
        return 'Letra FE';
      case BingoPattern.figuraCLoca:
        return 'Figura C Loca';
      case BingoPattern.figuraBandera:
        return 'Figura Bandera';
      case BingoPattern.figuraTripleLinea:
        return 'Figura Triple Línea';
      case BingoPattern.diagonalDerecha:
        return 'Diagonal Derecha';
    }
  }
}

// Diálogo para editar un juego existente
class _EditGameDialog extends StatefulWidget {
  final BingoGameConfig game;
  final Function(BingoGameConfig) onGameUpdated;

  const _EditGameDialog({
    required this.game,
    required this.onGameUpdated,
  });

  @override
  State<_EditGameDialog> createState() => _EditGameDialogState();
}

class _EditGameDialogState extends State<_EditGameDialog> {
  late BingoGameConfig _editedGame;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String _selectedDay;
  late List<BingoGameRound> _rounds;
  
  final List<String> _availableDays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    // Crear una copia del juego para editar
    _editedGame = widget.game.copyWith();
    _nameController.text = _editedGame.name;
    _selectedDay = _editedGame.date;
    _rounds = List.from(_editedGame.rounds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addRound() {
    setState(() {
      _rounds.add(BingoGameRound(
        id: 'ronda_${_rounds.length + 1}_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Ronda ${_rounds.length + 1}',
        patterns: [BingoPattern.cartonLleno],
      ));
    });
  }

  void _removeRound(int index) {
    if (_rounds.length > 1) {
      setState(() {
        _rounds.removeAt(index);
      });
    }
  }

  void _updateRound(int index, BingoGameRound round) {
    setState(() {
      _rounds[index] = round;
    });
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate() && _rounds.isNotEmpty) {
      final updatedGame = _editedGame.copyWith(
        name: _nameController.text.trim(),
        date: _selectedDay,
        rounds: List.from(_rounds),
      );
      
      // Actualizar el juego en la lista de presets
      final gameIndex = BingoGamePresets.defaultGames.indexWhere((g) => g.id == widget.game.id);
      if (gameIndex != -1) {
        BingoGamePresets.defaultGames[gameIndex] = updatedGame;
      }
      
      widget.onGameUpdated(updatedGame);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Editar Juego: ${widget.game.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del juego
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Juego',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Día de la semana
                      DropdownButtonFormField<String>(
                        value: _selectedDay,
                        decoration: const InputDecoration(
                          labelText: 'Día de la Semana',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableDays.map((day) {
                          return DropdownMenuItem(
                            value: day,
                            child: Text(day),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedDay = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Título de las rondas
                      Row(
                        children: [
                          Text(
                            'Rondas del Juego (${_rounds.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _addRound,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Agregar Ronda'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Lista de rondas
                      ...(_rounds.asMap().entries.map((entry) {
                        final index = entry.key;
                        final round = entry.value;
                        return _RoundEditor(
                          round: round,
                          onUpdate: (updatedRound) => _updateRound(index, updatedRound),
                          onRemove: () => _removeRound(index),
                          canRemove: _rounds.length > 1,
                        );
                      }).toList()),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar Cambios'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 

// Diálogo para editar una ronda individual
class _EditRoundDialog extends StatefulWidget {
  final BingoGameRound round;
  final Function(BingoGameRound) onRoundUpdated;

  const _EditRoundDialog({
    required this.round,
    required this.onRoundUpdated,
  });

  @override
  State<_EditRoundDialog> createState() => _EditRoundDialogState();
}

class _EditRoundDialogState extends State<_EditRoundDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<BingoPattern> _selectedPatterns;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.round.name);
    _descriptionController = TextEditingController(text: widget.round.description ?? '');
    _selectedPatterns = List.from(widget.round.patterns);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_nameController.text.trim().isNotEmpty && _selectedPatterns.isNotEmpty) {
      final updatedRound = widget.round.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        patterns: List.from(_selectedPatterns),
      );
      
      widget.onRoundUpdated(updatedRound);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.orange.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Editar Ronda: ${widget.round.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre de la ronda
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Ronda',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Juego 1, Consuelo, etc.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Descripción de la ronda
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (Opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Descripción detallada de la ronda',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    
                    // Patrones de la ronda
                    Text(
                      'Patrones de la Ronda:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      'Selecciona las figuras que se deben completar para ganar esta ronda:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Grid de patrones seleccionables
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: BingoPattern.values.map((pattern) {
                        final isSelected = _selectedPatterns.contains(pattern);
                        return FilterChip(
                          label: Text(_getPatternDisplayName(pattern)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedPatterns.add(pattern);
                              } else {
                                _selectedPatterns.remove(pattern);
                              }
                            });
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: Colors.orange.shade100,
                          checkmarkColor: Colors.orange.shade600,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.orange.shade700 : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vista previa de la ronda
                    if (_selectedPatterns.isNotEmpty) ...[
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
                              'Vista Previa:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nombre: ${_nameController.text.trim().isEmpty ? "Sin nombre" : _nameController.text.trim()}',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Patrones: ${_selectedPatterns.map((p) => _getPatternDisplayName(p)).join(', ')}',
                              style: TextStyle(fontSize: 12),
                            ),
                            if (_descriptionController.text.trim().isNotEmpty)
                              Text(
                                'Descripción: ${_descriptionController.text.trim()}',
                                style: TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedPatterns.isNotEmpty && _nameController.text.trim().isNotEmpty
                      ? _saveChanges
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar Cambios'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPatternDisplayName(BingoPattern pattern) {
    switch (pattern) {
      case BingoPattern.diagonalPrincipal:
        return 'Diagonal Principal';
      case BingoPattern.diagonalSecundaria:
        return 'Diagonal Secundaria';
      case BingoPattern.lineaHorizontal:
        return 'Línea Horizontal';
      case BingoPattern.marcoCompleto:
        return 'Marco Completo';
      case BingoPattern.marcoPequeno:
        return 'Marco Pequeño';
      case BingoPattern.spoutnik:
        return 'Spoutnik';
      case BingoPattern.corazon:
        return 'Corazón';
      case BingoPattern.cartonLleno:
        return 'Cartón Lleno';
      case BingoPattern.consuelo:
        return 'Consuelo';
      case BingoPattern.x:
        return 'X';
      // Nuevas figuras legendarias
      case BingoPattern.relojArena:
        return 'Reloj de Arena';
      case BingoPattern.dobleLineaV:
        return 'Doble Línea V';
      case BingoPattern.figuraSuegra:
        return 'Figura la Suegra';
      case BingoPattern.figuraComodin:
        return 'Figura Comodín';
      case BingoPattern.letraFE:
        return 'Letra FE';
      case BingoPattern.figuraCLoca:
        return 'Figura C Loca';
      case BingoPattern.figuraBandera:
        return 'Figura Bandera';
      case BingoPattern.figuraTripleLinea:
        return 'Figura Triple Línea';
      case BingoPattern.diagonalDerecha:
        return 'Diagonal Derecha';
    }
  }
} 