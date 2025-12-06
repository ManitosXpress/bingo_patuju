import re

# Leer archivo
with open('e:/bingo_patuju/lib/services/bingo_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Reemplazar eventId con date en todos los métodos
content = re.sub(r'Future<String> saveBingoGame\(String eventId,', r'Future<String> saveBingoGame(String date,', content)
content = re.sub(r'Future<void> updateBingoGame\(String eventId,', r'Future<void> updateBingoGame(String date,', content)
content = re.sub(r'Future<List<FirebaseBingoGame>> getEventGames\(String eventId\)', r'Future<List<FirebaseBingoGame>> getEventGames(String date)', content)
content = re.sub(r'Future<FirebaseBingoGame\?> getBingoGameById\(String eventId,', r'Future<FirebaseBingoGame?> getBingoGameById(String date,', content)
content = re.sub(r'Future<void> deleteBingoGame\(String eventId,', r'Future<void> deleteBingoGame(String date,', content)
content = re.sub(r'Future<void> saveRound\(String eventId,', r'Future<void> saveRound(String date,', content)
content = re.sub(r'Future<void> deleteRound\(String eventId,', r'Future<void> deleteRound(String date,', content)
content = re.sub(r'Future<void> markRoundAsCompleted\(String eventId,', r'Future<void> markRoundAsCompleted(String date,', content)
content = re.sub(r'Stream<List<FirebaseBingoGame>> watchEventGames\(String eventId\)', r'Stream<List<FirebaseBingoGame>> watchEventGames(String date)', content)

# Reemplazar usos de eventId dentro de los métodos
content = re.sub(r'\.doc\(eventId\)', r'.doc(date)', content)
content = re.sub(r'await updateBingoGame\(eventId,', r'await updateBingoGame(date,', content)
content = re.sub(r'await getBingoGameById\(eventId,', r'await getBingoGameById(date,', content)

# Actualizar comentarios
content = re.sub(r'/// Guardar un juego de bingo en un evento específico', r'/// Guardar un juego de bingo en una fecha específica\n  /// @param date - Fecha en formato YYYY-MM-DD (ej: "2025-12-09")', content)
content = re.sub(r'/// Obtener todos los juegos de un evento', r'/// Obtener todos los juegos de una fecha', content)
content = re.sub(r'print\(\'DEBUG: \$\{games\.length\} juegos de bingo cargados del evento \$eventId\'\);', r'print(\'DEBUG: ${games.length} juegos de bingo cargados de la fecha $date\');', content)
content = re.sub(r'print\(\'DEBUG: Juego de bingo guardado exitosamente: \$\{game\.name\} en evento \$eventId\'\);', r'print(\'DEBUG: Juego de bingo guardado exitosamente: ${game.name} en fecha $date\');', content)

# Guardar archivo
with open('e:/bingo_patuju/lib/services/bingo_games_service.dart', 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)

print("✅ BingoGamesService actualizado:")
print("- Todos los parámetros eventId renombrados a date")
print("- Comentarios actualizados")
print("- Mensajes de debug actualizados")
