"""
Script para eliminar clases duplicadas de bingo_games_panel.dart
mantener solo las referencias
"""

import re

# Leer el archivo
with open(r'e:\bingo_patuju\lib\widgets\bingo_games_panel.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f"📄 Líneas originales: {len(lines)}")

# Crear backup
with open(r'e:\bingo_patuju\lib\widgets\bingo_games_panel.dart.backup2', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ Backup creado: bingo_games_panel.dart.backup2")

# Buscar y marcar líneas a eliminar
lines_to_keep = []
skip_until = None
classes_removed = []

i = 0
while i < len(lines):
    line = lines[i]
    
    # Detectar inicio de clases a eliminar
    if '// Diálogo para seleccionar un juego existente' in line:
        # Buscar el final de la clase _GameSelectorDialog
        skip_until = '_GameSelectorDialog'
        classes_removed.append('_GameSelectorDialog')
        i += 1
        continue
    
    elif '// Editor de ronda individual' in line and 'class _RoundEditor' in ''.join(lines[i:i+5]):
        skip_until = '_RoundEditor'
        classes_removed.append('_RoundEditor')
        i += 1
        continue
    
    elif '// Diálogo para editar un juego existente' in line:
        skip_until = '_EditGameDialog'
        classes_removed.append('_EditGameDialog')
        i += 1
        continue
    
    elif '// Diálogo para editar una ronda individual' in line:
        skip_until = '_EditRoundDialog'
        classes_removed.append('_EditRoundDialog')
        i += 1
        continue
    
    # Si estamos saltando una clase
    if skip_until:
        # Buscar el cierre de la clase (línea que empieza con '}' y no tiene nada más significativo después)
        if line.strip() == '}' and i + 1 < len(lines):
            # Verificar si la siguiente línea es el inicio de algo nuevo
            next_line = lines[i + 1].strip()
            if (next_line == '' or 
                next_line.startswith('//') or 
                next_line.startswith('class ') or
                i + 1 >= len(lines) - 1):
                print(f"✅ Removida clase: {skip_until}")
                skip_until = None
                i += 1
                continue
        i += 1
        continue
    
    # Mantener la línea
    lines_to_keep.append(line)
    i += 1

print(f"\n📊 Líneas después de remover clases: {len(lines_to_keep)}")
print(f"🗑️ Clases removidas: {', '.join(set(classes_removed))}")

# Escribir archivo limpio
with open(r'e:\bingo_patuju\lib\widgets\bingo_games_panel.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines_to_keep)

print("✅ Archivo actualizado")
