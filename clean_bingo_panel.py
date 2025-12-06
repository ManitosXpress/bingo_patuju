"""
Script para limpiar y refactorizar bingo_games_panel.dart
Remueve código duplicado y actualiza imports
"""

import re

# Leer el archivo original
with open(r'e:\bingo_patuju\lib\widgets\bingo_games_panel.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Hacer backup
with open(r'e:\bingo_patuju\lib\widgets\bingo_games_panel.dart.backup', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Backup creado: bingo_games_panel.dart.backup")

# 1. Actualizar imports (agregar después de los imports existentes)
imports_to_add = """import 'game_selector_dialog.dart';
import 'edit_game_dialog.dart';
import 'edit_round_dialog.dart';
import 'round_editor.dart';
import '../utils/bingo_pattern_names.dart';
"""

# Buscar el último import y agregar los nuevos
import_pattern = r"(import '[^']+';)\s*\n\s*\nclass BingoGamesPanel"
if re.search(import_pattern, content):
    content = re.sub(
        import_pattern,
        r"\1\n" + imports_to_add + "\nclass BingoGamesPanel",
        content,
        count=1
    )
    print("✅ Imports agregados")
else:
    print("⚠️ No se pudo agregar imports automáticamente")

# 2. Reemplazar referencias a widgets privados con públicos
replacements = [
    (r'_GameSelectorDialog\b', 'GameSelectorDialog'),
    (r'_EditGameDialog\b', 'EditGameDialog'),
    (r'_EditRoundDialog\b', 'EditRoundDialog'),
    (r'_RoundEditor\b', 'RoundEditor'),
    (r'_getPatternDisplayName\(', 'getBingoPatternDisplayName('),
]

for old, new in replacements:
    count = len(re.findall(old, content))
    content = re.sub(old, new, content)
    if count > 0:
        print(f"✅ Reemplazado {old} -> {new} ({count} ocurrencias)")

# 3. Eliminar definiciones de clases duplicadas
classes_to_remove = [
    r'// Diálogo para seleccionar un juego existente.*?class _GameSelectorDialog.*?(?=\n\n// |class _|class [A-Z]|\Z)',
    r'// Diálogo para editar un juego existente.*?class _EditGameDialog.*?(?=\n\n// |class _|class [A-Z]|\Z)',
    r'// Diálogo para editar una ronda individual.*?class _EditRoundDialog.*?(?=\n\n// |class _|class [A-Z]|\Z)',
    r'// Editor de ronda individual.*?class _RoundEditor.*?(?=\n\n// |class _|class [A-Z]|\Z)',
    r'// Diálogo para crear un nuevo juego.*?class _CreateGameDialog.*?(?=\n\n// |class _|class [A-Z]|\Z)',
]

for pattern in classes_to_remove:
    matches = re.findall(pattern, content, re.DOTALL)
    if matches:
        content = re.sub(pattern, '', content, flags=re.DOTALL)
        print(f"✅ Removida clase duplicada")

# 4. Eliminar función _getPatternDisplayName duplicada
pattern_func_pattern = r'String _getPatternDisplayName\(BingoPattern pattern\).*?(?=\n  [a-zA-Z]|\nclass |\Z)'
matches = re.findall(pattern_func_pattern, content, re.DOTALL)
if matches:
    content = re.sub(pattern_func_pattern, '', content, flags=re.DOTALL)
    print(f"✅ Removida función _getPatternDisplayName duplicada ({len(matches)} ocurrencias)")

# 5. Limpiar líneas vacías múltiples
content = re.sub(r'\n{4,}', '\n\n\n', content)

# Escribir el archivo limpio
with open(r'e:\bingo_patuju\lib\widgets\bingo_games_panel.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Contar líneas finales
final_lines = len(content.split('\n'))
print(f"\n📊 Líneas finales: {final_lines}")
print(f"✅ Archivo refactorizado guardado")
