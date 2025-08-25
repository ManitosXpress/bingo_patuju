import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bingo_game.dart';
import '../providers/app_provider.dart';
import '../models/bingo_game_config.dart';

class BingoPatternsDialog extends StatelessWidget {
  final BingoGame bingoGame;
  final BingoGameRound? currentRound; // Nueva propiedad para mostrar solo figuras de una ronda
  
  const BingoPatternsDialog({
    super.key,
    required this.bingoGame,
    this.currentRound, // Opcional: si se pasa, solo muestra las figuras de esa ronda
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final completed = appProvider.getCompletedPatterns();
        final probs = _conditionalPatternProbabilities(completed);
        
        // Filtrar patrones si se especifica una ronda actual
        final patternsToShow = currentRound != null 
            ? _getPatternsForRound(currentRound!)
            : _getAllPatterns();
        
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentRound != null 
                                ? 'Figuras de "${currentRound!.name}"'
                                : 'Todas las Figuras de Bingo',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          if (currentRound != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Ronda actual del juego',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Patterns list (changed from grid to list)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate grid size based on available space
                      final availableWidth = constraints.maxWidth;
                      
                      // Use full width for better visibility
                      final gridSize = (availableWidth * 0.15).clamp(50.0, 80.0);
                      final cellSize = gridSize / 5.5;
                      
                      return ListView.builder(
                        itemCount: patternsToShow.length,
                        itemBuilder: (context, index) {
                          final pattern = patternsToShow[index];
                          final patternName = pattern['name'] as String;
                          final patternMatrix = pattern['matrix'] as List<List<int>>;
                          final probability = probs[patternName] ?? '0.00%';
                          final isCompleted = completed[patternName] ?? false;
                          
                          // Resaltar si es parte de la ronda actual
                          final isCurrentRoundPattern = currentRound != null && 
                              currentRound!.patterns.any((p) => _getPatternName(p) == patternName);
                          
                          return _buildPatternListItem(
                            context,
                            patternName,
                            patternMatrix,
                            probability,
                            isCompleted,
                            gridSize,
                            cellSize,
                            isCurrentRoundPattern: isCurrentRoundPattern,
                          );
                        },
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Footer info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentRound != null
                            ? 'Figuras de la ronda actual resaltadas en azul. Probabilidad de que cada figura sea la próxima en salir (se actualiza en tiempo real).'
                            : 'Probabilidad de que cada figura sea la próxima en salir (se actualiza en tiempo real).',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (currentRound != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Ronda: ${currentRound!.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          'Patrones: ${currentRound!.patternsDisplay}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getAllPatterns() {
    return [
      {'name': 'Línea Horizontal', 'matrix': _horizontalPattern()},
      {'name': 'Línea Vertical', 'matrix': _verticalPattern()},
      {'name': 'Diagonal Principal', 'matrix': _mainDiagonalPattern()},
      {'name': 'Diagonal Secundaria', 'matrix': _antiDiagonalPattern()},
      {'name': 'Cartón Lleno', 'matrix': _fullCardPattern()},
      {'name': '5 Casillas Diagonales', 'matrix': _diagonal5Pattern()},
      {'name': 'X', 'matrix': _xPattern()},
      {'name': 'Marco Completo', 'matrix': _fullFramePattern()},
      {'name': 'Corazón', 'matrix': _heartPattern()},
      {'name': 'Caída de Nieve', 'matrix': _snowfallPattern()},
      {'name': 'Marco Pequeño', 'matrix': _smallFramePattern()},
      {'name': 'Árbol o Flecha', 'matrix': _treeArrowPattern()},
      {'name': 'Spoutnik', 'matrix': _spoutnikPattern()},
      {'name': 'ING', 'matrix': _ingPattern()},
      {'name': 'NGO', 'matrix': _ngoPattern()},
      {'name': 'Autopista', 'matrix': _highwayPattern()},
    ];
  }

  Widget _buildPatternListItem(
    BuildContext context,
    String name,
    List<List<int>> pattern,
    String probability,
    bool completed,
    double gridSize,
    double cellSize,
    {bool isCurrentRoundPattern = false}
  ) {
    String displayProbability = completed ? 'COMPLETADO ✓' : probability;
    
    // Determinar colores basados en el estado
    Color borderColor;
    Color? backgroundColor;
    
    if (completed) {
      borderColor = Colors.green.shade400;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (isCurrentRoundPattern) {
      borderColor = Colors.blue.shade400;
      backgroundColor = Colors.blue.withOpacity(0.1);
    } else {
      borderColor = Colors.grey.shade300;
      backgroundColor = Colors.white;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor, 
          width: completed || isCurrentRoundPattern ? 2 : 1
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Pattern visualization
            Container(
              width: gridSize,
              height: gridSize,
              child: _patternMiniGrid(
                pattern, 
                completed ? Colors.green : (isCurrentRoundPattern ? Colors.blue : Colors.grey), 
                gridSize, 
                cellSize
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Pattern info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pattern name
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: completed 
                        ? Colors.green.shade700 
                        : (isCurrentRoundPattern ? Colors.blue.shade700 : Colors.black87),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Pattern description
                  Text(
                    _getPatternDescription(name),
                    style: TextStyle(
                      fontSize: 14,
                      color: completed 
                        ? Colors.green.shade600 
                        : (isCurrentRoundPattern ? Colors.blue.shade600 : Colors.grey.shade600),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  
                  // Indicador de ronda actual
                  if (isCurrentRoundPattern && !completed) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ronda Actual',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Probability or completion status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: completed 
                  ? Colors.green.shade100 
                  : (isCurrentRoundPattern ? Colors.blue.shade100 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: completed 
                    ? Colors.green.shade300 
                    : (isCurrentRoundPattern ? Colors.blue.shade300 : Colors.grey.shade300),
                ),
              ),
              child: Text(
                displayProbability,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: completed 
                    ? Colors.green.shade700 
                    : (isCurrentRoundPattern ? Colors.blue.shade700 : Colors.grey.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPatternDescription(String patternName) {
    switch (patternName) {
      case 'Línea Horizontal':
        return 'Completar cualquier fila horizontal del cartón';
      case 'Línea Vertical':
        return 'Completar cualquier columna vertical del cartón';
      case 'Diagonal Principal':
        return 'Completar la diagonal desde la esquina superior izquierda';
      case 'Diagonal Secundaria':
        return 'Completar la diagonal desde la esquina superior derecha';
      case 'Cartón Lleno':
        return 'Completar todas las casillas del cartón';
      case '5 Casillas Diagonales':
        return 'Completar 5 casillas en forma diagonal';
      case 'X':
        return 'Completar las casillas que forman una X en el cartón';
      case 'Marco Completo':
        return 'Completar todo el borde del cartón';
      case 'Corazón':
        return 'Completar las casillas que forman un corazón';
      case 'Caída de Nieve':
        return 'Completar las casillas en forma de copo de nieve';
      case 'Marco Pequeño':
        return 'Completar un marco interior más pequeño';
      case 'Árbol o Flecha':
        return 'Completar las casillas que forman un árbol o flecha';
      case 'Spoutnik':
        return 'Completar las casillas en forma de satélite';
      case 'ING':
        return 'Completar las casillas que forman las letras ING';
      case 'NGO':
        return 'Completar las casillas que forman las letras NGO';
      case 'Autopista':
        return 'Completar las casillas en forma de autopista';
      default:
        return 'Patrón de bingo personalizado';
    }
  }

  Widget _patternMiniGrid(List<List<int>> pattern, Color color, double gridSize, double cellSize) {
    return Container(
      width: gridSize,
      height: gridSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (col) {
              bool isActive = pattern[row][col] == 1;
              return Container(
                width: cellSize,
                height: cellSize,
                margin: const EdgeInsets.all(0.5),
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.grey.shade400, width: 0.5),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Map<String, String> _conditionalPatternProbabilities(Map<String, bool> completed) {
    // Analizar las cartillas para calcular probabilidades reales
    final patternCounts = <String, int>{};
    final totalCards = bingoGame.cartillas.length;
    
    // Inicializar contadores
    final patterns = [
      'Línea Horizontal', 'Línea Vertical', 'Diagonal Principal', 'Diagonal Secundaria',
      'Cartón Lleno', '5 Casillas Diagonales', 'X', 'Marco Completo', 'Corazón',
      'Caída de Nieve', 'Marco Pequeño', 'Árbol o Flecha', 'Spoutnik', 'ING', 'NGO', 'Autopista'
    ];
    
    for (String pattern in patterns) {
      patternCounts[pattern] = 0;
    }
    
    // Si no se han llamado números, calcular probabilidades iniciales
    if (bingoGame.calledNumbers.isEmpty) {
      return _calculateInitialProbabilities(completed);
    }
    
    // Contar cuántas cartillas pueden lograr cada patrón con los números llamados
    for (var cartilla in bingoGame.cartillas) {
      for (String pattern in patterns) {
        if (_canAchievePattern(cartilla, bingoGame.calledNumbers, pattern)) {
          patternCounts[pattern] = (patternCounts[pattern] ?? 0) + 1;
        }
      }
    }
    
    // Calcular probabilidades
    final result = <String, String>{};
    for (String pattern in patterns) {
      if (completed[pattern] == true) {
        result[pattern] = 'COMPLETADO ✓';
      } else {
        int count = patternCounts[pattern] ?? 0;
        double probability = totalCards > 0 ? (count / totalCards) * 100 : 0.0;
        result[pattern] = probability.toStringAsFixed(2) + '%';
      }
    }
    
    return result;
  }

  Map<String, String> _calculateInitialProbabilities(Map<String, bool> completed) {
    final initialProbabilities = {
      'Línea Horizontal': 20.0,
      'Línea Vertical': 20.0,
      'Diagonal Principal': 2.0,
      'Diagonal Secundaria': 2.0,
      'Cartón Lleno': 0.1,
      '5 Casillas Diagonales': 8.0,
      'X': 8.0,
      'Marco Completo': 15.0,
      'Corazón': 12.0,
      'Caída de Nieve': 10.0,
      'Marco Pequeño': 18.0,
      'Árbol o Flecha': 14.0,
      'Spoutnik': 6.0,
      'ING': 16.0,
      'NGO': 16.0,
      'Autopista': 22.0,
    };
    
    final result = <String, String>{};
    for (String pattern in initialProbabilities.keys) {
      if (completed[pattern] == true) {
        result[pattern] = '99.50%';
      } else {
        result[pattern] = initialProbabilities[pattern]!.toStringAsFixed(2) + '%';
      }
    }
    
    return result;
  }

  bool _canAchievePattern(List<List<int>> cartilla, List<int> calledNumbers, String patternName) {
    switch (patternName) {
      case 'Línea Horizontal':
        return _canAchieveHorizontal(cartilla, calledNumbers);
      case 'Línea Vertical':
        return _canAchieveVertical(cartilla, calledNumbers);
      case 'Diagonal Principal':
        return _canAchieveMainDiagonal(cartilla, calledNumbers);
      case 'Diagonal Secundaria':
        return _canAchieveAntiDiagonal(cartilla, calledNumbers);
      case 'Cartón Lleno':
        return _canAchieveFullCard(cartilla, calledNumbers);
      default:
        return _canAchieveCustomPattern(cartilla, calledNumbers, _getPatternMatrix(patternName));
    }
  }

  List<List<int>> _getPatternMatrix(String patternName) {
    switch (patternName) {
      case '5 Casillas Diagonales':
        return _diagonal5Pattern();
      case 'X':
        return _xPattern();
      case 'Marco Completo':
        return _fullFramePattern();
      case 'Corazón':
        return _heartPattern();
      case 'Caída de Nieve':
        return _snowfallPattern();
      case 'Marco Pequeño':
        return _smallFramePattern();
      case 'Árbol o Flecha':
        return _treeArrowPattern();
      case 'Spoutnik':
        return _spoutnikPattern();
      case 'ING':
        return _ingPattern();
      case 'NGO':
        return _ngoPattern();
      case 'Autopista':
        return _highwayPattern();
      default:
        return List.generate(5, (_) => List.filled(5, 0));
    }
  }

  bool _canAchieveHorizontal(List<List<int>> cartilla, List<int> calledNumbers) {
    for (int row = 0; row < 5; row++) {
      bool rowComplete = true;
      for (int col = 0; col < 5; col++) {
        if (cartilla[row][col] != 0 && !calledNumbers.contains(cartilla[row][col])) {
          rowComplete = false;
          break;
        }
      }
      if (rowComplete) return true;
    }
    return false;
  }

  bool _canAchieveVertical(List<List<int>> cartilla, List<int> calledNumbers) {
    for (int col = 0; col < 5; col++) {
      bool colComplete = true;
      for (int row = 0; row < 5; row++) {
        if (cartilla[row][col] != 0 && !calledNumbers.contains(cartilla[row][col])) {
          colComplete = false;
          break;
        }
      }
      if (colComplete) return true;
    }
    return false;
  }

  bool _canAchieveMainDiagonal(List<List<int>> cartilla, List<int> calledNumbers) {
    for (int i = 0; i < 5; i++) {
      if (cartilla[i][i] != 0 && !calledNumbers.contains(cartilla[i][i])) {
        return false;
      }
    }
    return true;
  }

  bool _canAchieveAntiDiagonal(List<List<int>> cartilla, List<int> calledNumbers) {
    for (int i = 0; i < 5; i++) {
      if (cartilla[i][4-i] != 0 && !calledNumbers.contains(cartilla[i][4-i])) {
        return false;
      }
    }
    return true;
  }

  bool _canAchieveFullCard(List<List<int>> cartilla, List<int> calledNumbers) {
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        if (cartilla[row][col] != 0 && !calledNumbers.contains(cartilla[row][col])) {
          return false;
        }
      }
    }
    return true;
  }

  bool _canAchieveCustomPattern(List<List<int>> cartilla, List<int> calledNumbers, List<List<int>> pattern) {
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        if (pattern[row][col] == 1) {
          if (cartilla[row][col] != 0 && !calledNumbers.contains(cartilla[row][col])) {
            return false;
          }
        }
      }
    }
    return true;
  }

  // Pattern definitions
  List<List<int>> _horizontalPattern() {
    return [
      [1,1,1,1,1],
      [0,0,0,0,0],
      [0,0,0,0,0],
      [0,0,0,0,0],
      [0,0,0,0,0],
    ];
  }
  
  List<List<int>> _verticalPattern() {
    return [
      [1,0,0,0,0],
      [1,0,0,0,0],
      [1,0,0,0,0],
      [1,0,0,0,0],
      [1,0,0,0,0],
    ];
  }
  
  List<List<int>> _mainDiagonalPattern() {
    return [
      [1,0,0,0,0],
      [0,1,0,0,0],
      [0,0,1,0,0],
      [0,0,0,1,0],
      [0,0,0,0,1],
    ];
  }
  
  List<List<int>> _antiDiagonalPattern() {
    return [
      [0,0,0,0,1],
      [0,0,0,1,0],
      [0,0,1,0,0],
      [0,1,0,0,0],
      [1,0,0,0,0],
    ];
  }
  
  List<List<int>> _fullCardPattern() {
    return List.generate(5, (_) => List.filled(5, 1));
  }
  
  List<List<int>> _diagonal5Pattern() {
    return [
      [1,0,0,0,1],
      [0,1,0,1,0],
      [0,0,1,0,0],
      [0,1,0,1,0],
      [1,0,0,0,1],
    ];
  }
  
  List<List<int>> _xPattern() {
    return [
      [1,0,0,0,1],
      [0,1,0,1,0],
      [0,0,1,0,0],
      [0,1,0,1,0],
      [1,0,0,0,1],
    ];
  }
  
  List<List<int>> _fullFramePattern() {
    return [
      [1,1,1,1,1],
      [1,0,0,0,1],
      [1,0,0,0,1],
      [1,0,0,0,1],
      [1,1,1,1,1],
    ];
  }
  
  List<List<int>> _heartPattern() {
    return [
      [0,1,0,1,0],
      [1,0,1,0,1],
      [1,0,0,0,1],
      [0,1,0,1,0],
      [0,0,1,0,0],
    ];
  }
  
  List<List<int>> _snowfallPattern() {
    return [
      [0,0,1,0,0],
      [0,1,0,1,0],
      [1,0,1,0,1],
      [0,1,0,1,0],
      [0,0,1,0,0],
    ];
  }
  
  List<List<int>> _smallFramePattern() {
    return [
      [0,0,0,0,0],
      [0,1,1,1,0],
      [0,1,0,1,0],
      [0,1,1,1,0],
      [0,0,0,0,0],
    ];
  }
  
  List<List<int>> _treeArrowPattern() {
    return [
      [0,0,1,0,0],
      [0,1,1,1,0],
      [1,1,1,1,1],
      [0,0,0,0,0],
      [0,0,0,0,0],
    ];
  }
  
  List<List<int>> _spoutnikPattern() {
    return [
      [1,0,0,0,1],
      [0,0,1,0,0],
      [0,1,0,1,0],
      [0,0,1,0,0],
      [1,0,0,0,1],
    ];
  }
  
  List<List<int>> _ingPattern() {
    return [
      [0,1,1,1,0],
      [0,0,1,0,0],
      [0,0,1,0,0],
      [0,0,1,0,0],
      [0,1,1,1,0],
    ];
  }
  
  List<List<int>> _ngoPattern() {
    return [
      [1,0,0,0,1],
      [1,1,0,0,1],
      [1,0,1,0,1],
      [1,0,0,1,1],
      [1,0,0,0,1],
    ];
  }
  
  List<List<int>> _highwayPattern() {
    return [
      [0,1,0,1,0],
      [0,1,0,1,0],
      [0,1,0,1,0],
      [0,1,0,1,0],
      [0,1,0,1,0],
    ];
  }

  // Método para obtener solo los patrones de una ronda específica
  // Mantiene el orden original de los patrones en la ronda
  // Con reglas especiales: Cartón Lleno siempre penúltimo, Consuelo siempre último
  List<Map<String, dynamic>> _getPatternsForRound(BingoGameRound round) {
    final allPatterns = _getAllPatterns();
    final patternsMap = <String, Map<String, dynamic>>{};
    
    // Crear un mapa de todos los patrones disponibles
    for (final pattern in allPatterns) {
      patternsMap[pattern['name'] as String] = pattern;
    }
    
    // Construir la lista en el orden de la ronda
    final orderedPatterns = <Map<String, dynamic>>[];
    final cartonLlenoPattern = <Map<String, dynamic>>[];
    final consueloPattern = <Map<String, dynamic>>[];
    
    for (final roundPattern in round.patterns) {
      final patternName = _getPatternName(roundPattern);
      if (patternsMap.containsKey(patternName)) {
        final pattern = patternsMap[patternName]!;
        
        // Separar Cartón Lleno y Consuelo para posicionarlos al final
        if (patternName == 'Cartón Lleno') {
          cartonLlenoPattern.add(pattern);
        } else if (patternName == 'Consuelo') {
          consueloPattern.add(pattern);
        } else {
          // Agregar otros patrones en su orden normal
          orderedPatterns.add(pattern);
        }
      }
    }
    
    // Agregar Cartón Lleno de penúltimo (si existe)
    if (cartonLlenoPattern.isNotEmpty) {
      orderedPatterns.addAll(cartonLlenoPattern);
    }
    
    // Agregar Consuelo de último (si existe)
    if (consueloPattern.isNotEmpty) {
      orderedPatterns.addAll(consueloPattern);
    }
    
    return orderedPatterns;
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