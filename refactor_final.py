"""
Script definitivo para refactorizar bingo_games_panel.dart
- Verifica que tenga >1000 líneas
- Hace backup
- Elimina clases duplicadas ya extraídas
- Actualiza imports
- Actualiza referencias
"""

import re
import os

filepath = r'e:\bingo_patuju\lib\widgets\bingo_games_panel.dart'

# Leer archivo
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

lines_original = len(content.split('\n'))
print(f"📄 Líneas originales: {lines_original}")

if lines_original < 1000:
    print("✅ Archivo ya tiene menos de 1000 líneas")
    exit(0)

# Backup
backup_path = filepath + '.final_backup'
with open(backup_path, 'w', encoding='utf-8') as f:
    f.write(content)
print(f"✅ Backup creado: {os.path.basename(backup_path)}")

# 1. Verificar y agregar imports si no existen
imports_needed = [
    "import 'game_selector_dialog.dart';",
    "import 'edit_game_dialog.dart';",
    "import 'edit_round_dialog.dart';",
    "import 'round_editor.dart';",
    "import '../utils/bingo_pattern_names.dart';",
    "import '../services/bingo_games_service.dart';",
    "import '../models/firebase_bingo_game.dart';",
    "import 'create_game_modal.dart';"
]

for imp in imports_needed:
    if imp not in content:
        # Buscar después del último import antes de 'class BingoGamesPanel'
        pattern = r"(import '[^']+';)\s*\n\s*\nclass BingoGamesPanel"
        if re.search(pattern, content):
            content = re.sub(
                pattern,
                r"\1\n" + imp + "\n\nclass BingoGamesPanel",
                content,
                count=1
            )
            print(f"✅ Añadido: {imp}")

# 2. Reemplazar widgets privados por públicos
widget_replacements = [
    (r'\b_GameSelectorDialog\(', 'GameSelectorDialog('),
    (r'\b_EditGameDialog\(', 'EditGameDialog('),
    (r'\b_EditRoundDialog\(', 'EditRoundDialog('),
    (r'\b_RoundEditor\(', 'RoundEditor('),
    (r'_CreateGameDialog\(', 'CreateGameModal('),
]

for old, new in widget_replacements:
    count = len(re.findall(old, content))
    if count > 0:
        content = re.sub(old, new, content)
        print(f"✅ Reemplazado: {old} -> {new} ({count} veces)")

# 3. Eliminar definiciones de clases duplicadas
# Buscar posiciones de clases a eliminar
classes_to_remove_patterns = [
    (r'\/\/ Diálogo para seleccionar un juego existente\s*\nclass _GameSelectorDialog.*?(?=\n\/\/|\nclass [A-Z]|\Z)', 'GameSelectorDialog'),
    (r'\/\/ Editor de ronda individual\s*\nclass _RoundEditor.*?(?=\n\/\/|\nclass [A-Z]|\Z)', 'RoundEditor'),
    (r'\/\/ Diálogo para editar un juego existente\s*\nclass _EditGameDialog.*?(?=\n\/\/|\nclass [A-Z]|\Z)', 'EditGameDialog'),
    (r'\/\/ Diálogo para editar una ronda individual\s*\nclass _EditRoundDialog.*?(?=\n\/\/|\nclass [A-Z]|\Z)', 'EditRoundDialog'),
    (r'\/\/ Diálogo para crear un nuevo juego\s*\nclass _CreateGameDialog.*?(?=\n\/\/|\nclass [A-Z]|\Z)', 'CreateGameDialog'),
]

for pattern, name in classes_to_remove_patterns:
    matches = re.findall(pattern, content, re.DOTALL)
    if matches:
        content = re.sub(pattern, '', content, flags=re.DOTALL)
        print(f"✅ Removida clase duplicada: {name} (~{len(matches[0]) // 50} líneas)")

# 4. Limpiar líneas vacías múltiples
content = re.sub(r'\n{4,}', '\n\n\n', content)

# 5. Guardar
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

lines_final = len(content.split('\n'))
reduction = lines_original - lines_final

print(f"\n📊 Resultados:")
print(f"   Líneas originales: {lines_original}")
print(f"   Líneas finales: {lines_final}")
print(f"   Reducción: {reduction} líneas ({reduction/lines_original*100:.1f}%)")

if lines_final > 1000:
    print(f"\n⚠️  Advertencia: Archivo aún tiene {lines_final} líneas (> 1000)")
    print("   Considera extraer más componentes")
else:
    print(f"\n✅ Éxito: Archivo ahora tiene menos de 1000 líneas")

print(f"\n✅ Refactorización completada")
