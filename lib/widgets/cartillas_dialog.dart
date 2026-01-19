import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/bingo_game.dart';
import 'cartillas_stats_panel.dart';
import 'cartillas_filters_panel.dart';
import 'cartillas_list_panel.dart';

class CartillasDialog extends StatefulWidget {
  final BingoGame bingoGame;

  const CartillasDialog({
    super.key,
    required this.bingoGame,
  });

  @override
  State<CartillasDialog> createState() => _CartillasDialogState();
}

class _CartillasDialogState extends State<CartillasDialog> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Marcar como inicializado después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  void _refreshData() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // Verificar que hay una fecha seleccionada válida
    final selectedDate = appProvider.selectedDate;
    if (selectedDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una fecha para refrescar los datos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        _errorMessage = null;
      });
      
      // Usar refreshFirebaseCartillas que recarga las cartillas de la fecha seleccionada
      await appProvider.refreshFirebaseCartillas();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Datos actualizados para la fecha: $selectedDate'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al refrescar datos: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con título y botones
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Gestión de Cartillas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Botón de refrescar con indicador de carga (usa isLoadingFirebase)
                  Consumer<AppProvider>(
                    builder: (context, appProvider, child) {
                      return IconButton(
                        icon: appProvider.isLoadingFirebase 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.refresh, color: Colors.white),
                        onPressed: appProvider.isLoadingFirebase ? null : () {
                          _refreshData();
                        },
                        tooltip: 'Refrescar datos',
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Contenido scrollable
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mostrar error si existe
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red.shade700),
                                onPressed: () {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      
                      // Panel de estadísticas
                      CartillasStatsPanel(bingoGame: widget.bingoGame),
                      
                      const SizedBox(height: 16),
                      
                      // Panel de filtros y controles
                      CartillasFiltersPanel(bingoGame: widget.bingoGame),
                      
                      const SizedBox(height: 16),
                      
                      // Lista de cartillas
                      if (_isInitialized)
                        CartillasListPanel(bingoGame: widget.bingoGame)
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}