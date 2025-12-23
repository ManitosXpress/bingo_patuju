import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bingo_game_config.dart';
import '../services/bingo_games_service.dart';
import '../models/firebase_bingo_game.dart';
import '../providers/app_provider.dart';

/// Diálogo para seleccionar un juego de bingo desde Firebase
/// Los juegos se agrupan por fecha
class GameSelectorDialog extends StatelessWidget {
  final BingoGameConfig? currentGame;
  final Function(BingoGameConfig) onGameSelected;

  const GameSelectorDialog({
    super.key,
    required this.currentGame,
    required this.onGameSelected,
  });

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Seleccionar Juego',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: FutureBuilder<List<FirebaseBingoGame>>(
                future: BingoGamesService().getAllBingoGames(date: appProvider.selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error cargando juegos',
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final games = snapshot.data ?? [];
                  
                  if (games.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'No hay juegos guardados',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea un juego nuevo para empezar',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // Agrupar juegos por fecha
                  final Map<String, List<FirebaseBingoGame>> gamesByDate = {};
                  for (final game in games) {
                    gamesByDate.putIfAbsent(game.date, () => []).add(game);
                  }
                  
                  // Ordenar fechas en orden descendente
                  final sortedDates = gamesByDate.keys.toList()
                    ..sort((a, b) => b.compareTo(a));
                  
                  return ListView.builder(
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final dateGames = gamesByDate[date]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Text(
                              date,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          ...dateGames.map((game) {
                            final isCurrent = currentGame?.id == game.id;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              color: isCurrent ? Colors.blue.shade50 : null,
                              child: ListTile(
                                leading: Icon(
                                  Icons.casino_outlined,
                                  color: isCurrent ? Colors.blue.shade700 : Colors.grey.shade600,
                                ),
                                title: Text(
                                  game.name,
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  '${game.rounds.length} rondas • ${game.totalCartillas} cartillas',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                trailing: isCurrent
                                    ? Icon(Icons.check_circle, color: Colors.blue.shade700)
                                    : null,
                                onTap: () {
                                  // Convertir FirebaseBingoGame a BingoGameConfig
                                  final config = BingoGameConfig(
                                    id: game.id,
                                    name: game.name,
                                    date: game.date,
                                    rounds: game.rounds.map((r) => BingoGameRound(
                                      id: r.id,
                                      name: r.name,
                                      patterns: r.patterns.map((p) {
                                        // Convertir string de patrón a BingoPattern enum
                                        return BingoPattern.values.firstWhere(
                                          (pattern) => pattern.toString() == p,
                                          orElse: () => BingoPattern.cartonLleno,
                                        );
                                      }).toList(),
                                      isCompleted: r.isCompleted,
                                    )).toList(),
                                  );
                                  
                                  onGameSelected(config);
                                },
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
