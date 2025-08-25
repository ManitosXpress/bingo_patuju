import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/firebase_bingo_game.dart';

/// Widget para mostrar y gestionar los juegos de bingo de Firebase
class FirebaseBingoGamesPanel extends StatefulWidget {
  const FirebaseBingoGamesPanel({super.key});

  @override
  State<FirebaseBingoGamesPanel> createState() => _FirebaseBingoGamesPanelState();
}

class _FirebaseBingoGamesPanelState extends State<FirebaseBingoGamesPanel> {
  @override
  void initState() {
    super.initState();
    // Cargar juegos de bingo al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.loadFirebaseBingoGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isLoadingBingoGames) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (appProvider.bingoGamesError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error cargando juegos',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  appProvider.bingoGamesError!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => appProvider.loadFirebaseBingoGames(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (appProvider.firebaseBingoGames.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.games_outlined,
                  color: Colors.grey,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay juegos de bingo',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Los juegos que crees se guardarán automáticamente en Firebase',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header con estadísticas
            _buildHeader(appProvider),
            const SizedBox(height: 16),
            
            // Lista de juegos
            Expanded(
              child: _buildGamesList(appProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(AppProvider appProvider) {
    final totalGames = appProvider.firebaseBingoGames.length;
    final completedGames = appProvider.firebaseBingoGames
        .where((game) => game.isCompleted)
        .length;
    final activeGames = totalGames - completedGames;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Juegos',
              totalGames.toString(),
              Icons.games,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Juegos Activos',
              activeGames.toString(),
              Icons.play_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Completados',
              completedGames.toString(),
              Icons.check_circle,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList(AppProvider appProvider) {
    return ListView.builder(
      itemCount: appProvider.firebaseBingoGames.length,
      itemBuilder: (context, index) {
        final game = appProvider.firebaseBingoGames[index];
        return _buildGameCard(game, appProvider);
      },
    );
  }

  Widget _buildGameCard(FirebaseBingoGame game, AppProvider appProvider) {
    final isCompleted = game.isCompleted;
    final roundsCount = game.rounds.length;
    final completedRounds = game.rounds
        .where((round) => round.isCompleted)
        .length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _showGameDetails(game, appProvider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del juego
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fecha: ${game.date}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Estado del juego
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCompleted ? Colors.green.shade300 : Colors.blue.shade300,
                      ),
                    ),
                    child: Text(
                      isCompleted ? 'Completado' : 'Activo',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isCompleted ? Colors.green.shade700 : Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información de rondas
              Row(
                children: [
                  Expanded(
                    child: _buildRoundInfo(
                      'Total Rondas',
                      roundsCount.toString(),
                      Icons.loop,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRoundInfo(
                      'Completadas',
                      completedRounds.toString(),
                      Icons.check,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRoundInfo(
                      'Cartillas',
                      game.totalCartillas.toString(),
                      Icons.style,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Barra de progreso
              LinearProgressIndicator(
                value: roundsCount > 0 ? completedRounds / roundsCount : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : Colors.blue,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    'Ver Detalles',
                    Icons.visibility,
                    Colors.blue,
                    () => _showGameDetails(game, appProvider),
                  ),
                  _buildActionButton(
                    'Editar',
                    Icons.edit,
                    Colors.orange,
                    () => _editGame(game, appProvider),
                  ),
                  _buildActionButton(
                    'Eliminar',
                    Icons.delete,
                    Colors.red,
                    () => _deleteGame(game, appProvider),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundInfo(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.shade50,
            foregroundColor: color.shade700,
            side: BorderSide(color: color.shade200),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  void _showGameDetails(FirebaseBingoGame game, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${game.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fecha: ${game.date}'),
              Text('Total Cartillas: ${game.totalCartillas}'),
              Text('Estado: ${game.isCompleted ? "Completado" : "Activo"}'),
              const SizedBox(height: 16),
              Text(
                'Rondas (${game.rounds.length}):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...game.rounds.map((round) => ListTile(
                leading: Icon(
                  round.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: round.isCompleted ? Colors.green : Colors.grey,
                ),
                title: Text(round.name),
                subtitle: Text('${round.patterns.length} patrones'),
                trailing: Text(
                  round.isCompleted ? 'Completada' : 'Pendiente',
                  style: TextStyle(
                    color: round.isCompleted ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _editGame(FirebaseBingoGame game, AppProvider appProvider) {
    // TODO: Implementar edición de juego
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edición de ${game.name} - Funcionalidad en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteGame(FirebaseBingoGame game, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el juego "${game.name}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await appProvider.deleteBingoGame(game.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${game.name} eliminado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error eliminando juego: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
