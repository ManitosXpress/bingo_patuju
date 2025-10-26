import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import '../providers/app_provider.dart';
import '../models/bingo_game.dart';
import '../models/firebase_cartilla.dart';
import '../widgets/cartilla_widget.dart'; // Added import for CartillaWidget

class CartillasListPanel extends StatefulWidget {
  final BingoGame bingoGame;

  const CartillasListPanel({
    super.key,
    required this.bingoGame,
  });

  @override
  State<CartillasListPanel> createState() => _CartillasListPanelState();
}

class _CartillasListPanelState extends State<CartillasListPanel> {
  @override
  void initState() {
    super.initState();
    // Cargar cartillas de Firebase al inicializar (solo las primeras 10)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshFirebaseCartillas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final firebaseCartillas = appProvider.getFilteredFirebaseCartillas();
        final isLoading = appProvider.isLoadingFirebase;
        final error = appProvider.firebaseError;
        
        if (isLoading) {
          return _buildLoadingState();
        }
        
        if (error != null) {
          return _buildErrorState(error, appProvider);
        }
        
        if (firebaseCartillas.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botones de acción para Firebase
            _buildFirebaseActions(appProvider),
            const SizedBox(height: 16),
            // Indicador de progreso
            _buildProgressIndicator(appProvider),
            const SizedBox(height: 16),
            // Lista de cartillas
            SizedBox(
              height: 600, // Aumentar altura para mejor visualización
              child: ListView.builder(
                itemCount: firebaseCartillas.length + 1, // +1 para el botón "Cargar Más"
                itemBuilder: (context, index) {
                  if (index == firebaseCartillas.length) {
                    // Botón "Cargar Más" al final de la lista
                    return _buildLoadMoreButton(appProvider);
                  }
                  
                  final cartilla = firebaseCartillas[index];
                  return _CartillaListItem(
                    key: ValueKey('firebase_cartilla_${cartilla.id}'),
                    firebaseCartilla: cartilla,
                    index: index,
                    appProvider: appProvider,
                  );
                },
                // Mejorar el scroll
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                physics: const AlwaysScrollableScrollPhysics(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando cartillas desde Firebase...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, AppProvider appProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar cartillas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              appProvider.clearFirebaseError();
              appProvider.refreshFirebaseCartillas();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseActions(AppProvider appProvider) {
    return const SizedBox.shrink(); // Botones eliminados
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No hay cartillas disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Crea una nueva cartilla o refresca desde Firebase',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadMoreButton(AppProvider appProvider) {
    if (!appProvider.hasMoreData) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No hay más cartillas para cargar',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: appProvider.isLoadingMore 
            ? null 
            : () => appProvider.loadMoreCartillas(),
          icon: appProvider.isLoadingMore 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more),
          label: Text(
            appProvider.isLoadingMore 
              ? 'Cargando...' 
              : 'Cargar Más Cartillas',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator(AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cartillas visibles: ${appProvider.firebaseCartillas.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Total cargadas: ${appProvider.allFirebaseCartillas.length}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (appProvider.hasMoreData)
            Text(
              'Página ${appProvider.currentPage}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          if (appProvider.isLoadingFirebase || appProvider.isLoadingMore)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  appProvider.isLoadingFirebase ? 'Refrescando...' : 'Cargando más...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showCreateCartillaDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nueva Cartilla'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Quieres crear una nueva cartilla en Firebase?'),
            SizedBox(height: 16),
            Text('La cartilla se generará automáticamente con números válidos de Bingo.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _createNewCartilla(context, appProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewCartilla(BuildContext context, AppProvider appProvider) async {
    try {
      final newCartilla = await appProvider.createFirebaseCartilla();
      if (newCartilla != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cartilla creada exitosamente: ${newCartilla.displayNumber}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear cartilla: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _CartillaListItem extends StatelessWidget {
  final FirebaseCartilla firebaseCartilla;
  final int index;
  final AppProvider appProvider;

  const _CartillaListItem({
    super.key,
    required this.firebaseCartilla,
    required this.index,
    required this.appProvider,
  });

  // Getter para el vendedor asignado
  String? get assignedVendor => firebaseCartilla.assignedTo;

  @override
  Widget build(BuildContext context) {
    final isAssigned = firebaseCartilla.isAssigned;
    final isSelected = appProvider.isCartillaSelected(firebaseCartilla.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: isSelected ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            appProvider.toggleCartillaSelection(firebaseCartilla.id);
          },
        ),
        title: _buildTitle(),
        subtitle: _buildSubtitle(),
        trailing: _buildPopupMenu(context),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        // Mostrar número de cartilla de manera prominente
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: Text(
            firebaseCartilla.cardNo != null ? '${firebaseCartilla.cardNo}' : 'ID',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          firebaseCartilla.displayNumber,
          style: TextStyle(
            fontWeight: firebaseCartilla.isAssigned ? FontWeight.bold : FontWeight.normal,
            color: firebaseCartilla.isAssigned ? Colors.green.shade700 : null,
          ),
        ),
        const SizedBox(width: 8),
        if (firebaseCartilla.isAssigned) _buildAssignedBadge(),
        if (firebaseCartilla.sold) ...[
          const SizedBox(width: 8),
          _buildSoldBadge(),
        ],
      ],
    );
  }

  Widget _buildAssignedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Text(
        'Asignada',
        style: TextStyle(
          color: Colors.green.shade700,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSoldBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Text(
        'Vendida',
        style: TextStyle(
          color: Colors.orange.shade700,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mostrar información sobre los números aleatorios
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            'Números aleatorios: 1-75',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (firebaseCartilla.isAssigned && assignedVendor != null)
          Text(
            'Vendedor: ${appProvider.getVendorName(assignedVendor!)}',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        Text(
          'Creada: ${firebaseCartilla.formattedDate}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        _handleMenuAction(context, value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility),
              SizedBox(width: 8),
              Text('Ver Cartilla'),
            ],
          ),
        ),
        if (!firebaseCartilla.isAssigned)
          const PopupMenuItem(
            value: 'assign',
            child: Row(
              children: [
                Icon(Icons.person_add),
                SizedBox(width: 8),
                Text('Asignar'),
              ],
            ),
          ),
        if (firebaseCartilla.isAssigned)
          const PopupMenuItem(
            value: 'unassign',
            child: Row(
              children: [
                Icon(Icons.person_remove),
                SizedBox(width: 8),
                Text('Desasignar'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete),
              SizedBox(width: 8),
              Text('Eliminar'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'view':
        _showCartillaDetails(context);
        break;
      case 'delete':
        _deleteCartilla(context);
        break;
      case 'assign':
        _showVendorSelectionDialog(context);
        break;
      case 'unassign':
        _unassignCartilla(context);
        break;
    }
  }

  void _showCartillaDetails(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.98,
          height: MediaQuery.of(context).size.height * 0.98,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 25,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header premium con gradiente
              Container(
                constraints: const BoxConstraints(minHeight: 80), // Altura mínima en lugar de fija
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF8C00),
                      const Color(0xFFFF6B35),
                      const Color(0xFFFF5722),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    // Patrón de fondo sutil
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    // Contenido del header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          // Número de cartilla con estilo premium
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                firebaseCartilla.cardNo?.toString() ?? firebaseCartilla.displayNumber,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF8C00),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Título principal
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min, // No expandir más del necesario
                              children: [
                                                                 // Mostrar solo el número de cartilla sin duplicar "Cartilla"
                                 Text(
                                   firebaseCartilla.cardNo != null 
                                     ? 'Cartilla ${firebaseCartilla.cardNo}'
                                     : firebaseCartilla.displayNumber,
                                   style: TextStyle(
                                     fontSize: 18, // Aumentado para compensar el texto eliminado
                                     color: Colors.white.withValues(alpha: 0.9),
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                              ],
                            ),
                          ),
                          // Botón de cerrar premium
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 28),
                              onPressed: () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido principal con scroll elegante
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                                             child: Center(
                         child: Container(
                           constraints: BoxConstraints(
                             maxWidth: 600,
                             maxHeight: 600, // Altura reducida para evitar overflow
                           ),
                           child: SingleChildScrollView(
                             child: CartillaWidget(
                               numbers: firebaseCartilla.numbers,
                               cardNumber: firebaseCartilla.cardNo?.toString() ?? firebaseCartilla.displayNumber,
                               date: firebaseCartilla.formattedDate,
                               price: "Bs. 20", // Precio actualizado a 20 Bs para consistencia
                               isSelected: false,
                               compact: false, // Usar modo normal para mejor presentación
                             ),
                           ),
                         ),
                       ),
                    ),
                  ),
                ),
              ),
              
              // Footer premium con botones
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Botón de descarga premium
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade600.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              // Crear un ScreenshotController para capturar la cartilla visible
                              final screenshotController = ScreenshotController();
                              
                              // Crear un widget temporal con la cartilla para capturar
                              final cartillaWidget = MaterialApp(
                                home: Scaffold(
                                  backgroundColor: Colors.white,
                  body: Center(
                    child: Container(
                      width: 550, // Ancho reducido para mejor ajuste
                      height: 800, // Alto ajustado para mejor ajuste
                      child: Center(
                        child: CartillaWidget(
                                          numbers: firebaseCartilla.numbers,
                                          cardNumber: firebaseCartilla.cardNo?.toString() ?? firebaseCartilla.displayNumber,
                                          date: DateTime.now().toString().split(' ')[0],
                                          price: "Bs. 20",
                                          compact: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                              
                              // Capturar la cartilla directamente
                              final imageBytes = await screenshotController.captureFromWidget(
                                cartillaWidget,
                                context: context,
                                delay: const Duration(milliseconds: 500), // Aumentar delay para asegurar renderizado completo
                              );
                              
                              if (imageBytes != null) {
                                // Descargar la imagen
                                await _saveImageToDevice(imageBytes, 'cartilla_${firebaseCartilla.displayNumber}.png');
                                
                                // Cerrar el diálogo de "Ver Cartilla"
                                Navigator.of(context).pop();
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cartilla ${firebaseCartilla.displayNumber} descargada exitosamente'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error al capturar la cartilla'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al descargar: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download, color: Colors.white, size: 24),
                          label: const Text(
                            'Descargar PNG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Botón de cerrar elegante
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  void _showVendorSelectionDialog(BuildContext context) async {
    // Cargar vendedores antes de mostrar el diálogo
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    debugPrint('DEBUG: Iniciando carga de vendedores...');
    await appProvider.loadVendors();
    debugPrint('DEBUG: Vendedores cargados: ${appProvider.vendors.length}');
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Vendedor'),
        content: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            debugPrint('DEBUG: Construyendo diálogo con ${appProvider.vendors.length} vendedores');
            
            // Verificar si hay vendedores cargados
            if (appProvider.vendors.isEmpty) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No hay vendedores disponibles.'),
                  SizedBox(height: 16),
                  Text('Ve a CRM para crear vendedores primero.', 
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              );
            }
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selecciona un vendedor para asignar esta cartilla:'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Vendedor',
                    border: OutlineInputBorder(),
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
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return ElevatedButton(
                onPressed: appProvider.selectedVendorId != null && appProvider.vendors.isNotEmpty
                    ? () async {
                        Navigator.of(context).pop();
                        await _assignCartilla(context, appProvider);
                      }
                    : null,
                child: const Text('Asignar'),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _assignCartilla(BuildContext context, AppProvider appProvider) async {
    try {
      final success = await appProvider.assignFirebaseCartilla(
        firebaseCartilla.id,
        appProvider.selectedVendorId!,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cartilla asignada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al asignar cartilla'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _unassignCartilla(BuildContext context) async {
    try {
      final success = await appProvider.unassignFirebaseCartilla(firebaseCartilla.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cartilla desasignada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al desasignar cartilla'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveImageToDevice(Uint8List imageBytes, String fileName) async {
    try {
      // Crear un blob y descargar usando dart:html
      final blob = html.Blob([imageBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Crear elemento de descarga
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      
      // Agregar al DOM, hacer clic y limpiar
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      
      // Liberar memoria
      html.Url.revokeObjectUrl(url);
      
      // Pequeña pausa para asegurar que la descarga se inicie
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      debugPrint('Error al guardar imagen: $e');
      rethrow;
    }
  }
  
  void _showDownloadInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 25,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header premium
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade600,
                      Colors.indigo.shade600,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info,
                        color: Colors.purple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Descarga Automática de Cartillas',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'La descarga de cartillas ahora es completamente automática:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Características principales
                    _buildFeatureItem(
                      Icons.check_circle,
                      Colors.green,
                      'Simplemente haz clic en "Descargar PNG"',
                    ),
                    _buildFeatureItem(
                      Icons.check_circle,
                      Colors.green,
                      'La cartilla se capturará automáticamente',
                    ),
                    _buildFeatureItem(
                      Icons.check_circle,
                      Colors.green,
                      'Se descargará en formato PNG de alta calidad',
                    ),
                    _buildFeatureItem(
                      Icons.check_circle,
                      Colors.green,
                      'El archivo se guardará en tu carpeta de descargas',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Especificaciones técnicas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.settings,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Especificaciones Técnicas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSpecItem('Formato', 'PNG (imagen de alta calidad)'),
                          _buildSpecItem('Resolución', 'Optimizada para impresión'),
                          _buildSpecItem('Nombre', 'cartilla_[número].png'),
                          _buildSpecItem('Compatibilidad', 'Windows, Mac, Linux'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botón de cerrar
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  void _deleteCartilla(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar ${firebaseCartilla.displayNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                final success = await appProvider.deleteFirebaseCartilla(firebaseCartilla.id);
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cartilla eliminada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al eliminar cartilla'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
} 