"""
Script final para reducir bingo_games_panel.dart a < 1000 líneas
Extrae los métodos build más grandes a archivos separados
"""

import re

filepath = r'e:\bingo_patuju\lib\widgets\bingo_games_panel.dart'

# Leer archivo
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()
    lines = content.split('\n')

print(f"📄 Líneas originales: {len(lines)}")

# Backup
backup_path = filepath + '.pre_build_extraction'
with open(backup_path, 'w', encoding='utf-8') as f:
    f.write(content)
print(f"✅ Backup creado: pre_build_extraction")

# Métodos a evaluar para reducción
methods_to_check = [
    ('_buildGameInfo', 852, 946),  # ~95 líneas
    ('_buildRoundsList', 948, 1136),  # ~189 líneas  
    ('_buildCurrentRoundInfo', 1138, 1307),  # ~170 líneas
]

total_to_reduce = sum(end - start + 1 for _, start, end in methods_to_check)
current_lines = len(lines)
estimated_final = current_lines - total_to_reduce + (len(methods_to_check) * 5)  # +5 por cada llamada de método

print(f"\n📊 Análisis:")
for name, start, end in methods_to_check:
    print(f"   {name}: líneas {start}-{end} (~{end-start+1} líneas)")

print(f"\n   Total a reducir: ~{total_to_reduce} líneas")
print(f"   Estimado final: ~{estimated_final} líneas")

if estimated_final > 1000:
    print(f"\n⚠️  Aún quedarían {estimated_final} líneas (> 1000)")
    print("   Se necesita más refactorización")
else:
    print(f"\n✅ Alcanzaríamos el objetivo (<1000 líneas)")

print("\nNOTA: Estos métodos necesitan ser reconvertidos a widgets Stateless/Stateful")
print("para poder ser extraídos correctamente. Esta es una tarea manual que requiere:")
print("- Identificar dependencias de estado (_selectedGame, _currentRoundIndex, etc.)")
print("- Pasar esas dependencias como parámetros al nuevo widget")
print("- Crear constructores apropiados")
print("\nRecomendación: Hacer esto manualmente o en pasos más controlados")
