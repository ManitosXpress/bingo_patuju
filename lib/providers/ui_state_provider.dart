import 'package:flutter/foundation.dart';

class UIStateProvider extends ChangeNotifier {
  // Estado de filtros
  bool _onlyUnsynced = false;
  bool _onlyUnassigned = false;
  bool _onlyAssigned = false;
  String? _filterVendorId;
  String _searchQuery = '';
  
  // Estado de selección
  final Set<String> _selectedCartillaIds = {}; // Cambiar a IDs en lugar de índices
  
  // Getters
  bool get onlyUnsynced => _onlyUnsynced;
  bool get onlyUnassigned => _onlyUnassigned;
  bool get onlyAssigned => _onlyAssigned;
  String? get filterVendorId => _filterVendorId;
  String get searchQuery => _searchQuery;
  Set<String> get selectedCartillaIds => _selectedCartillaIds; // Cambiar getter
  
  // Métodos para filtros
  void setOnlyUnsynced(bool value) {
    _onlyUnsynced = value;
    notifyListeners();
  }
  
  void setOnlyUnassigned(bool value) {
    _onlyUnassigned = value;
    notifyListeners();
  }
  
  void setOnlyAssigned(bool value) {
    _onlyAssigned = value;
    notifyListeners();
  }
  
  void setFilterVendorId(String? value) {
    _filterVendorId = value;
    notifyListeners();
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  // Métodos para selección usando IDs
  void toggleCartillaSelection(String cartillaId) {
    if (_selectedCartillaIds.contains(cartillaId)) {
      _selectedCartillaIds.remove(cartillaId);
    } else {
      _selectedCartillaIds.add(cartillaId);
    }
    notifyListeners();
  }
  
  void selectAllCartillas(List<String> cartillaIds) {
    _selectedCartillaIds.clear();
    _selectedCartillaIds.addAll(cartillaIds);
    notifyListeners();
  }
  
  void clearSelection() {
    _selectedCartillaIds.clear();
    notifyListeners();
  }
  
  void selectCartilla(String cartillaId) {
    _selectedCartillaIds.add(cartillaId);
    notifyListeners();
  }
  
  void unselectCartilla(String cartillaId) {
    _selectedCartillaIds.remove(cartillaId);
    notifyListeners();
  }
  
  bool isCartillaSelected(String cartillaId) {
    return _selectedCartillaIds.contains(cartillaId);
  }
  
  int get selectedCount => _selectedCartillaIds.length;
  
  // Método para resetear todos los filtros
  void resetFilters() {
    _onlyUnsynced = false;
    _onlyUnassigned = false;
    _onlyAssigned = false;
    _filterVendorId = null;
    _searchQuery = '';
    notifyListeners();
  }
  
  // Método para aplicar filtros por defecto
  void applyDefaultFilters() {
    _onlyUnsynced = false;
    _onlyUnassigned = false;
    _onlyAssigned = false; // Por defecto mostrar todas
    _filterVendorId = null;
    notifyListeners();
  }
} 