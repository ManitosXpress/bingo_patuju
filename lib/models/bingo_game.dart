import 'dart:math';

class BingoGame {
  List<int> allNumbers = List.generate(75, (index) => index + 1);
  List<int> calledNumbers = [];
  List<int> availableNumbers = List.generate(75, (index) => index + 1);
  List<List<List<int>>> cartillas = [];
  // Nuevo campo para rastrear asignaciones
  Map<String, String> cartillaAssignments = {}; // cardKey -> vendorId
  int currentBall = 0;
  final Random random = Random();

  BingoGame() {
    // No generar cartillas por defecto - se cargarán desde Firebase
    // generateCartillas(500); // Comentado para usar solo cartillas de Firebase
  }

  // Método para obtener la clave única de una cartilla
  String getCardKey(List<List<int>> cartilla) {
    return cartilla.expand((row) => row).join(',');
  }

  // Método para asignar una cartilla a un vendedor
  void assignCartilla(List<List<int>> cartilla, String vendorId) {
    final key = getCardKey(cartilla);
    cartillaAssignments[key] = vendorId;
  }

  // Método para desasignar una cartilla
  void unassignCartilla(List<List<int>> cartilla) {
    final key = getCardKey(cartilla);
    cartillaAssignments.remove(key);
  }

  // Método para verificar si una cartilla está asignada
  bool isCartillaAssigned(List<List<int>> cartilla) {
    final key = getCardKey(cartilla);
    return cartillaAssignments.containsKey(key);
  }

  // Método para obtener el vendedor asignado a una cartilla
  String? getAssignedVendor(List<List<int>> cartilla) {
    final key = getCardKey(cartilla);
    return cartillaAssignments[key];
  }

  // Método para obtener todas las cartillas asignadas a un vendedor
  List<List<List<int>>> getCartillasByVendor(String vendorId) {
    return cartillas.where((cartilla) {
      final key = getCardKey(cartilla);
      return cartillaAssignments[key] == vendorId;
    }).toList();
  }

  // Método para obtener el conteo de cartillas por estado
  Map<String, int> getCartillaStatusCount() {
    int total = cartillas.length;
    int assigned = cartillaAssignments.length;
    int unassigned = total - assigned;
    
    return {
      'total': total,
      'assigned': assigned,
      'unassigned': unassigned,
    };
  }

  void generateCartillas(int count) {
    cartillas.clear();
    final Set<String> uniqueCartillas = {};
    while (cartillas.length < count) {
      final c = generateSingleCartilla();
      final key = c.expand((row) => row).join(',');
      if (!uniqueCartillas.contains(key)) {
        cartillas.add(c);
        uniqueCartillas.add(key);
      }
    }
  }

  List<List<int>> generateSingleCartilla() {
    List<List<int>> cartilla = List.generate(5, (index) => List.filled(5, 0));
    
    // Generar números para cada columna según las reglas del bingo
    for (int col = 0; col < 5; col++) {
      List<int> columnNumbers = [];
      int startNum = col * 15 + 1;
      int endNum = (col + 1) * 15;
      
      // Generar 5 números únicos para esta columna
      while (columnNumbers.length < 5) {
        int num = random.nextInt(endNum - startNum + 1) + startNum;
        if (!columnNumbers.contains(num)) {
          columnNumbers.add(num);
        }
      }
      
      // Colocar los números en la columna
      for (int row = 0; row < 5; row++) {
        cartilla[row][col] = columnNumbers[row];
      }
    }
    
    // El centro es libre (número 0)
    cartilla[2][2] = 0;
    
    return cartilla;
  }

  void callNextBall() {
    if (availableNumbers.isNotEmpty) {
      int randomIndex = random.nextInt(availableNumbers.length);
      int ball = availableNumbers[randomIndex];
      
      currentBall = ball;
      calledNumbers.add(ball);
      availableNumbers.removeAt(randomIndex);
    }
  }

  void resetGame() {
    calledNumbers.clear();
    availableNumbers = List.generate(75, (index) => index + 1);
    currentBall = 0;
    // No generar nuevas cartillas al resetear - mantener las de Firebase
    // generateCartillas(500); // Comentado para usar solo cartillas de Firebase
  }

  // Método para sincronizar cartillas desde Firebase
  void syncCartillasFromFirebase(List<List<List<int>>> firebaseCartillas) {
    print('DEBUG: Sincronizando ${firebaseCartillas.length} cartillas desde Firebase');
    
    cartillas.clear();
    cartillas.addAll(firebaseCartillas);
    
    // Validar y corregir cartillas para asegurar correlación con letras BINGO
    for (int i = 0; i < cartillas.length; i++) {
      cartillas[i] = _validateAndCorrectCartilla(cartillas[i]);
    }
    
    // Limpiar asignaciones que ya no existen
    final existingKeys = cartillas.map((c) => getCardKey(c)).toSet();
    cartillaAssignments.removeWhere((key, _) => !existingKeys.contains(key));
    
    print('DEBUG: Cartillas sincronizadas y validadas: ${cartillas.length}');
    print('DEBUG: Números llamados actuales: ${calledNumbers.length}');
    
    // Verificar si hay patrones completados después de la sincronización
    if (calledNumbers.isNotEmpty) {
      final completedPatterns = getCompletedPatterns(calledNumbers);
      final completedCount = completedPatterns.values.where((completed) => completed).length;
      print('DEBUG: Patrones completados después de sincronización: $completedCount');
    }
  }

  // Método para validar y corregir una cartilla según las reglas del BINGO
  List<List<int>> _validateAndCorrectCartilla(List<List<int>> cartilla) {
    List<List<int>> correctedCartilla = List.generate(5, (index) => List.filled(5, 0));
    
    // Copiar la cartilla original
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        correctedCartilla[row][col] = cartilla[row][col];
      }
    }
    
    // Validar y corregir cada columna según las reglas del BINGO
    for (int col = 0; col < 5; col++) {
      int startNum = col * 15 + 1;
      int endNum = (col + 1) * 15;
      
      // Verificar que cada número en la columna esté en el rango correcto
      for (int row = 0; row < 5; row++) {
        int currentNum = correctedCartilla[row][col];
        
        // Si es el centro (libre), mantenerlo como 0
        if (row == 2 && col == 2) {
          correctedCartilla[row][col] = 0;
          continue;
        }
        
        // Si el número no está en el rango correcto, generar uno nuevo
        if (currentNum < startNum || currentNum > endNum) {
          // Generar un número válido para esta columna
          int newNum;
          do {
            newNum = random.nextInt(endNum - startNum + 1) + startNum;
          } while (_isNumberInColumn(correctedCartilla, col, newNum));
          
          correctedCartilla[row][col] = newNum;
        }
      }
    }
    
    return correctedCartilla;
  }

  // Método helper para verificar si un número ya existe en una columna
  bool _isNumberInColumn(List<List<int>> cartilla, int col, int number) {
    for (int row = 0; row < 5; row++) {
      if (cartilla[row][col] == number) {
        return true;
      }
    }
    return false;
  }

  void shuffleNumbers() {
    availableNumbers.shuffle(random);
  }

  bool checkBingo(List<List<int>> cartilla) {
    // Verificar filas
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

    // Verificar columnas
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

    // Verificar diagonales
    bool diagonal1Complete = true;
    bool diagonal2Complete = true;
    
    for (int i = 0; i < 5; i++) {
      if (cartilla[i][i] != 0 && !calledNumbers.contains(cartilla[i][i])) {
        diagonal1Complete = false;
      }
      if (cartilla[i][4-i] != 0 && !calledNumbers.contains(cartilla[i][4-i])) {
        diagonal2Complete = false;
      }
    }
    
    return diagonal1Complete || diagonal2Complete;
  }

  bool isNumberCalled(int number) {
    return calledNumbers.contains(number);
  }

  int get currentBallNumber => currentBall;
  int get totalCalledNumbers => calledNumbers.length;
  int get remainingNumbers => availableNumbers.length;
  int get totalCartillas => cartillas.length;

  /// Devuelve el nombre de la figura lograda o null si no hay bingo
  String? getBingoPattern(List<List<int>> cartilla, List<int> calledNumbers) {
    // Horizontal
    for (int row = 0; row < 5; row++) {
      bool rowComplete = true;
      for (int col = 0; col < 5; col++) {
        if (cartilla[row][col] != 0 && !calledNumbers.contains(cartilla[row][col])) {
          rowComplete = false;
          break;
        }
      }
      if (rowComplete) return 'Línea Horizontal';
    }
    // Vertical
    for (int col = 0; col < 5; col++) {
      bool colComplete = true;
      for (int row = 0; row < 5; row++) {
        if (cartilla[row][col] != 0 && !calledNumbers.contains(cartilla[row][col])) {
          colComplete = false;
          break;
        }
      }
      if (colComplete) return 'Línea Vertical';
    }
    // Diagonal principal
    bool diagonal1Complete = true;
    for (int i = 0; i < 5; i++) {
      if (cartilla[i][i] != 0 && !calledNumbers.contains(cartilla[i][i])) {
        diagonal1Complete = false;
      }
    }
    if (diagonal1Complete) return 'Diagonal Principal';
    // Diagonal secundaria
    bool diagonal2Complete = true;
    for (int i = 0; i < 5; i++) {
      if (cartilla[i][4-i] != 0 && !calledNumbers.contains(cartilla[i][4-i])) {
        diagonal2Complete = false;
      }
    }
    if (diagonal2Complete) return 'Diagonal Secundaria';
    // Cartón lleno
    bool full = true;
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        if (cartilla[row][col] != 0 && !calledNumbers.contains(cartilla[row][col])) {
          full = false;
        }
      }
    }
    if (full) return 'Cartón Lleno';
    
    // Nuevos patrones
    if (_checkPattern(cartilla, calledNumbers, _diagonal5Pattern())) return '5 Casillas Diagonales';
    if (_checkPattern(cartilla, calledNumbers, _xPattern())) return 'X';
    if (_checkPattern(cartilla, calledNumbers, _fullFramePattern())) return 'Marco Completo';
    if (_checkPattern(cartilla, calledNumbers, _heartPattern())) return 'Corazón';
    if (_checkPattern(cartilla, calledNumbers, _snowfallPattern())) return 'Caída de Nieve';
    if (_checkPattern(cartilla, calledNumbers, _smallFramePattern())) return 'Marco Pequeño';
    if (_checkPattern(cartilla, calledNumbers, _treeArrowPattern())) return 'Árbol o Flecha';
    if (_checkPattern(cartilla, calledNumbers, _spoutnikPattern())) return 'Spoutnik';
    if (_checkPattern(cartilla, calledNumbers, _ingPattern())) return 'ING';
    if (_checkPattern(cartilla, calledNumbers, _ngoPattern())) return 'NGO';
    if (_checkPattern(cartilla, calledNumbers, _highwayPattern())) return 'Autopista';
    
    return null;
  }

  /// Verifica si un patrón específico está completo
  bool _checkPattern(List<List<int>> cartilla, List<int> calledNumbers, List<List<int>> pattern) {
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

  /// Devuelve un mapa con las figuras completadas en las cartillas actuales
  Map<String, bool> getCompletedPatterns(List<int> calledNumbers) {
    bool horizontal = false;
    bool vertical = false;
    bool diagMain = false;
    bool diagAnti = false;
    bool full = false;
    bool diagonal5 = false;
    bool x = false;
    bool fullFrame = false;
    bool heart = false;
    bool snowfall = false;
    bool smallFrame = false;
    bool treeArrow = false;
    bool spoutnik = false;
    bool ing = false;
    bool ngo = false;
    bool highway = false;
    
    for (var cartilla in cartillas) {
      // Horizontal
      for (int row = 0; row < 5; row++) {
        bool rowComplete = true;
        for (int col = 0; col < 5; col++) {
          if (cartilla[row][col] != 0 && !calledNumbers.contains(cartilla[row][col])) {
            rowComplete = false;
            break;
          }
        }
        if (rowComplete) horizontal = true;
      }
      // Vertical
      for (int col = 0; col < 5; col++) {
        bool colComplete = true;
        for (int row = 0; row < 5; row++) {
          if (cartilla[row][col] != 0 && !calledNumbers.contains(cartilla[row][col])) {
            colComplete = false;
            break;
          }
        }
        if (colComplete) vertical = true;
      }
      // Diagonal principal
      bool diag1 = true;
      for (int i = 0; i < 5; i++) {
        if (cartilla[i][i] != 0 && !calledNumbers.contains(cartilla[i][i])) {
          diag1 = false;
        }
      }
      if (diag1) diagMain = true;
      // Diagonal secundaria
      bool diag2 = true;
      for (int i = 0; i < 5; i++) {
        if (cartilla[i][4-i] != 0 && !calledNumbers.contains(cartilla[i][4-i])) {
          diag2 = false;
        }
      }
      if (diag2) diagAnti = true;
      // Cartón lleno
      bool isFull = true;
      for (int row = 0; row < 5; row++) {
        for (int col = 0; col < 5; col++) {
          if (cartilla[row][col] != 0 && !calledNumbers.contains(cartilla[row][col])) {
            isFull = false;
          }
        }
      }
      if (isFull) full = true;
      
      // Nuevos patrones
      if (_checkPattern(cartilla, calledNumbers, _diagonal5Pattern())) diagonal5 = true;
      if (_checkPattern(cartilla, calledNumbers, _xPattern())) x = true;
      if (_checkPattern(cartilla, calledNumbers, _fullFramePattern())) fullFrame = true;
      if (_checkPattern(cartilla, calledNumbers, _heartPattern())) heart = true;
      if (_checkPattern(cartilla, calledNumbers, _snowfallPattern())) snowfall = true;
      if (_checkPattern(cartilla, calledNumbers, _smallFramePattern())) smallFrame = true;
      if (_checkPattern(cartilla, calledNumbers, _treeArrowPattern())) treeArrow = true;
      if (_checkPattern(cartilla, calledNumbers, _spoutnikPattern())) spoutnik = true;
      if (_checkPattern(cartilla, calledNumbers, _ingPattern())) ing = true;
      if (_checkPattern(cartilla, calledNumbers, _ngoPattern())) ngo = true;
      if (_checkPattern(cartilla, calledNumbers, _highwayPattern())) highway = true;
    }
    return {
      'Línea Horizontal': horizontal,
      'Línea Vertical': vertical,
      'Diagonal Principal': diagMain,
      'Diagonal Secundaria': diagAnti,
      'Cartón Lleno': full,
      '5 Casillas Diagonales': diagonal5,
      'X': x,
      'Marco Completo': fullFrame,
      'Corazón': heart,
      'Caída de Nieve': snowfall,
      'Marco Pequeño': smallFrame,
      'Árbol o Flecha': treeArrow,
      'Spoutnik': spoutnik,
      'ING': ing,
      'NGO': ngo,
      'Autopista': highway,
    };
  }

  // Definiciones de patrones
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
  
  // Método para llamar un número aleatorio
  void callNumber() {
    if (availableNumbers.isNotEmpty) {
      final randomIndex = random.nextInt(availableNumbers.length);
      final calledNumber = availableNumbers.removeAt(randomIndex);
      calledNumbers.add(calledNumber);
      currentBall = calledNumber;
    }
  }

  /// Verifica si hay bingo en alguna cartilla y devuelve información detallada
  Map<String, dynamic> checkBingoInRealTime() {
    if (cartillas.isEmpty) {
      return {
        'hasBingo': false,
        'completedPatterns': {},
        'winningCards': [],
        'message': 'No hay cartillas para verificar'
      };
    }
    
    if (calledNumbers.isEmpty) {
      return {
        'hasBingo': false,
        'completedPatterns': {},
        'winningCards': [],
        'message': 'No se han llamado números aún'
      };
    }
    
    final completedPatterns = getCompletedPatterns(calledNumbers);
    final hasAnyBingo = completedPatterns.values.any((completed) => completed);
    
    // Buscar cartillas ganadoras
    final winningCards = <Map<String, dynamic>>[];
    for (int i = 0; i < cartillas.length; i++) {
      final cartilla = cartillas[i];
      final pattern = getBingoPattern(cartilla, calledNumbers);
      
      if (pattern != null) {
        winningCards.add({
          'cardIndex': i,
          'pattern': pattern,
          'numbers': cartilla,
          'assignedVendor': getAssignedVendor(cartilla),
        });
      }
    }
    
    return {
      'hasBingo': hasAnyBingo,
      'completedPatterns': completedPatterns,
      'winningCards': winningCards,
      'totalWinningCards': winningCards.length,
      'message': hasAnyBingo 
          ? '¡BINGO! Se completaron ${winningCards.length} cartilla${winningCards.length > 1 ? 's' : ''}'
          : 'No hay bingo aún'
    };
  }

  /// Verifica si hay bingo para patrones específicos de una ronda
  Map<String, dynamic> checkBingoForRoundPatterns(List<String> roundPatterns) {
    if (cartillas.isEmpty) {
      return {
        'hasBingo': false,
        'completedPatterns': {},
        'winningCards': [],
        'message': 'No hay cartillas para verificar'
      };
    }
    
    if (calledNumbers.isEmpty) {
      return {
        'hasBingo': false,
        'completedPatterns': {},
        'winningCards': [],
        'message': 'No se han llamado números aún'
      };
    }
    
    // Obtener solo los patrones de la ronda actual
    final completedPatterns = getCompletedPatterns(calledNumbers);
    final roundCompletedPatterns = <String, bool>{};
    
    for (final pattern in roundPatterns) {
      roundCompletedPatterns[pattern] = completedPatterns[pattern] ?? false;
    }
    
    final hasRoundBingo = roundCompletedPatterns.values.any((completed) => completed);
    
    // Buscar cartillas ganadoras solo para los patrones de la ronda
    final winningCards = <Map<String, dynamic>>[];
    for (int i = 0; i < cartillas.length; i++) {
      final cartilla = cartillas[i];
      final pattern = getBingoPattern(cartilla, calledNumbers);
      
      if (pattern != null && roundPatterns.contains(pattern)) {
        winningCards.add({
          'cardIndex': i,
          'pattern': pattern,
          'numbers': cartilla,
          'assignedVendor': getAssignedVendor(cartilla),
        });
      }
    }
    
    return {
      'hasBingo': hasRoundBingo,
      'completedPatterns': roundCompletedPatterns,
      'winningCards': winningCards,
      'totalWinningCards': winningCards.length,
      'roundPatterns': roundPatterns,
      'message': hasRoundBingo 
          ? '¡BINGO! Se completaron patrones de la ronda actual'
          : 'No hay bingo para la ronda actual aún'
    };
  }
} 