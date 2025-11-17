import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/bingo_game.dart';

class CartillasFiltersPanel extends StatelessWidget {
  final BingoGame bingoGame;

  const CartillasFiltersPanel({
    super.key,
    required this.bingoGame,
  });

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
            
            // Tercera fila: botones de acción
            _buildActionButtons(),
            
            const SizedBox(height: 12),
            
            // Cuarta fila: botones de asignación
            _buildAssignmentButtons(),
            
            const SizedBox(height: 12),
            
            // Quinta fila: botones de utilidad
            _buildUtilityButtons(),
            
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
        final textController = TextEditingController(text: appProvider.searchQuery);
        
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: textController,
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

  Widget _buildActionButtons() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return const SizedBox.shrink(); // Botones eliminados
      },
    );
  }

  Widget _buildAssignmentButtons() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Column(
          children: [
            // Primera fila: Asignar y Desasignar
            Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: appProvider.selectedCount > 0 && appProvider.selectedVendorId != null
                    ? () {
                        // Asignar cartillas seleccionadas
                            for (String cartillaId in appProvider.selectedCartillaIds) {
                              // Buscar la cartilla por ID
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
                label: const Text('Asignar Seleccionadas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: appProvider.selectedCount > 0
                    ? () {
                        // Desasignar cartillas seleccionadas
                            for (String cartillaId in appProvider.selectedCartillaIds) {
                              // Buscar la cartilla por ID
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
                label: const Text('Desasignar Seleccionadas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
              ],
            ),
            const SizedBox(height: 8),
            // Segunda fila: Eliminar y Nueva Cartilla
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: appProvider.selectedCount > 0
                        ? () async {
                            // Mostrar confirmación antes de eliminar
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmar Eliminación'),
                                content: Text(
                                  '¿Estás seguro de que quieres eliminar ${appProvider.selectedCount} cartilla${appProvider.selectedCount > 1 ? 's' : ''} seleccionada${appProvider.selectedCount > 1 ? 's' : ''}?\n\nEsta acción no se puede deshacer.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              // Eliminar cartillas seleccionadas
                              for (String cartillaId in appProvider.selectedCartillaIds) {
                                // Buscar la cartilla por ID
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
                              
                              // Recargar automáticamente si es necesario
                              await appProvider.autoReloadIfNeeded();
                              
                              // Mostrar mensaje de confirmación
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${appProvider.selectedCount} cartilla${appProvider.selectedCount > 1 ? 's' : ''} eliminada${appProvider.selectedCount > 1 ? 's' : ''} correctamente'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Eliminar Seleccionadas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Mostrar diálogo para especificar cantidad
                  final textController = TextEditingController(text: '1');
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Generar Cartillas'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Cuántas cartillas quieres generar?\n\n'
                            'Ingresa un número entre 0 y 1000:',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Ej: 10',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              (context as Element).markNeedsBuild();
                            },
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
                            if (count != null && count >= 0 && count <= 1000) {
                              Navigator.pop(context, true);
                            }
                          },
                          child: const Text('Generar'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    final count = int.tryParse(textController.text) ?? 1;
                    
                    // Mostrar indicador de carga
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🃏 Generando $count cartilla${count > 1 ? 's' : ''}...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                    
                    // Generar las cartillas
                    final success = await appProvider.generateFirebaseCartillas(count);
                    
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Se generaron $count cartilla${count > 1 ? 's' : ''} exitosamente'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Error al generar las cartillas'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Nueva Cartilla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildUtilityButtons() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Column(
          children: [
            // Primera fila: botones de utilidad
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      appProvider.resetFilters();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpiar Filtros'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      appProvider.applyDefaultFilters();
                    },
                    icon: const Icon(Icons.settings_backup_restore),
                    label: const Text('Filtros por Defecto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Obtener todos los IDs de las cartillas Firebase
                      final cartillaIds = appProvider.firebaseCartillas.map((c) => c.id).toList();
                      appProvider.selectAllCartillas(cartillaIds);
                    },
                    icon: const Icon(Icons.select_all),
                    label: const Text('Seleccionar Todas'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Segunda fila: botón de eliminar todas (peligroso)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Mostrar diálogo para escribir "ELIMINAR"
                      final textController = TextEditingController();
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('⚠️ ADVERTENCIA CRÍTICA'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¿Estás SEGURO de que quieres eliminar TODAS las cartillas de la base de datos?\n\n'
                                'Esta acción:\n'
                                '• Eliminará TODAS las cartillas permanentemente\n'
                                '• No se puede deshacer\n'
                                '• Limpiará toda la base de datos\n\n'
                                'Escribe "ELIMINAR" para confirmar:',
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: textController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Escribe ELIMINAR aquí',
                                ),
                                onChanged: (value) {
                                  // Habilitar/deshabilitar botón según el texto
                                  (context as Element).markNeedsBuild();
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: textController.text == 'ELIMINAR' 
                                  ? () => Navigator.pop(context, true)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade800,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Confirmar'),
                            ),
                          ],
                          contentPadding: const EdgeInsets.all(20),
                        ),
                      );
                      
                      if (confirmed == true) {
                        // Mostrar diálogo de confirmación final
                        final finalConfirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmación Final'),
                            content: const Text(
                              '¿Estás 100% seguro? Esta acción eliminará TODAS las cartillas sin posibilidad de recuperación.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade800,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('SÍ, ELIMINAR TODO'),
                              ),
                            ],
                          ),
                        );
                        
                        if (finalConfirmed == true) {
                          // Eliminar todas las cartillas
                          final success = await appProvider.clearAllFirebaseCartillas();
                          
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Todas las cartillas han sido eliminadas'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 5),
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ Error al eliminar todas las cartillas'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('ELIMINAR TODAS', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
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