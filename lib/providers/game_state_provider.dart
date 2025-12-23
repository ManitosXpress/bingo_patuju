import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/bingo_game.dart';
import '../config/backend_config.dart';

class GameStateProvider extends ChangeNotifier {
  // Estado del juego
  BingoGame _bingoGame = BingoGame();
  BingoGame get bingoGame => _bingoGame;
  
  // Estado de sincronización
  final Set<String> _syncedKeys = <String>{};
  final Set<String> _serverCardKeys = <String>{};
  final Map<String, String> _serverAssignments = <String, String>{};
  
  // Estado de carga
  bool _isLoading = false;
  bool _isSyncingAll = false;
  bool _loadingServerCards = false;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isSyncingAll => _isSyncingAll;
  bool get loadingServerCards => _loadingServerCards;
  
  // Vendedores
  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> get vendors => _vendors;
  String? _selectedVendorId;
  String? get selectedVendorId => _selectedVendorId;
  
  // Constructor
  GameStateProvider() {
    // No cargar vendedores automáticamente para mejor rendimiento
    // Se cargarán solo cuando se necesiten
  }
  
  // Métodos para el juego
  void generateNewCartillas(int count) {
    _bingoGame.generateCartillas(count);
    notifyListeners();
  }
  
  void callNumber() {
    _bingoGame.callNumber();
    notifyListeners();
  }
  
  void resetGame() {
    _bingoGame = BingoGame();
    _syncedKeys.clear();
    _serverCardKeys.clear();
    notifyListeners();
  }
  
  // Métodos para asignaciones
  void assignCartilla(List<List<int>> cartilla, String vendorId) {
    _bingoGame.assignCartilla(cartilla, vendorId);
    notifyListeners();
  }
  
  void unassignCartilla(List<List<int>> cartilla) {
    _bingoGame.unassignCartilla(cartilla);
    notifyListeners();
  }
  
  bool isCartillaAssigned(List<List<int>> cartilla) {
    return _bingoGame.isCartillaAssigned(cartilla);
  }
  
  String? getAssignedVendor(List<List<int>> cartilla) {
    return _bingoGame.getAssignedVendor(cartilla);
  }
  
  List<List<List<int>>> getCartillasByVendor(String vendorId) {
    return _bingoGame.getCartillasByVendor(vendorId);
  }
  
  Map<String, int> getCartillaStatusCount() {
    return _bingoGame.getCartillaStatusCount();
  }
  
  // Métodos para vendedores
  void setSelectedVendor(String? vendorId) {
    _selectedVendorId = vendorId;
    notifyListeners();
  }
  
  Future<void> loadVendors() async {
    await _loadVendors();
  }
  
  Future<void> _loadVendors() async {
    try {
      // Limpiar cache de nombres de vendedores
      _vendorNameCache.clear();
      
      final url = '${BackendConfig.apiBase}/vendors';
      // print('DEBUG: Cargando vendedores desde: $url');
      
      final resp = await http.get(Uri.parse(url));
      // print('DEBUG: Respuesta del servidor: ${resp.statusCode}');
      // print('DEBUG: Cuerpo de la respuesta: ${resp.body}');
      
      if (resp.statusCode < 300) {
        _vendors = List<Map<String, dynamic>>.from(json.decode(resp.body));
        // print('DEBUG: Vendedores cargados: ${_vendors.length}');
        
        // Debug: mostrar cada vendedor cargado
        // for (final vendor in _vendors) {
        //   print('DEBUG: Vendedor cargado - ID: ${vendor['id']}, Nombre: ${vendor['name']}');
        // }
        
        notifyListeners();
      } else {
        if (kDebugMode) {
          print('Error del servidor al cargar vendedores: ${resp.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cargando vendedores: $e');
      }
    }
  }
  
  // Métodos para sincronización
  Future<void> refreshSyncStatus() async {
    try {
      _loadingServerCards = true;
      notifyListeners();
      
      final resp = await http.get(Uri.parse('${BackendConfig.apiBase}/cards'));
      if (resp.statusCode < 300) {
        final list = List<Map<String, dynamic>>.from(json.decode(resp.body));
        
        // Crear un Set para búsquedas más eficientes
        final serverCardKeys = <String>{};
        final serverAssignments = <String, String>{};
        
        // Procesar respuesta del servidor una sola vez
        for (final card in list) {
          final numbers = List<List<int>>.from((card['numbers'] as List).map((r) => List<int>.from(r as List)));
          final key = _getCardKey(numbers);
          final assignedTo = card['assignedTo'] as String?;
          
          serverCardKeys.add(key);
          if (assignedTo != null) {
            serverAssignments[key] = assignedTo;
          }
        }
        
        // Actualizar estado local de manera más eficiente
        bool hasChanges = false;
        for (int i = 0; i < _bingoGame.cartillas.length; i++) {
          final cartilla = _bingoGame.cartillas[i];
          final key = _getCardKey(cartilla);
          
          // Verificar sincronización
          if (serverCardKeys.contains(key) && !_syncedKeys.contains(key)) {
            _syncedKeys.add(key);
            _serverCardKeys.add(key);
            hasChanges = true;
          }
          
          // Verificar asignación
          final serverAssigned = serverAssignments[key];
          final localAssigned = _bingoGame.getAssignedVendor(cartilla);
          if (serverAssigned != localAssigned) {
            if (serverAssigned != null) {
              _bingoGame.assignCartilla(cartilla, serverAssigned);
            } else {
              _bingoGame.unassignCartilla(cartilla);
            }
            hasChanges = true;
          }
        }
        
        // Solo notificar si hubo cambios
        if (hasChanges) {
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refrescando estado: $e');
      }
    } finally {
      _loadingServerCards = false;
      notifyListeners();
    }
  }
  
  Future<void> syncAllCartillas() async {
    try {
      _isSyncingAll = true;
      notifyListeners();
      
      int done = 0;
      for (final cartilla in _bingoGame.cartillas) {
        await _syncCartillaWithBackend(cartilla);
        done++;
      }
      
      if (kDebugMode) {
        print('Sincronizadas $done cartillas');
      }
    } finally {
      _isSyncingAll = false;
      notifyListeners();
    }
  }
  
  Future<void> syncAssignedCartillas() async {
    try {
      _isSyncingAll = true;
      notifyListeners();
      
      final assignedCartillas = <List<List<int>>>[];
      for (int i = 0; i < _bingoGame.cartillas.length; i++) {
        if (_bingoGame.isCartillaAssigned(_bingoGame.cartillas[i])) {
          assignedCartillas.add(_bingoGame.cartillas[i]);
        }
      }
      
      int done = 0;
      for (final cartilla in assignedCartillas) {
        await _syncCartillaWithBackend(cartilla);
        done++;
      }
      
      if (kDebugMode) {
        print('Sincronizadas $done cartillas asignadas');
      }
    } finally {
      _isSyncingAll = false;
      notifyListeners();
    }
  }
  
  Future<void> _syncCartillaWithBackend(List<List<int>> numbers) async {
    try {
      final key = _getCardKey(numbers);
      if (_syncedKeys.contains(key)) {
        return;
      }
      
      // Crear cartilla en backend
      final resp = await http.post(
        Uri.parse('${BackendConfig.apiBase}/cards'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'numbers': numbers, 'cardNo': _bingoGame.cartillas.indexOf(numbers) + 1}),
      );
      
      if (resp.statusCode >= 300) {
        throw Exception('Error creando cartilla: ${resp.body}');
      }
      
      final card = json.decode(resp.body) as Map<String, dynamic>;
      
      // Asignar si hay vendedor seleccionado
      if (_selectedVendorId != null && _selectedVendorId!.isNotEmpty) {
        final a = await http.post(
          Uri.parse('${BackendConfig.apiBase}/cards/${card['id']}/assign'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'vendorId': _selectedVendorId}),
        );
        
        if (a.statusCode >= 300) {
          throw Exception('Creada pero no asignada: ${a.body}');
        }
        
        // Actualizar el estado local de asignación
        _bingoGame.assignCartilla(numbers, _selectedVendorId!);
      }
      
      _syncedKeys.add(key);
      _serverCardKeys.add(key);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error sincronizando cartilla: $e');
      }
    }
  }
  
  // Método para obtener la clave única de una cartilla
  String _getCardKey(List<List<int>> cartilla) {
    return cartilla.expand((row) => row).join(',');
  }
  
  // Método para verificar si una cartilla está sincronizada
  bool isCartillaSynced(List<List<int>> cartilla) {
    final key = _getCardKey(cartilla);
    return _syncedKeys.contains(key) || _serverCardKeys.contains(key);
  }
  
  // Cache para nombres de vendedores
  final Map<String, String> _vendorNameCache = {};
  
  // Método para obtener el nombre del vendedor
  String? getVendorName(String? vendorId) {
    if (vendorId == null) {
      return null;
    }
    
    // Usar cache si está disponible
    if (_vendorNameCache.containsKey(vendorId)) {
      return _vendorNameCache[vendorId];
    }
    
    try {
      for (final vendor in _vendors) {
        if (vendor['id'] == vendorId) {
          final name = vendor['name'] as String?;
          
          // Guardar en cache
          if (name != null) {
            _vendorNameCache[vendorId] = name;
          }
          
          return name;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error en getVendorName: $e');
      }
      return null;
    }
  }

  // Método para sincronizar cartillas de Firebase con el juego local
  Future<void> syncFirebaseCartillasWithGame(List<List<List<int>>> firebaseCartillas) async {
    try {
      // print('DEBUG: Sincronizando ${firebaseCartillas.length} cartillas de Firebase con el juego local');
      
      // Sincronizar cartillas
      _bingoGame.syncCartillasFromFirebase(firebaseCartillas);
      
      // Verificar si hay bingo después de la sincronización
      final bingoCheck = _bingoGame.checkBingoInRealTime();
      if (bingoCheck['hasBingo'] == true) {
        if (kDebugMode) {
          print('¡BINGO detectado después de sincronización!');
          // print('${bingoCheck['message']}');
          // print('Cartillas ganadoras: ${bingoCheck['totalWinningCards']}');
        }
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error sincronizando cartillas de Firebase: $e');
      }
    }
  }
  
  // Método para verificar bingo en tiempo real
  Map<String, dynamic> checkBingoInRealTime() {
    return _bingoGame.checkBingoInRealTime();
  }

  // Método para verificar bingo solo para patrones de una ronda específica
  Map<String, dynamic> checkBingoForRoundPatterns(List<String> roundPatterns) {
    return _bingoGame.checkBingoForRoundPatterns(roundPatterns);
  }
} 