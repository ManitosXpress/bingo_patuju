import re

# Leer archivo
with open('e:/bingo_patuju/lib/providers/app_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Convertir CRLF a LF
content = content.replace('\r\n', '\n')

# 2. Agregar campo _selectedDate después de _isLoadingMore
content = re.sub(
    r'(bool _isLoadingMore = false;)\n',
    r'\1\n  \n  // Fecha seleccionada para cargar cartillas (formato YYYY-MM-DD)\n  String _selectedDate = DateTime.now().toIso8601String().split(\'T\')[0];\n',
    content,
    count=1
)

# 3. Agregar getter y setter después de los getters de paginación
content = re.sub(
    r'(bool get isLoadingMore => _isLoadingMore;)\n',
    r'\1\n  \n  // Getter para fecha seleccionada\n  String get selectedDate => _selectedDate;\n  \n  // Setter para cambiar fecha seleccionada\n  void setSelectedDate(String date) {\n    if (_selectedDate != date) {\n      _selectedDate = date;\n      debugLog(\'Fecha cambiada a: $date\');\n      // Recargar cartillas para la nueva fecha\n      loadFirebaseCartillas();\n      notifyListeners();\n    }\n  }\n',
    content,
    count=1
)

# 4. Actualizar la llamada a getCartillas para incluir date
content = re.sub(
    r'final cartillasData = await CartillaService\.getCartillas\(\n([ \t]+)assignedTo:',
    r'final cartillasData = await CartillaService.getCartillas(\n\1date: _selectedDate,\n\1assignedTo:',
    content,
    count=1
)

# 5. Actualizar generateFirebaseCartillas para usar _selectedDate
content = re.sub(
    r'(final result = await CartillaService\.generateCartillas\(count,) date: date\);',
    r'\1 date: _selectedDate);',
    content
)

# Guardar archivo
with open('e:/bingo_patuju/lib/providers/app_provider.dart', 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)

print("✅ Archivo actualizado correctamente")
print("- Convertido a LF line endings")
print("- Agregado campo _selectedDate")
print("- Agregado getter y setter")
print("- Actualizado getCartillas() con date parameter")
print("- Actualizado generateCartillas() para usar _selectedDate")
