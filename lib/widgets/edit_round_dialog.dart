import 'package:flutter/material.dart';
import '../models/bingo_game_config.dart';
import '../utils/bingo_pattern_names.dart';

/// Diálogo para editar una ronda individual de un juego de bingo
class EditRoundDialog extends StatefulWidget {
  final BingoGameRound round;
  final Function(BingoGameRound) onRoundUpdated;

  const EditRoundDialog({
    super.key,
    required this.round,
    required this.onRoundUpdated,
  });

  @override
  State<EditRoundDialog> createState() => _EditRoundDialogState();
}

class _EditRoundDialogState extends State<EditRoundDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<BingoPattern> _selectedPatterns;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.round.name);
    _descriptionController = TextEditingController(text: widget.round.description ?? '');
    _selectedPatterns = List.from(widget.round.patterns);
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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_nameController.text.trim().isNotEmpty && _selectedPatterns.isNotEmpty) {
      final updatedRound = widget.round.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        patterns: List.from(_selectedPatterns),
      );
      
      widget.onRoundUpdated(updatedRound);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.orange.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Editar Ronda: ${widget.round.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre de la ronda
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Ronda',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Juego 1, Consuelo, etc.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Descripción de la ronda
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (Opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Descripción detallada de la ronda',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    
                    // Patrones de la ronda
                    Text(
                      'Patrones de la Ronda:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      'Selecciona las figuras que se deben completar para ganar esta ronda:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Grid de patrones seleccionables (ordenados alfabéticamente)
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
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: Colors.orange.shade100,
                          checkmarkColor: Colors.orange.shade600,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.orange.shade700 : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vista previa de la ronda
                    if (_selectedPatterns.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vista Previa:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nombre: ${_nameController.text.trim().isEmpty ? "Sin nombre" : _nameController.text.trim()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Patrones: ${_selectedPatterns.map((p) => getBingoPatternDisplayName(p)).join(', ')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (_descriptionController.text.trim().isNotEmpty)
                              Text(
                                'Descripción: ${_descriptionController.text.trim()}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedPatterns.isNotEmpty && _nameController.text.trim().isNotEmpty
                      ? _saveChanges
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar Cambios'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
