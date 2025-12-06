import re

# Leer archivo
with open('e:/bingo_patuju/lib/providers/app_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Corregir comillas escapadas incorrectamente
content = content.replace("\\'T\\'", "'T'")
content = content.replace("\\'Fecha cambiada a: $date\\'", "'Fecha cambiada a: $date'")

# 2. Actualizar assignFirebaseCartilla para incluir date
content = re.sub(
    r'(final cartillaData = await CartillaService\.assignCartilla\(cartillaId, vendorId)\);',
    r'\1, _selectedDate);',
    content
)

# 3. Actualizar deleteFirebaseCartilla para incluir date  
content = re.sub(
    r'(final success = await CartillaService\.deleteCartilla\(cartillaId)\);',
    r'\1, _selectedDate);',
    content
)

# 4. Actualizar generateFirebaseCartillas signature para aceptar date opcional
content = re.sub(
    r'Future<bool> generateFirebaseCartillas\(int count, \{String\? date\}\) async \{',
    r'Future<bool> generateFirebaseCartillas(int count) async {',
    content
)

# 5. Actualizar la llamada interna en generateFirebaseCartillas
content = re.sub(
    r'final result = await CartillaService\.generateCartillas\(count\);',
    r'final result = await CartillaService.generateCartillas(count, date: _selectedDate);',
    content
)

# Guardar archivo
with open('e:/bingo_patuju/lib/providers/app_provider.dart', 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)

print("✅ Errores de compilación corregidos:")
print("- Comillas escapadas arregladas")
print("- assignCartilla actualizado con _selectedDate")
print("- deleteCartilla actualizado con _selectedDate")
print("- generateFirebaseCartillas signature simplificada")
print("- generateCartillas call actualizado con date")
