import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/bingo_game.dart';

class CartillasFiltersPanel extends StatefulWidget {
  final BingoGame bingoGame;

  const CartillasFiltersPanel({
    super.key,
    required this.bingoGame,
  });

  @override
  State<CartillasFiltersPanel> createState() => _CartillasFiltersPanelState();
}

class _CartillasFiltersPanelState extends State<CartillasFiltersPanel> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros y Controles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Primera fila de filtros
            _buildFilterCheckboxes(),
            
            const SizedBox(height: 16),
            
            // Segunda fila: búsqueda y vendedor
            _buildSearchAndVendorRow(),
            
            const SizedBox(height: 16),
            
            // Tercera fila: Panel de control unificado
            _buildUnifiedControls(),
            
            const SizedBox(height: 12),
            
            // Sexta fila: información de paginación y navegación
            _buildPaginationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCheckboxes() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Solo No Sincronizadas'),
                value: appProvider.onlyUnsynced,
                onChanged: (value) {
                  appProvider.setOnlyUnsynced(value ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Solo Sin Asignar'),
                value: appProvider.onlyUnassigned,
                onChanged: (value) {
                  appProvider.setOnlyUnassigned(value ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Solo Asignadas'),
                value: appProvider.onlyAssigned,
                onChanged: (value) {
                  appProvider.setOnlyAssigned(value ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndVendorRow() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Sincronizar el controlador con el provider si el texto cambió externamente
        if (_searchController.text != appProvider.searchQuery) {
          _searchController.value = _searchController.value.copyWith(
            text: appProvider.searchQuery,
            selection: TextSelection.collapsed(offset: appProvider.searchQuery.length),
            composing: TextRange.empty,
          );
        }
        
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar por número de cartilla',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  appProvider.setSearchQuery(value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Asignar a...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_add),
                ),
                value: appProvider.selectedVendorId,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Seleccionar vendedor'),
                  ),
                  ...appProvider.vendors.map((vendor) {
                    return DropdownMenuItem<String>(
                      value: vendor['id'] as String,
                      child: Text(vendor['name'] as String),
                    );
                  }),
                ],
                onChanged: (value) {
                  appProvider.setSelectedVendor(value);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnifiedControls() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Column(
          children: [
            // Fila 1: Acciones Generales y Utilidades
            Row(
              children: [
                // Nueva Cartilla
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                     onPressed: () async {
                      final textController = TextEditingController(text: '1');
                      DateTime selectedDate = DateTime.now();
                      
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => StatefulBuilder(
                          builder: (context, setState) => AlertDialog(
                            title: const Text('Generar Cartillas'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('¿Cuántas cartillas quieres generar? (0-10000):'),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: textController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Ej: 10',
                                    prefixIcon: Icon(Icons.numbers),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => (context as Element).markNeedsBuild(),
                                ),
                                const SizedBox(height: 24),
                                const Text('Fecha del evento:'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        selectedDate = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final count = int.tryParse(textController.text);
                                  if (count != null && count >= 0 && count <= 10000) {
                                    Navigator.pop(context, true);
                                  }
                                },
                                child: const Text('Generar'),
                              ),
                            ],
                          ),
                        ),
                      );
                      
                      if (confirmed == true) {
                        final count = int.tryParse(textController.text) ?? 1;
                        final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                        
                        // Actualizar la fecha seleccionada en el AppProvider
                        appProvider.setSelectedDate(dateStr);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('🃏 Generando $count cartilla${count > 1 ? 's' : ''} para $dateStr...'), duration: const Duration(seconds: 2)),
                          );
                        }
                        final success = await appProvider.generateFirebaseCartillas(count);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('✅ Se generaron $count cartilla${count > 1 ? 's' : ''} exitosamente'), backgroundColor: Colors.green),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('❌ Error al generar las cartillas'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Utilidades (Iconos)
                Tooltip(
                  message: 'Seleccionar Todas',
                  child: IconButton.outlined(
                    onPressed: () {
                      final cartillaIds = appProvider.firebaseCartillas.map((c) => c.id).toList();
                      appProvider.selectAllCartillas(cartillaIds);
                    },
                    icon: const Icon(Icons.select_all),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Limpiar Filtros',
                  child: IconButton.outlined(
                    onPressed: () => appProvider.resetFilters(),
                    icon: const Icon(Icons.clear_all),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Filtros por Defecto',
                  child: IconButton.outlined(
                    onPressed: () => appProvider.applyDefaultFilters(),
                    icon: const Icon(Icons.settings_backup_restore),
                  ),
                ),
                const SizedBox(width: 8),
                // Eliminar Todas (Peligroso)
                Tooltip(
                  message: 'ELIMINAR TODAS',
                  child: IconButton.filled(
                    onPressed: () async {
                      final textController = TextEditingController();
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('⚠️ ADVERTENCIA CRÍTICA'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Escribe "ELIMINAR" para borrar TODAS las cartillas permanentemente.'),
                              const SizedBox(height: 16),
                              TextField(
                                controller: textController,
                                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'ELIMINAR'),
                                onChanged: (value) => (context as Element).markNeedsBuild(),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                            ElevatedButton(
                              onPressed: textController.text == 'ELIMINAR' ? () => Navigator.pop(context, true) : null,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
                              child: const Text('Confirmar'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        final finalConfirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmación Final'),
                            content: const Text('¿Estás 100% seguro? No hay vuelta atrás.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
                                child: const Text('SÍ, ELIMINAR'),
                              ),
                            ],
                          ),
                        );
                        
                        if (finalConfirmed == true) {
                          final success = await appProvider.clearAllFirebaseCartillas();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? '✅ Todas las cartillas eliminadas' : '❌ Error al eliminar'), backgroundColor: success ? Colors.green : Colors.red),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_forever),
                    style: IconButton.styleFrom(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Fila 2: Acciones de Selección
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: appProvider.selectedCount > 0 && appProvider.selectedVendorId != null
                        ? () {
                            for (String cartillaId in appProvider.selectedCartillaIds) {
                              final firebaseCartilla = appProvider.firebaseCartillas.firstWhere(
                                (fc) => fc.id == cartillaId,
                                orElse: () => appProvider.allFirebaseCartillas.firstWhere(
                                  (fc) => fc.id == cartillaId,
                                  orElse: () => throw Exception('Cartilla no encontrada'),
                                ),
                              );
                              appProvider.assignFirebaseCartilla(firebaseCartilla.id, appProvider.selectedVendorId!);
                            }
                            appProvider.clearSelection();
                          }
                        : null,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Asignar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: appProvider.selectedCount > 0
                        ? () {
                            for (String cartillaId in appProvider.selectedCartillaIds) {
                              final firebaseCartilla = appProvider.firebaseCartillas.firstWhere(
                                (fc) => fc.id == cartillaId,
                                orElse: () => appProvider.allFirebaseCartillas.firstWhere(
                                  (fc) => fc.id == cartillaId,
                                  orElse: () => throw Exception('Cartilla no encontrada'),
                                ),
                              );
                              appProvider.unassignFirebaseCartilla(firebaseCartilla.id);
                            }
                            appProvider.clearSelection();
                          }
                        : null,
                    icon: const Icon(Icons.person_remove),
                    label: const Text('Desasignar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: appProvider.selectedCount > 0
                        ? () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmar Eliminación'),
                                content: Text('¿Eliminar ${appProvider.selectedCount} cartillas seleccionadas?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              for (String cartillaId in appProvider.selectedCartillaIds) {
                                final firebaseCartilla = appProvider.firebaseCartillas.firstWhere(
                                  (fc) => fc.id == cartillaId,
                                  orElse: () => appProvider.allFirebaseCartillas.firstWhere(
                                    (fc) => fc.id == cartillaId,
                                    orElse: () => throw Exception('Cartilla no encontrada'),
                                  ),
                                );
                                await appProvider.deleteFirebaseCartilla(firebaseCartilla.id);
                              }
                              appProvider.clearSelection();
                              await appProvider.autoReloadIfNeeded();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cartillas eliminadas correctamente'), backgroundColor: Colors.green),
                                );
                              }
                            }
                          }
                        : null,
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaginationInfo() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Row(
          children: [
            Expanded(
              child: Text(
                'Página ${appProvider.currentPage} de ${appProvider.totalPages} (${appProvider.totalCartillas} cartillas total)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: appProvider.hasPreviousPage
                        ? () {
                            appProvider.goToPreviousPage();
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  IconButton(
                    onPressed: appProvider.hasNextPage
                        ? () {
                            appProvider.loadMoreCartillas();
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
} 