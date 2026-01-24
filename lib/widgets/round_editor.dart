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

  List<List<int>> _getPatternMatrix(BingoPattern pattern) {
    switch (pattern) {
      case BingoPattern.lineaHorizontal:
        return [[1,1,1,1,1], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0]];
      case BingoPattern.lineaVertical:
        return [[1,0,0,0,0], [1,0,0,0,0], [1,0,0,0,0], [1,0,0,0,0], [1,0,0,0,0]];
      case BingoPattern.diagonalPrincipal:
        return [[1,0,0,0,0], [0,1,0,0,0], [0,0,1,0,0], [0,0,0,1,0], [0,0,0,0,1]];
      case BingoPattern.diagonalSecundaria:
        return [[0,0,0,0,1], [0,0,0,1,0], [0,0,1,0,0], [0,1,0,0,0], [1,0,0,0,0]];
      case BingoPattern.cartonLleno:
        return List.generate(5, (_) => List.filled(5, 1));
      case BingoPattern.figuraAvion:
        return [[1,0,0,0,1], [0,1,0,1,0], [0,0,1,0,0], [0,1,0,1,0], [1,0,0,0,1]];
      case BingoPattern.x:
        return [[1,0,0,0,1], [0,1,0,1,0], [0,0,1,0,0], [0,1,0,1,0], [1,0,0,0,1]];
      case BingoPattern.marcoCompleto:
        return [[1,1,1,1,1], [1,0,0,0,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1]];
      case BingoPattern.corazon:
        return [[0,1,0,1,0], [1,0,1,0,1], [1,0,0,0,1], [0,1,0,1,0], [0,0,1,0,0]];
      case BingoPattern.caidaNieve:
        return [[0,0,1,0,0], [0,1,0,1,0], [1,0,1,0,1], [0,1,0,1,0], [0,0,1,0,0]];
      case BingoPattern.marcoPequeno:
        return [[0,0,0,0,0], [0,1,1,1,0], [0,1,0,1,0], [0,1,1,1,0], [0,0,0,0,0]];
      case BingoPattern.arbolFlecha:
        return [[0,0,1,0,0], [0,1,1,1,0], [1,1,1,1,1], [0,0,1,0,0], [0,0,1,0,0]];
      case BingoPattern.spoutnik:
        return [[1,0,0,0,1], [0,0,1,0,0], [0,1,0,1,0], [0,0,1,0,0], [1,0,0,0,1]];
      case BingoPattern.letraI:
        return [[0,1,1,1,0], [0,0,1,0,0], [0,0,1,0,0], [0,0,1,0,0], [0,1,1,1,0]];
      case BingoPattern.letraN:
        return [[1,0,0,0,1], [1,1,0,0,1], [1,0,1,0,1], [1,0,0,1,1], [1,0,0,0,1]];
      case BingoPattern.autopista:
        return [[0,1,0,1,0], [0,1,0,1,0], [0,1,0,1,0], [0,1,0,1,0], [0,1,0,1,0]];
      case BingoPattern.relojArena:
        return [[1,1,1,1,1], [0,1,1,1,0], [0,0,1,0,0], [0,1,1,1,0], [1,1,1,1,1]];
      case BingoPattern.dobleLineaV:
        return [[1,0,0,0,1], [0,1,0,1,0], [0,0,1,0,0], [0,1,0,1,0], [1,0,0,0,1]];
      case BingoPattern.figuraSuegra:
        return [[1,0,1,0,1], [0,1,0,1,0], [1,0,1,0,1], [0,1,0,1,0], [1,0,1,0,1]];
      case BingoPattern.figuraComodin: // Infinito
        return [[1,0,1,0,1], [0,1,0,1,0], [1,1,1,1,1], [0,1,0,1,0], [1,0,1,0,1]];
      case BingoPattern.letraFE:
        return [[1,1,1,1,0], [1,0,0,0,0], [1,1,1,0,0], [1,0,0,0,0], [1,0,0,0,0]];
      case BingoPattern.figuraCLoca:
        return [[1,0,0,0,1], [1,0,0,0,1], [1,0,1,0,1], [1,0,0,0,1], [1,0,0,0,1]];
      case BingoPattern.figuraBandera:
        return [[1,1,1,1,1], [1,1,1,1,1], [1,1,1,1,1], [0,0,1,1,1], [0,0,1,1,1]];
      case BingoPattern.figuraTripleLinea:
        return [[1,1,1,1,1], [0,0,0,0,0], [1,1,1,1,1], [0,0,0,0,0], [1,1,1,1,1]];
      case BingoPattern.cactus:
        return [[1,0,1,0,1], [1,0,1,0,1], [1,1,1,1,1], [0,0,1,0,0], [0,0,1,0,0]];
      case BingoPattern.silla:
        return [[1,0,0,0,0], [1,0,0,0,0], [1,1,1,1,1], [1,0,0,0,1], [1,0,0,0,1]];
      case BingoPattern.sieteDeLaSuerte:
        return [[1,1,1,1,1], [0,0,0,1,0], [0,0,1,0,0], [0,1,0,0,0], [1,0,0,0,0]];
      case BingoPattern.cometa:
        return [[1,1,0,0,0], [1,1,0,0,0], [0,0,1,0,0], [0,0,0,1,0], [0,0,0,0,1]];
      case BingoPattern.sombrero:
        return [[0,0,0,0,0], [0,1,1,1,0], [0,1,1,1,0], [1,1,1,1,1], [0,0,0,0,0]];
      case BingoPattern.mancuerna:
        return [[0,0,0,0,0], [0,1,0,1,0], [1,1,1,1,1], [0,1,0,1,0], [0,0,0,0,0]];
      case BingoPattern.mesa:
        return [[0,0,0,0,0], [1,1,1,1,1], [0,0,1,0,0], [0,1,0,1,0], [1,0,0,0,1]];
      default:
        return List.generate(5, (_) => List.filled(5, 0));
    }
  }

  Widget _patternMiniGrid(List<List<int>> pattern, Color color, double size) {
    final cellSize = size / 5;
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        children: List.generate(5, (row) {
          return Row(
            children: List.generate(5, (col) {
              bool isActive = pattern[row][col] == 1;
              return Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.grey.shade200,
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
              );
            }),
          );
        }),
      ),
    );
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
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedPatterns.remove(pattern);
                      } else {
                        _selectedPatterns.add(pattern);
                      }
                    });
                    _updateRound();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: (MediaQuery.of(context).size.width < 600) 
                        ? (MediaQuery.of(context).size.width - 60) / 2 // 2 columnas en móvil
                        : 200, // Ancho fijo en desktop
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.shade50 : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected ? Colors.green.shade400 : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green.shade600,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            getBingoPatternDisplayName(pattern),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _patternMiniGrid(
                          _getPatternMatrix(pattern),
                          isSelected ? Colors.green.shade600 : Colors.grey.shade400,
                          40,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
