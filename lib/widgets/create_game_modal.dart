import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/bingo_game.dart';
import '../models/bingo_game_config.dart';
import '../providers/app_provider.dart';

/// Modal profesional para crear juegos de bingo
/// Integrado con selectedDate del AppProvider
class CreateGameModal extends StatefulWidget {
  final Function(BingoGameConfig) onGameCreated;

  const CreateGameModal({
    Key? key,
    required this.onGameCreated,
  }) : super(key: key);

  @override
  State<CreateGameModal> createState() => _CreateGameModalState();
}

class _CreateGameModalState extends State<CreateGameModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<BingoGameRound> _rounds = [];
  int? _expandedRoundIndex;

  @override
  void initState() {
    super.initState();
    // Agregar una ronda por defecto
    _addRound();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addRound() {
    setState(() {
      _rounds.add(BingoGameRound(
        id: 'ronda_${_rounds.length + 1}',
        name: 'Ronda ${_rounds.length + 1}',
        patterns: [BingoPattern.cartonLleno],
      ));
      _expandedRoundIndex = _rounds.length - 1; // Expandir la nueva ronda
    });
  }

  void _removeRound(int index) {
    if (_rounds.length > 1) {
      setState(() {
        _rounds.removeAt(index);
        if (_expandedRoundIndex == index) {
          _expandedRoundIndex = null;
        } else if (_expandedRoundIndex != null && _expandedRoundIndex! > index) {
          _expandedRoundIndex = _expandedRoundIndex! - 1;
        }
      });
    }
  }

  void _updateRound(int index, BingoGameRound round) {
    setState(() {
      _rounds[index] = round;
    });
  }

  void _createGame(String selectedDate) {
    if (_formKey.currentState!.validate() && _rounds.isNotEmpty) {
      final newGame = BingoGameConfig(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        date: selectedDate, // Usar la fecha seleccionada
        rounds: List.from(_rounds),
      );

      widget.onGameCreated(newGame);
      Navigator.of(context).pop();
    }
  }

  String _getDayName(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      return dayNames[date.weekday - 1];
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _pickDate(BuildContext context, AppProvider appProvider) async {
    final initialDate = DateTime.tryParse(appProvider.selectedDate) ?? DateTime.now();
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Seleccionar fecha del evento',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final dateStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      
      // Actualizar el AppProvider con la nueva fecha
      appProvider.setSelectedDate(dateStr);
      
      // Recargar cartillas para la nueva fecha
      await appProvider.loadFirebaseCartillas(reset: true);
      
      // Forzar rebuild del widget
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final selectedDate = appProvider.selectedDate;
        final dayName = _getDayName(selectedDate);
        final formattedDate = _formatDate(selectedDate);
        final cartillasCount = appProvider.totalCartillas;
        final canCreate = cartillasCount > 0;

        return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crear Nuevo Juego',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _pickDate(context, appProvider),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '$dayName, $formattedDate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: canCreate ? Colors.white.withOpacity(0.25) : Colors.red.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        canCreate ? Icons.check_circle : Icons.warning,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        canCreate ? '$cartillasCount cartillas' : 'Sin cartillas',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección: Datos del Juego
                      _buildSectionCard(
                        title: 'Datos del Juego',
                        icon: Icons.gamepad,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre del Juego',
                            hintText: 'Ej: Bingo Especial',
                            prefixIcon: const Icon(Icons.edit),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un nombre';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sección: Rondas
                      _buildSectionCard(
                        title: 'Configuración de Rondas',
                        icon: Icons.layers,
                        child: Column(
                          children: [
                            // Lista de rondas añadidas
                            if (_rounds.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    'No hay rondas. Agrega una para comenzar.',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                              )
                            else
                              ..._rounds.asMap().entries.map((entry) {
                                final index = entry.key;
                                final round = entry.value;
                                final isExpanded = _expandedRoundIndex == index;

                                return _RoundCard(
                                  round: round,
                                  index: index,
                                  isExpanded: isExpanded,
                                  onExpand: () {
                                    setState(() {
                                      _expandedRoundIndex = isExpanded ? null : index;
                                    });
                                  },
                                  onUpdate: (updatedRound) => _updateRound(index, updatedRound),
                                  onRemove: () => _removeRound(index),
                                  canRemove: _rounds.length > 1,
                                );
                              }).toList(),

                            const SizedBox(height: 16),

                            // Botón Agregar Ronda
                            OutlinedButton.icon(
                              onPressed: _addRound,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Ronda'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green.shade700,
                                side: BorderSide(color: Colors.green.shade300, width: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer con botones
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: canCreate ? () => _createGame(selectedDate) : null,
                    icon: const Icon(Icons.check_circle),
                    label: Text(canCreate ? 'Crear Juego' : 'Sin Cartillas', style: const TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canCreate ? Colors.green.shade600 : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: canCreate ? 2 : 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

/// Tarjeta individual de ronda con diseño colapsable
class _RoundCard extends StatefulWidget {
  final BingoGameRound round;
  final int index;
  final bool isExpanded;
  final VoidCallback onExpand;
  final Function(BingoGameRound) onUpdate;
  final VoidCallback onRemove;
  final bool canRemove;

  const _RoundCard({
    required this.round,
    required this.index,
    required this.isExpanded,
    required this.onExpand,
    required this.onUpdate,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  State<_RoundCard> createState() => _RoundCardState();
}

class _RoundCardState extends State<_RoundCard> {
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

  List<BingoPattern> _getSortedPatterns() {
    final patterns = List<BingoPattern>.from(BingoPattern.values);
    patterns.sort((a, b) {
      final nameA = _getPatternDisplayName(a).toLowerCase();
      final nameB = _getPatternDisplayName(b).toLowerCase();
      return nameA.compareTo(nameB);
    });
    return patterns;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: widget.isExpanded ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.isExpanded ? Colors.green.shade300 : Colors.grey.shade200,
          width: widget.isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header colapsable
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              widget.round.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${widget.round.patterns.length} patrón(es) seleccionado(s)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.canRemove)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(Icons.delete, color: Colors.red.shade400),
                    tooltip: 'Eliminar',
                  ),
                IconButton(
                  onPressed: widget.onExpand,
                  icon: Icon(
                    widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  tooltip: widget.isExpanded ? 'Contraer' : 'Expandir',
                ),
              ],
            ),
          ),

          // Contenido expandible
          if (widget.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),

                  // Campo nombre
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Ronda',
                      prefixIcon: const Icon(Icons.label),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (_) => _updateRound(),
                  ),

                  const SizedBox(height: 20),

                  // Selector de patrones
                  Text(
                    'Selecciona los Patrones:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Grid de patrones
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _getSortedPatterns().length,
                    itemBuilder: (context, index) {
                      final pattern = _getSortedPatterns()[index];
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
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                size: 18,
                                color: isSelected ? Colors.green.shade600 : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _getPatternDisplayName(pattern),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getPatternDisplayName(BingoPattern pattern) {
    switch (pattern) {
      case BingoPattern.diagonalPrincipal:
        return 'Diagonal Principal';
      case BingoPattern.diagonalSecundaria:
        return 'Diagonal Secundaria';
      case BingoPattern.lineaHorizontal:
        return 'Línea Horizontal';
      case BingoPattern.lineaVertical:
        return 'Línea Vertical';
      case BingoPattern.marcoCompleto:
        return 'Marco Completo';
      case BingoPattern.marcoPequeno:
        return 'Marco Pequeño';
      case BingoPattern.spoutnik:
        return 'Spoutnik';
      case BingoPattern.corazon:
        return 'Corazón';
      case BingoPattern.cartonLleno:
        return 'Cartón Lleno';
      case BingoPattern.consuelo:
        return 'Consuelo';
      case BingoPattern.x:
        return 'X';
      case BingoPattern.figuraAvion:
        return 'Figura Avión';
      case BingoPattern.caidaNieve:
        return 'Caída de Nieve';
      case BingoPattern.arbolFlecha:
        return 'Árbol o Flecha';
      case BingoPattern.letraI:
        return 'LETRA I';
      case BingoPattern.letraN:
        return 'LETRA N';
      case BingoPattern.autopista:
        return 'Autopista';
      case BingoPattern.relojArena:
        return 'Reloj de Arena';
      case BingoPattern.dobleLineaV:
        return 'Doble Línea V';
      case BingoPattern.figuraSuegra:
        return 'La Suegra';
      case BingoPattern.figuraComodin:
        return 'Infinito';
      case BingoPattern.letraFE:
        return 'Letra FE';
      case BingoPattern.figuraCLoca:
        return 'C Loca';
      case BingoPattern.figuraBandera:
        return 'Bandera';
      case BingoPattern.figuraTripleLinea:
        return 'Triple Línea';
      case BingoPattern.diagonalDerecha:
        return 'Diagonal Derecha';
    }
  }
}
