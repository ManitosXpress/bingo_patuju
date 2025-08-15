import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bingo_game_config.dart';
import 'bingo_patterns_dialog.dart';
import '../models/bingo_game.dart';
import '../providers/app_provider.dart';

class BingoGamesPanel extends StatefulWidget {
  const BingoGamesPanel({super.key});

  @override
  State<BingoGamesPanel> createState() => _BingoGamesPanelState();
}

class _BingoGamesPanelState extends State<BingoGamesPanel> {
  BingoGameConfig? _selectedGame;
  int _currentRoundIndex = 0;
  
  // Mapa local para patrones marcados manualmente por el usuario
  final Map<String, bool> _manuallyMarkedPatterns = {};

  @override
  void initState() {
    super.initState();
    // Seleccionar el primer juego por defecto
    if (BingoGamePresets.defaultGames.isNotEmpty) {
      _selectedGame = BingoGamePresets.defaultGames.first;
    }
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
          onGameSelected: (game) {
            setState(() {
              _selectedGame = game;
              _currentRoundIndex = 0;
            });
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
          onGameCreated: (newGame) {
            setState(() {
              _selectedGame = newGame;
              _currentRoundIndex = 0;
            });
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
          onGameUpdated: (updatedGame) {
            setState(() {
              _selectedGame = updatedGame;
              _currentRoundIndex = 0;
            });
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _markCurrentRoundAsCompleted() {
    if (_selectedGame != null && _currentRoundIndex < _selectedGame!.rounds.length) {
      setState(() {
        _selectedGame!.rounds[_currentRoundIndex].isCompleted = true;
      });
      
      // Avanzar automáticamente a la siguiente ronda si no es la última
      if (_currentRoundIndex < _selectedGame!.rounds.length - 1) {
        setState(() {
          _currentRoundIndex++;
        });
      }
    }
  }

  void _resetGame() {
    if (_selectedGame != null) {
      setState(() {
        for (var round in _selectedGame!.rounds) {
          round.isCompleted = false;
        }
        _currentRoundIndex = 0;
      });
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

  // Método para verificar si una ronda se completó automáticamente
  bool _isRoundCompletedAutomatically(BingoGameRound round) {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final completedPatterns = appProvider.getCompletedPatterns();
      
      print('DEBUG: Verificando patrones completados para ronda "${round.name}"');
      print('DEBUG: Patrones de la ronda: ${round.patterns.map((p) => _getPatternName(p)).join(', ')}');
      
      // Verificar si todos los patrones de la ronda están completados
      for (var pattern in round.patterns) {
        final patternName = _getPatternName(pattern);
        final isCompleted = completedPatterns[patternName] ?? false;
        
        print('DEBUG: Patrón "$patternName" - Estado: ${isCompleted ? "COMPLETADO" : "NO COMPLETADO"}');
        
        if (!isCompleted) {
          print('DEBUG: Ronda "${round.name}" - Patrón "$patternName" NO está completado');
          return false;
        }
      }
      
      print('DEBUG: Ronda "${round.name}" - TODOS los patrones están completados');
      return true;
    } catch (e) {
      print('DEBUG: Error al verificar ronda "${round.name}": $e');
      return false;
    }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Comentado para permitir solo control manual del usuario
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   _checkAndUpdateRoundsAutomatically(appProvider);
        // });
        
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
                  ],
                ),
                const SizedBox(height: 12),
                
                // Botón para ver todas las figuras de bingo
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPatternsDialog(context),
                    icon: const Icon(Icons.grid_view, size: 16),
                    label: const Text(
                      'Ver Todas las Figuras de Bingo',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Información del juego seleccionado
                if (_selectedGame != null) ...[
                  _buildGameInfo(),
                  const SizedBox(height: 8),
                  
                  // Lista de rondas - Hacer flexible
                  Expanded(
                    child: _buildRoundsList(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Indicador de figuras necesarias para la ronda actual
                  if (!_isGameCompleted && _selectedGame != null && _currentRoundIndex < _selectedGame!.rounds.length)
                    _buildCurrentRoundInfo(),
                  
                  const SizedBox(height: 8),
                  
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

  void _checkAndUpdateRoundsAutomatically(AppProvider appProvider) {
    if (_selectedGame == null || !mounted) return;
    
    // Solo verificar la ronda actual, no todas las rondas
    if (_currentRoundIndex < _selectedGame!.rounds.length) {
      final currentRound = _selectedGame!.rounds[_currentRoundIndex];
      
      print('DEBUG: Verificando ronda actual: "${currentRound.name}" (índice: $_currentRoundIndex)');
      print('DEBUG: Estado actual de la ronda: ${currentRound.isCompleted ? "COMPLETADA" : "PENDIENTE"}');
      
      // Solo marcar como completada si NO está ya completada y si todas sus figuras están completadas
      if (!currentRound.isCompleted && _isRoundCompletedAutomatically(currentRound)) {
        print('DEBUG: Marcando ronda "${currentRound.name}" como completada automáticamente');
        
        // Crear una copia del juego para evitar mutaciones directas
        final updatedGame = _selectedGame!.copyWith();
        updatedGame.rounds[_currentRoundIndex] = updatedGame.rounds[_currentRoundIndex].copyWith(
          isCompleted: true,
        );
        
        // Avanzar automáticamente a la siguiente ronda si no es la última
        int newCurrentRoundIndex = _currentRoundIndex;
        if (_currentRoundIndex < updatedGame.rounds.length - 1) {
          print('DEBUG: Avanzando automáticamente a la siguiente ronda');
          newCurrentRoundIndex = _currentRoundIndex + 1;
        } else {
          print('DEBUG: Última ronda completada - Juego terminado');
        }
        
        // Actualizar el estado de manera segura
        if (mounted) {
          setState(() {
            _selectedGame = updatedGame;
            _currentRoundIndex = newCurrentRoundIndex;
          });
        }
      } else {
        print('DEBUG: Ronda "${currentRound.name}" no cumple condiciones para completarse automáticamente');
      }
    }
  }

  Widget _buildGameInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isGameCompleted ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 4),
          Text(
            'Fecha: ${_selectedGame!.date}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
          ),
          Text(
            'Total de Rondas: ${_selectedGame!.rounds.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
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
            child: ListView.builder(
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
                    onTap: isCompleted ? null : () {
                      setState(() {
                        _currentRoundIndex = index;
                      });
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

  Widget _buildGameControls() {
    return Column(
      mainAxisSize: MainAxisSize.min, // No expandir más del necesario
      children: [
        // Controles de navegación
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _currentRoundIndex > 0
                  ? () {
                      setState(() {
                        _currentRoundIndex--;
                      });
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
                  ? () {
                      setState(() {
                        _currentRoundIndex++;
                      });
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
                padding: const EdgeInsets.symmetric(vertical: 6), // Reducir padding
                minimumSize: const Size(0, 32), // Reducir altura
              ),
            ),
          ),
        
        // Botón para reiniciar el juego
        if (_isGameCompleted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetGame,
              icon: const Icon(Icons.refresh, size: 14), // Reducir tamaño
              label: const Text('Reiniciar Juego', style: TextStyle(fontSize: 11)), // Reducir tamaño
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6), // Reducir padding
                minimumSize: const Size(0, 32), // Reducir altura
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
          
          // Mostrar cada figura individualmente con botón de toggle manual
          ...round.patterns.map((pattern) {
            final patternName = _getPatternDisplayName(pattern);
            final isCompleted = _manuallyMarkedPatterns[_getPatternName(pattern)] ?? false;
            
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
                  // Indicador de estado manual
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
          }).toList(),
          
          // Mostrar progreso general
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.yellow.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
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
                  '${round.patterns.where((p) => _manuallyMarkedPatterns[_getPatternName(p)] ?? false).length}/${round.patterns.length} figuras tachadas',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow.shade800,
                  ),
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

  void _toggleFigureManually(BingoPattern pattern, bool isCompleted) {
    try {
      final patternName = _getPatternName(pattern);
      
      print('DEBUG: Toggle manual de figura "$patternName" a estado: $isCompleted');
      
      // Actualizar el estado en el mapa local
      _manuallyMarkedPatterns[patternName] = isCompleted;
      
      print('DEBUG: Figura "$patternName" actualizada manualmente');
      
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
    }
  }
} 