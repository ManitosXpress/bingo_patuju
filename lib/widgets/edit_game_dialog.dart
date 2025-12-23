import 'package:flutter/material.dart';
import '../models/bingo_game_config.dart';
import 'round_editor.dart';

/// Diálogo para editar un juego de bingo existente
class EditGameDialog extends StatefulWidget {
  final BingoGameConfig game;
  final Function(BingoGameConfig) onGameUpdated;

  const EditGameDialog({
    super.key,
    required this.game,
    required this.onGameUpdated,
  });

  @override
  State<EditGameDialog> createState() => _EditGameDialogState();
}

class _EditGameDialogState extends State<EditGameDialog> {
  late BingoGameConfig _editedGame;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String _selectedDay;
  late List<BingoGameRound> _rounds;
  
  @override
  void initState() {
    super.initState();
    // Crear una copia del juego para editar
    _editedGame = widget.game.copyWith();
    _nameController.text = _editedGame.name;
    _selectedDay = _editedGame.date;
    _rounds = List.from(_editedGame.rounds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addRound() {
    setState(() {
      _rounds.add(BingoGameRound(
        id: 'ronda_${_rounds.length + 1}_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Ronda ${_rounds.length + 1}',
        patterns: [BingoPattern.cartonLleno],
      ));
    });
  }

  void _removeRound(int index) {
    if (_rounds.length > 1) {
      setState(() {
        _rounds.removeAt(index);
      });
    }
  }

  void _updateRound(int index, BingoGameRound round) {
    setState(() {
      _rounds[index] = round;
    });
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate() && _rounds.isNotEmpty) {
      final updatedGame = _editedGame.copyWith(
        name: _nameController.text.trim(),
        date: _selectedDay,
        rounds: List.from(_rounds),
      );
      
      // Actualizar el juego en la lista de presets
      final gameIndex = BingoGamePresets.defaultGames.indexWhere((g) => g.id == widget.game.id);
      if (gameIndex != -1) {
        BingoGamePresets.defaultGames[gameIndex] = updatedGame;
      }
      
      widget.onGameUpdated(updatedGame);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Editar Juego: ${widget.game.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del juego
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Juego',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Fecha del evento
                      TextFormField(
                        initialValue: _selectedDay,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Fecha del Evento',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          // Implementación opcional para cambiar la fecha si se desea
                          // Por ahora solo visualización ya que el error era con el Dropdown
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Título de las rondas
                      Row(
                        children: [
                          Text(
                            'Rondas del Juego (${_rounds.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _addRound,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Agregar Ronda'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Lista de rondas
                      ...(_rounds.asMap().entries.map((entry) {
                        final index = entry.key;
                        final round = entry.value;
                        return RoundEditor(
                          round: round,
                          onUpdate: (updatedRound) => _updateRound(index, updatedRound),
                          onRemove: () => _removeRound(index),
                          canRemove: _rounds.length > 1,
                        );
                      }).toList()),
                    ],
                  ),
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
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
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
