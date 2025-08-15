import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/bingo_game.dart';

class CartillasStatsPanel extends StatelessWidget {
  final BingoGame bingoGame;

  const CartillasStatsPanel({
    super.key,
    required this.bingoGame,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final statusCount = appProvider.getCartillaStatusCount();
        final selectedCount = appProvider.selectedCount;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen del Estado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        'Total',
                        '${bingoGame.cartillas.length}',
                        Icons.grid_on,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _StatCard(
                        'Asignadas',
                        '${statusCount['assigned'] ?? 0}',
                        Icons.person,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _StatCard(
                        'Sin Asignar',
                        '${statusCount['unassigned'] ?? 0}',
                        Icons.person_off,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _StatCard(
                        'Sincronizadas',
                        '${statusCount['synced'] ?? 0}',
                        Icons.cloud_done,
                        Colors.teal,
                      ),
                    ),
                    Expanded(
                      child: _StatCard(
                        'Seleccionadas',
                        '$selectedCount',
                        Icons.check_circle,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 