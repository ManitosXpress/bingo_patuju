import 'package:flutter/material.dart';
import '../models/bingo_game_config.dart';
import '../utils/bingo_pattern_names.dart';

/// Editor de ronda individual para el modal de creación/edición de juegos
class RoundEditor extends StatefulWidget {
  final BingoGameRound round;
  final Function(BingoGameRound) onUpdate;
  final VoidCallback onRemove;
  final bool canRemove;

  const RoundEditor({
    super.key,
    required this.round,
    required this.onUpdate,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  State<RoundEditor> createState() => _RoundEditorState();
}

class _RoundEditorState extends State<RoundEditor> {
  late TextEditingController _nameController;
  late List<BingoPattern> _selectedPatterns;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.round.name);
    _selectedPatterns = List.from(widget.round.patterns);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateRound() {
    final updatedRound = widget.round.copyWith(
      name: _nameController.text.trim(),
      patterns: _selectedPatterns,
    );
    widget.onUpdate(updatedRound);
  }

  /// Obtener patrones ordenados alfabéticamente por su nombre de visualización
  List<BingoPattern> _getSortedPatterns() {
    final patterns = List<BingoPattern>.from(BingoPattern.values);
    patterns.sort((a, b) {
      final nameA = getBingoPatternDisplayName(a).toLowerCase();
      final nameB = getBingoPatternDisplayName(b).toLowerCase();
      return nameA.compareTo(nameB);
    });
    return patterns;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Ronda',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateRound(),
                  ),
                ),
                if (widget.canRemove) ...[ 
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(Icons.delete, color: Colors.red.shade600),
                    tooltip: 'Eliminar Ronda',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              'Patrones:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getSortedPatterns().map((pattern) {
                final isSelected = _selectedPatterns.contains(pattern);
                return FilterChip(
                  label: Text(getBingoPatternDisplayName(pattern)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPatterns.add(pattern);
                      } else {
                        _selectedPatterns.remove(pattern);
                      }
                    });
                    _updateRound();
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade600,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
