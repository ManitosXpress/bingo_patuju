import 'package:flutter/foundation.dart';
import '../models/bingo_game.dart';
import '../models/firebase_cartilla.dart';
import '../services/cartillas_service.dart';
import '../utils/debug_logger.dart';
import 'game_state_provider.dart';
import 'ui_state_provider.dart';

class AppProvider extends ChangeNotifier {
  final GameStateProvider _gameState = GameStateProvider();
  final UIStateProvider _uiState = UIStateProvider();
  
  // Lista de cartillas de Firebase
  List<FirebaseCartilla> _firebaseCartillas = [];
  List<FirebaseCartilla> _allFirebaseCartillas = []; // Todas las cartillas cargadas
  bool _isLoadingFirebase = false;
  String? _firebaseError;
  
  // Variables para paginación
  int _currentPage = 0;
  int _pageSize = 10;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  
  AppProvider() {
    // Escuchar cambios en UIStateProvider para propagar notificaciones
    _uiState.addListener(() {
      notifyListeners();
    });
    
    // Cargar vendedores automáticamente al inicializar
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    try {
      await loadVendors();
      debugLog('Vendedores cargados automáticamente: ${vendors.length}');
      
      // Cargar cartillas automáticamente al inicializar
      await loadFirebaseCartillas();
      debugLog('Cartillas cargadas automáticamente: ${_allFirebaseCartillas.length}');
    } catch (e) {
      debugLog('Error cargando datos automáticamente: $e');
    }
  }
  
  // Getters para acceder a los providers
  GameStateProvider get gameState => _gameState;
  UIStateProvider get uiState => _uiState;
  
  // Getters para Firebase
  List<FirebaseCartilla> get firebaseCartillas => _firebaseCartillas; // Solo las cartillas de la página actual
  List<FirebaseCartilla> get allFirebaseCartillas => _allFirebaseCartillas; // Todas las cartillas
  bool get isLoadingFirebase => _isLoadingFirebase;
  String? get firebaseError => _firebaseError;
  
  // Getters para paginación
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => _isLoadingMore;
  
  // Nuevos getters para paginación local
  int get totalPages => (_allFirebaseCartillas.length / _pageSize).ceil();
  bool get hasNextPage => _currentPage < totalPages;
  bool get hasPreviousPage => _currentPage > 1;
  int get totalCartillas => _allFirebaseCartillas.length;
  
  // Métodos de conveniencia para acceder directamente al estado del juego
  BingoGame get bingoGame => _gameState.bingoGame;
  List<Map<String, dynamic>> get vendors => _gameState.vendors;
  String? get selectedVendorId => _gameState.selectedVendorId;
  bool get isLoading => _gameState.isLoading;
  bool get isSyncingAll => _gameState.isSyncingAll;
  bool get loadingServerCards => _gameState.loadingServerCards;
  
  // Métodos de conveniencia para acceder directamente al estado de la UI
  bool get onlyUnsynced => _uiState.onlyUnsynced;
  bool get onlyUnassigned => _uiState.onlyUnassigned;
  bool get onlyAssigned => _uiState.onlyAssigned;
  String? get filterVendorId => _uiState.filterVendorId;
  String get searchQuery => _uiState.searchQuery;
  
  // Métodos de conveniencia para el juego
  void generateNewCartillas(int count) => _gameState.generateNewCartillas(count);
  void callNumber() => _gameState.callNumber();
  void resetGame() => _gameState.resetGame();
  
  // Métodos de conveniencia para asignaciones
  void assignCartilla(List<List<int>> cartilla, String vendorId) => _gameState.assignCartilla(cartilla, vendorId);
  void unassignCartilla(List<List<int>> cartilla) => _gameState.unassignCartilla(cartilla);
  bool isCartillaAssigned(List<List<int>> cartilla) => _gameState.isCartillaAssigned(cartilla);
  String? getAssignedVendor(List<List<int>> cartilla) => _gameState.getAssignedVendor(cartilla);
  List<List<List<int>>> getCartillasByVendor(String vendorId) => _gameState.getCartillasByVendor(vendorId);
  Map<String, int> getCartillaStatusCount() => _gameState.getCartillaStatusCount();
  
  // Métodos de conveniencia para vendedores
  void setSelectedVendor(String? vendorId) => _gameState.setSelectedVendor(vendorId);
  Future<void> loadVendors() => _gameState.loadVendors();
  
  // Métodos de conveniencia para sincronización
  Future<void> refreshSyncStatus() => _gameState.refreshSyncStatus();
  Future<void> syncAllCartillas() => _gameState.syncAllCartillas();
  Future<void> syncAssignedCartillas() => _gameState.syncAssignedCartillas();
  
  // Método para refrescar datos de cartillas
  Future<void> refreshCartillasData() async {
    await refreshSyncStatus();
    await loadVendors();
  }
  
  // Métodos de conveniencia para la UI
  void setOnlyUnsynced(bool value) => _uiState.setOnlyUnsynced(value);
  void setOnlyUnassigned(bool value) => _uiState.setOnlyUnassigned(value);
  void setOnlyAssigned(bool value) => _uiState.setOnlyAssigned(value);
  void setFilterVendorId(String? value) => _uiState.setFilterVendorId(value);
  void setSearchQuery(String query) => _uiState.setSearchQuery(query);
  
  // Métodos de selección
  void toggleCartillaSelection(String cartillaId) {
    _uiState.toggleCartillaSelection(cartillaId);
  }
  void selectAllCartillas(List<String> cartillaIds) => _uiState.selectAllCartillas(cartillaIds);
  void clearSelection() => _uiState.clearSelection();
  void selectCartilla(String cartillaId) => _uiState.selectCartilla(cartillaId);
  void unselectCartilla(String cartillaId) => _uiState.unselectCartilla(cartillaId);
  bool isCartillaSelected(String cartillaId) {
    return _uiState.isCartillaSelected(cartillaId);
  }
  int get selectedCount => _uiState.selectedCount;
  Set<String> get selectedCartillaIds => _uiState.selectedCartillaIds;
  
  // Métodos de conveniencia para filtros
  void resetFilters() => _uiState.resetFilters();
  void applyDefaultFilters() => _uiState.applyDefaultFilters();
  
  // Método para obtener el nombre del vendedor
  String? getVendorName(String? vendorId) => _gameState.getVendorName(vendorId);
  
  // Método para verificar si una cartilla está sincronizada
  bool isCartillaSynced(List<List<int>> cartilla) => _gameState.isCartillaSynced(cartilla);
  
  // Método para obtener la clave única de una cartilla
  String getCardKey(List<List<int>> cartilla) {
    return cartilla.expand((row) => row).join(',');
  }
  
  // ===== MÉTODOS DE FIREBASE =====
  
  // Cargar cartillas desde Firebase con paginación
  Future<void> loadFirebaseCartillas({String? assignedTo, bool? sold, bool reset = false}) async {
    try {
      if (reset) {
        _currentPage = 0;
        _firebaseCartillas.clear();
        _allFirebaseCartillas.clear(); // Limpiar todas las cartillas cargadas
        _hasMoreData = true;
      }
      
      if (!_hasMoreData) return;
      
      _isLoadingFirebase = true;
      _firebaseError = null;
      notifyListeners();
      
      debugLog('Cargando todas las cartillas de Firebase...');
      
      // Cargar vendedores primero para asegurar que estén disponibles
      await loadVendors();
      debugLog('Vendedores cargados antes de cartillas: ${vendors.length}');
      
      // Cargar todas las cartillas de Firebase de una vez (máximo 2000)
      final cartillasData = await CartillaService.getCartillas(
        assignedTo: assignedTo,
        sold: sold,
        page: 0, // Siempre página 0 para cargar todo
        limit: 2000, // Límite alto para cargar todas las cartillas (600+)
      );
      
      debugLog('Cartillas recibidas de Firebase: ${cartillasData.length}');
      
      // Procesar solo las cartillas válidas
      final validCartillas = <FirebaseCartilla>[];
      for (int i = 0; i < cartillasData.length; i++) {
        try {
          final data = cartillasData[i];
          debugLog('Procesando cartilla $i - ID: ${data['id']}, Numbers: ${data['numbers']}');
          
          final cartilla = FirebaseCartilla.fromJson(data);
          
          if (cartilla.isValidStructure) {
            validCartillas.add(cartilla);
            debugLog('Cartilla $i válida - ID: ${cartilla.id}, Filas: ${cartilla.numbers.length}, Columnas: ${cartilla.numbers.isNotEmpty ? cartilla.numbers[0].length : 0}');
          } else {
            debugLog('Cartilla $i inválida - ID: ${cartilla.id}, Filas: ${cartilla.numbers.length}');
          }
        } catch (e) {
          debugLog('Error procesando cartilla $i: $e');
          debugLog('Datos de la cartilla: ${cartillasData[i]}');
          // Continuar con la siguiente cartilla en lugar de fallar completamente
          continue;
        }
      }
      
      // Agregar a la lista de todas las cartillas
      _allFirebaseCartillas.addAll(validCartillas);
      
      // Actualizar estado de paginación - ahora manejamos paginación local
      _hasMoreData = false; // No hay más datos en el backend
      _currentPage = 1; // Empezar en página 1 para mostrar las primeras 10
      
      // Actualizar la lista de cartillas visibles (página actual)
      _updateVisibleCartillas();
      
      debugLog('Total cartillas cargadas: ${_allFirebaseCartillas.length}, Visibles: ${_firebaseCartillas.length}, ¿Hay más datos? $_hasMoreData');
      
      // Sincronizar con el juego local
      await _syncFirebaseWithLocal();
      
    } catch (e) {
      _firebaseError = e.toString();
      print('Error cargando cartillas de Firebase: $e');
    } finally {
      _isLoadingFirebase = false;
      notifyListeners();
    }
  }
  
  // Actualizar las cartillas visibles basado en la página actual
  void _updateVisibleCartillas() {
    try {
      if (_allFirebaseCartillas.isEmpty) {
        _firebaseCartillas = [];
        return;
      }
      
      // Calcular índices para la paginación local
      final startIndex = (_currentPage - 1) * _pageSize;
      final endIndex = startIndex + _pageSize;
      
      debugLog('Actualizando cartillas visibles - Página: $_currentPage, Start: $startIndex, End: $endIndex, Total: ${_allFirebaseCartillas.length}');
      
      if (startIndex < _allFirebaseCartillas.length) {
        // Mostrar las cartillas de la página actual
        _firebaseCartillas = _allFirebaseCartillas.sublist(
          startIndex, 
          endIndex.clamp(0, _allFirebaseCartillas.length)
        );
        debugLog('Cartillas visibles actualizadas: ${_firebaseCartillas.length}');
      } else {
        _firebaseCartillas = [];
        debugLog('No hay cartillas para mostrar en esta página');
      }
    } catch (e) {
      debugLog('Error actualizando cartillas visibles: $e');
      _firebaseCartillas = [];
    }
  }
  
  // Cargar más cartillas (paginación local)
  Future<void> loadMoreCartillas({String? assignedTo, bool? sold}) async {
    if (_isLoadingMore) return;
    
    try {
      _isLoadingMore = true;
      notifyListeners();
      
      // Calcular si hay más páginas disponibles localmente
      final totalPages = (_allFirebaseCartillas.length / _pageSize).ceil();
      
      if (_currentPage < totalPages) {
        _currentPage++;
        _updateVisibleCartillas();
        debugLog('Avanzando a página $_currentPage de $totalPages');
      } else {
        debugLog('Ya estás en la última página ($_currentPage de $totalPages)');
      }
      
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Ir a la página anterior (paginación local)
  Future<void> goToPreviousPage() async {
    if (_currentPage > 1) {
      _currentPage--;
      _updateVisibleCartillas();
      debugLog('Retrocediendo a página $_currentPage');
      notifyListeners();
    }
  }
  
  // Refrescar cartillas (resetear paginación)
  Future<void> refreshFirebaseCartillas({String? assignedTo, bool? sold}) async {
    await loadFirebaseCartillas(
      assignedTo: assignedTo,
      sold: sold,
      reset: true,
    );
  }
  
  // Limpiar error de Firebase
  void clearFirebaseError() {
    _firebaseError = null;
    notifyListeners();
  }
  
  // Crear nueva cartilla en Firebase
  Future<FirebaseCartilla?> createFirebaseCartilla({int? cardNo}) async {
    try {
      final numbers = CartillaService.generateBingoCard();
      final cartillaData = await CartillaService.createCartilla(numbers, cardNo: cardNo);
      
      final newCartilla = FirebaseCartilla.fromJson(cartillaData);
      
      // Verificar que la cartilla tenga estructura válida antes de agregarla
      if (newCartilla.isValidStructure) {
        _firebaseCartillas.add(newCartilla);
        _allFirebaseCartillas.add(newCartilla); // Agregar a la lista de todas las cartillas
        
        // Sincronizar con el juego local
        await _syncFirebaseWithLocal();
        
        notifyListeners();
        return newCartilla;
      } else {
        throw Exception('La cartilla generada no tiene una estructura válida');
      }
      
    } catch (e) {
      _firebaseError = e.toString();
      print('Error creando cartilla en Firebase: $e');
      notifyListeners();
      return null;
    }
  }
  
  // Asignar cartilla a vendedor en Firebase
  Future<bool> assignFirebaseCartilla(String cartillaId, String vendorId) async {
    try {
      final cartillaData = await CartillaService.assignCartilla(cartillaId, vendorId);
      
      // Actualizar en la lista local
      final index = _firebaseCartillas.indexWhere((c) => c.id == cartillaId);
      if (index != -1) {
        _firebaseCartillas[index] = FirebaseCartilla.fromJson(cartillaData);
      }
      final indexAll = _allFirebaseCartillas.indexWhere((c) => c.id == cartillaId);
      if (indexAll != -1) {
        _allFirebaseCartillas[indexAll] = FirebaseCartilla.fromJson(cartillaData);
      }
      
      // Sincronizar con el juego local
      await _syncFirebaseWithLocal();
      
      notifyListeners();
      return true;
      
    } catch (e) {
      _firebaseError = e.toString();
      print('Error asignando cartilla en Firebase: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Sincronizar cartillas de Firebase con el juego local
  Future<void> _syncFirebaseWithLocal() async {
    try {
      debugLog('Iniciando sincronización de Firebase con juego local');
      
      // Convertir cartillas de Firebase al formato del juego local
      final localCartillas = _allFirebaseCartillas
          .map((fc) => fc.numbers)
          .toList();
      
      debugLog('${localCartillas.length} cartillas convertidas para sincronización');
      
      // Sincronizar usando el nuevo método del GameStateProvider
      await _gameState.syncFirebaseCartillasWithGame(localCartillas);
      
      // Verificar bingo después de la sincronización
      final bingoCheck = _gameState.checkBingoInRealTime();
      if (bingoCheck['hasBingo'] == true) {
        debugLog('¡BINGO detectado en AppProvider!');
        debugLog('${bingoCheck['message']}');
      }
      
      // Actualizar estado de sincronización
      await refreshSyncStatus();
      
      debugLog('Sincronización completada exitosamente');
      
    } catch (e) {
      print('Error sincronizando Firebase con local: $e');
    }
  }
  
  // Obtener cartillas filtradas de Firebase
  List<FirebaseCartilla> getFilteredFirebaseCartillas() {
    List<FirebaseCartilla> filtered = _firebaseCartillas;
    
    // Filtro por vendedor
    if (filterVendorId != null) {
      filtered = filtered.where((c) => c.assignedTo == filterVendorId).toList();
    }
    
    // Filtro por estado de asignación
    if (onlyAssigned) {
      filtered = filtered.where((c) => c.isAssigned).toList();
    } else if (onlyUnassigned) {
      filtered = filtered.where((c) => !c.isAssigned).toList();
    }
    
    // Filtro por búsqueda
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((c) => 
        c.displayNumber.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }
  
  // Desasignar cartilla de vendedor en Firebase
  Future<bool> unassignFirebaseCartilla(String cartillaId) async {
    try {
      final cartillaData = await CartillaService.unassignCartilla(cartillaId);
      
      // Actualizar en la lista local
      final index = _firebaseCartillas.indexWhere((c) => c.id == cartillaId);
      if (index != -1) {
        _firebaseCartillas[index] = FirebaseCartilla.fromJson(cartillaData);
      }
      final indexAll = _allFirebaseCartillas.indexWhere((c) => c.id == cartillaId);
      if (indexAll != -1) {
        _allFirebaseCartillas[indexAll] = FirebaseCartilla.fromJson(cartillaData);
      }
      
      // Sincronizar con el juego local
      await _syncFirebaseWithLocal();
      
      notifyListeners();
      return true;
      
    } catch (e) {
      _firebaseError = e.toString();
      print('Error desasignando cartilla en Firebase: $e');
      notifyListeners();
      return false;
    }
  }

  // Eliminar cartilla de Firebase
  Future<bool> deleteFirebaseCartilla(String cartillaId) async {
    try {
      final success = await CartillaService.deleteCartilla(cartillaId);
      
      if (success) {
        // Remover de la lista local
        _firebaseCartillas.removeWhere((c) => c.id == cartillaId);
        _allFirebaseCartillas.removeWhere((c) => c.id == cartillaId);
        
        // Si no hay más cartillas visibles en la página actual, ir a la página anterior
        if (_firebaseCartillas.isEmpty && _currentPage > 1) {
          debugLog('No hay cartillas visibles después de eliminar, retrocediendo a página anterior...');
          _currentPage--;
          _updateVisibleCartillas();
        }
        
        // Sincronizar con el juego local
        await _syncFirebaseWithLocal();
        
        notifyListeners();
        return true;
      }
      
      return false;
      
    } catch (e) {
      _firebaseError = e.toString();
      print('Error eliminando cartilla en Firebase: $e');
      notifyListeners();
      return false;
    }
  }

  // Generar cartillas en Firebase
  Future<bool> generateFirebaseCartillas(int count) async {
    try {
      final result = await CartillaService.generateCartillas(count);
      
      if (result != null) {
        // Recargar las cartillas después de generar
        await loadFirebaseCartillas();
        
        debugLog('Se generaron $count cartillas en Firebase');
        return true;
      }
      
      return false;
    } catch (e) {
      _firebaseError = e.toString();
      print('Error generando cartillas en Firebase: $e');
      notifyListeners();
      return false;
    }
  }

  // Eliminar TODAS las cartillas de Firebase
  Future<bool> clearAllFirebaseCartillas() async {
    try {
      final result = await CartillaService.clearAllCartillas();
      
      if (result != null) {
        // Limpiar todas las listas locales
        _firebaseCartillas.clear();
        _allFirebaseCartillas.clear();
        _currentPage = 1;
        _hasMoreData = true;
        
        // Limpiar selección
        _uiState.clearSelection();
        
        // Sincronizar con el juego local
        await _syncFirebaseWithLocal();
        
        notifyListeners();
        
        debugLog('Se eliminaron todas las cartillas. Resultado: $result');
        return true;
      }
      
      return false;
      
    } catch (e) {
      _firebaseError = e.toString();
      print('Error eliminando todas las cartillas de Firebase: $e');
      notifyListeners();
      return false;
    }
  }

  // Método para recargar automáticamente cartillas cuando sea necesario
  Future<void> autoReloadIfNeeded() async {
    if (_firebaseCartillas.isEmpty && _allFirebaseCartillas.isNotEmpty) {
      debugLog('Recarga automática necesaria - cartillas visibles vacías');
      
      // Si no hay cartillas visibles pero hay datos cargados, ir a la primera página
      if (_currentPage > 1) {
        _currentPage = 1;
        _updateVisibleCartillas();
        notifyListeners();
      }
    }
  }

  // Método para verificar bingo en tiempo real
  Map<String, dynamic> checkBingoInRealTime() {
    return _gameState.checkBingoInRealTime();
  }

  // Método para verificar bingo con patrones de la ronda actual
  Map<String, dynamic> checkBingoForRoundPatterns() {
    // Obtener los patrones de la ronda actual desde el panel de juegos
    // Por ahora, usar la verificación general hasta que se conecte con el panel de juegos
    // TODO: Implementar obtención de patrones de ronda actual desde BingoGamesPanel
    return checkBingoInRealTime();
  }
  
  // Método para verificar bingo con patrones específicos de una ronda
  Map<String, dynamic> checkBingoForSpecificRoundPatterns(List<String> roundPatterns) {
    if (roundPatterns.isEmpty) {
      debugLog('No hay patrones de ronda para verificar, usando verificación general');
      return checkBingoInRealTime();
    }
    
    debugLog('Verificando bingo para patrones específicos de ronda: $roundPatterns');
    return _gameState.checkBingoForRoundPatterns(roundPatterns);
  }
  
  // Método para obtener patrones completados solo de la ronda actual
  Map<String, bool> getCompletedPatternsForCurrentRound(List<String> currentRoundPatterns) {
    if (currentRoundPatterns.isEmpty) {
      debugLog('No hay patrones de ronda actual, devolviendo mapa vacío');
      return {};
    }
    
    final allCompletedPatterns = _gameState.bingoGame.getCompletedPatterns(_gameState.bingoGame.calledNumbers);
    final roundCompletedPatterns = <String, bool>{};
    
    for (final pattern in currentRoundPatterns) {
      roundCompletedPatterns[pattern] = allCompletedPatterns[pattern] ?? false;
    }
    
    debugLog('Patrones de ronda actual: $currentRoundPatterns');
    debugLog('Patrones completados de ronda: $roundCompletedPatterns');
    
    return roundCompletedPatterns;
  }

  // Método para obtener patrones completados
  Map<String, bool> getCompletedPatterns() {
    return _gameState.bingoGame.getCompletedPatterns(_gameState.bingoGame.calledNumbers);
  }

  // Método para llamar un número específico
  // Optimizado: NO verifica bingo automáticamente para mejorar rendimiento
  void callSpecificNumber(int number) {
    if (!_gameState.bingoGame.calledNumbers.contains(number)) {
      // Llamar el número específico
      _gameState.bingoGame.calledNumbers.add(number);
      _gameState.bingoGame.availableNumbers.remove(number);
      _gameState.bingoGame.currentBall = number;
      
      // NO verificar bingo automáticamente - solo se verifica cuando se presiona "Verificar Bingo"
      // Esto mejora significativamente el rendimiento, especialmente con muchas cartillas
      
      // Notificar cambios
      _gameState.notifyListeners();
      notifyListeners();
    }
  }

  // Método para buscar cartilla por número
  FirebaseCartilla? findCartillaByNumber(int cardNumber) {
    try {
      final cartilla = _allFirebaseCartillas.firstWhere(
        (c) => c.cardNo == cardNumber,
        orElse: () => throw Exception('Cartilla no encontrada'),
      );
      debugLog('Cartilla $cardNumber encontrada: ${cartilla.id}');
      return cartilla;
    } catch (e) {
      debugLog('Cartilla $cardNumber no encontrada: $e');
      return null;
    }
  }

  // Método para verificar si una cartilla específica es ganadora
  Map<String, dynamic> checkSpecificCartilla(int cardNumber, {List<String>? roundPatterns}) {
    try {
      final cartilla = findCartillaByNumber(cardNumber);
      if (cartilla == null) {
        return {
          'found': false,
          'message': 'Cartilla $cardNumber no encontrada',
        };
      }

      debugLog('Verificando cartilla $cardNumber con números: ${cartilla.numbers}');
      debugLog('Números llamados: ${bingoGame.calledNumbers}');

      // Verificar directamente si esta cartilla específica tiene un patrón completado
      final cartillaNumbers = cartilla.numbers;
      final calledNumbers = bingoGame.calledNumbers;
      
      // Verificar cada patrón de la ronda (o todos si no hay patrones específicos)
      final patternsToCheck = roundPatterns ?? [
        'Línea Horizontal', 'Línea Vertical', 'Diagonal Principal', 'Diagonal Secundaria',
        'Cartón Lleno', 'Figura Avión', 'X', 'Marco Completo', 'Corazón',
        'Caída de Nieve', 'Marco Pequeño', 'Árbol o Flecha', 'Spoutnik', 'ING', 'NGO', 'Autopista',
        // Figuras legendarias
        'Reloj de Arena', 'Doble Línea V', 'Figura la Suegra', 'Figura Infinito', 'Letra FE',
        'Figura C Loca', 'Figura Bandera', 'Figura Triple Línea', 'Diagonal Derecha'
      ];
      
      // Detectar TODOS los patrones ganadores
      final List<String> allWinningPatterns = [];
      
      for (final pattern in patternsToCheck) {
        if (_checkCartillaPattern(cartillaNumbers, calledNumbers, pattern)) {
          allWinningPatterns.add(pattern);
          debugLog('Patrón detectado: $pattern');
        }
      }

      if (allWinningPatterns.isNotEmpty) {
        final primaryPattern = allWinningPatterns.first;
        final message = roundPatterns != null && roundPatterns.isNotEmpty
            ? '¡Cartilla $cardNumber es GANADORA para la ronda actual!'
            : '¡Cartilla $cardNumber es GANADORA!';
            
        debugLog('¡Cartilla $cardNumber GANÓ con ${allWinningPatterns.length} patrones: $allWinningPatterns!');
            
        return {
          'found': true,
          'isWinning': true,
          'cartilla': cartilla,
          'message': message,
          'pattern': primaryPattern,
          'allWinningPatterns': allWinningPatterns, // Lista de TODOS los patrones ganadores
          'winningNumbers': cartillaNumbers,
          'calledNumbers': calledNumbers,
        };
      } else {
        final message = roundPatterns != null && roundPatterns.isNotEmpty
            ? 'Cartilla $cardNumber no es ganadora para la ronda actual aún'
            : 'Cartilla $cardNumber no es ganadora aún';
            
        debugLog('Cartilla $cardNumber no ganó ningún patrón');
            
        return {
          'found': true,
          'isWinning': false,
          'cartilla': cartilla,
          'message': message,
        };
      }
    } catch (e) {
      debugLog('Error verificando cartilla $cardNumber: $e');
      return {
        'found': false,
        'message': 'Error verificando cartilla: $e',
      };
    }
  }

  // Método auxiliar para verificar si una cartilla cumple un patrón específico
  bool _checkCartillaPattern(List<List<int>> cartilla, List<int> calledNumbers, String pattern) {
    switch (pattern) {
      case 'Línea Horizontal':
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
        
      case 'Línea Vertical':
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
        
      case 'Diagonal Principal':
        for (int i = 0; i < 5; i++) {
          if (cartilla[i][i] != 0 && !calledNumbers.contains(cartilla[i][i])) {
            return false;
          }
        }
        return true;
        
      case 'Diagonal Secundaria':
        for (int i = 0; i < 5; i++) {
          if (cartilla[i][4-i] != 0 && !calledNumbers.contains(cartilla[i][4-i])) {
            return false;
          }
        }
        return true;
        
      case 'Cartón Lleno':
        for (int row = 0; row < 5; row++) {
          for (int col = 0; col < 5; col++) {
            if (cartilla[row][col] != 0 && !calledNumbers.contains(cartilla[row][col])) {
              return false;
            }
          }
        }
        return true;
        
      case 'Marco Completo':
        for (int i = 0; i < 5; i++) {
          for (int j = 0; j < 5; j++) {
            if ((i == 0 || i == 4 || j == 0 || j == 4) && 
                cartilla[i][j] != 0 && !calledNumbers.contains(cartilla[i][j])) {
              return false;
            }
          }
        }
        return true;
        
      case 'Marco Pequeño':
        for (int i = 1; i < 4; i++) {
          for (int j = 1; j < 4; j++) {
            if (cartilla[i][j] != 0 && !calledNumbers.contains(cartilla[i][j])) {
              return false;
            }
          }
        }
        return true;
        
      case 'Figura Avión':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,0,0,0,1],
          [0,1,0,1,0],
          [0,0,1,0,0],
          [0,1,0,1,0],
          [1,0,0,0,1],
        ]);
        
      case 'X':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,0,0,0,1],
          [0,1,0,1,0],
          [0,0,1,0,0],
          [0,1,0,1,0],
          [1,0,0,0,1],
        ]);
        
      case 'Corazón':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [0,1,0,1,0],
          [1,1,1,1,1],
          [1,1,1,1,1],
          [0,1,1,1,0],
          [0,0,1,0,0],
        ]);
        
      case 'Caída de Nieve':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [0,0,1,0,0],
          [0,1,1,1,0],
          [1,1,1,1,1],
          [0,1,1,1,0],
          [0,0,1,0,0],
        ]);
        
      case 'Árbol o Flecha':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [0,0,1,0,0],
          [0,1,1,1,0],
          [1,1,1,1,1],
          [0,0,1,0,0],
          [0,0,1,0,0],
        ]);
        
      case 'Spoutnik':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [0,0,1,0,0],
          [0,1,1,1,0],
          [1,1,1,1,1],
          [0,0,1,0,0],
          [0,0,1,0,0],
        ]);
        
      case 'I':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,0,0,0,1],
          [1,0,0,0,1],
          [1,0,0,0,1],
          [1,0,0,0,1],
          [1,1,1,1,1],
        ]);
        
      case 'N':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,1,1,1,1],
          [1,0,0,0,1],
          [1,1,1,1,1],
          [1,0,0,0,1],
          [1,1,1,1,1],
        ]);
        
      case 'Autopista':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,1,1,1,1],
          [0,0,1,0,0],
          [0,0,1,0,0],
          [0,0,1,0,0],
          [1,1,1,1,1],
        ]);
        
      // Figuras legendarias
      case 'Reloj de Arena':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,1,1,1,1],
          [0,1,1,1,0],
          [0,0,1,0,0],
          [0,1,1,1,0],
          [1,1,1,1,1],
        ]);
        
      case 'Doble Línea V':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,0,0,0,1],
          [0,1,0,1,0],
          [0,0,1,0,0],
          [0,1,0,1,0],
          [1,0,0,0,1],
        ]);
        
      case 'Figura la Suegra':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,0,1,0,1],
          [0,1,0,1,0],
          [1,0,1,0,1],
          [0,1,0,1,0],
          [1,0,1,0,1],
        ]);
        
      case 'Figura Infinito':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,0,1,0,1],
          [0,1,0,1,0],
          [1,1,1,1,1],
          [0,1,0,1,0],
          [1,0,1,0,1],
        ]);
        
      case 'Letra FE':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,1,1,1,0],
          [1,0,0,0,0],
          [1,1,1,0,0],
          [1,0,0,0,0],
          [1,0,0,0,0],
        ]);
        
      case 'Figura C Loca':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,0,0,0,1],
          [1,0,0,0,1],
          [1,0,1,0,1],
          [1,0,0,0,1],
          [1,0,0,0,1],
        ]);
        
      case 'Figura Bandera':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,1,1,1,1],
          [1,1,1,1,1],
          [1,1,1,1,1],
          [0,0,1,1,1],
          [0,0,1,1,1],
        ]);
        
      case 'Figura Triple Línea':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,1,1,1,1],
          [0,0,0,0,0],
          [1,1,1,1,1],
          [0,0,0,0,0],
          [1,1,1,1,1],
        ]);
        
      case 'Diagonal Derecha':
        return _checkCustomPattern(cartilla, calledNumbers, [
          [1,0,0,0,0],
          [0,1,0,0,0],
          [0,0,1,0,0],
          [0,0,0,1,0],
          [0,0,0,0,1],
        ]);
        
      default:
        return false;
    }
  }

  // Método auxiliar para verificar patrones personalizados
  bool _checkCustomPattern(List<List<int>> cartilla, List<int> calledNumbers, List<List<int>> pattern) {
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
} 