import 'package:flutter/material.dart';
import '../models/block_assignment_config.dart';
import '../services/block_assignment_service.dart';
import 'block_assignment_config_widget.dart';
import 'block_assignment_summary_widget.dart';

class BlockAssignmentModal extends StatefulWidget {
  final String apiBase;
  final String vendorId;
  final String vendorName;
  final Function() onSuccess;
  final List<Map<String, dynamic>>? allVendors; // Nueva: lista completa de vendedores

  const BlockAssignmentModal({
    super.key,
    required this.apiBase,
    required this.vendorId,
    required this.vendorName,
    required this.onSuccess,
    this.allVendors, // Opcional para compatibilidad
  });

  @override
  State<BlockAssignmentModal> createState() => _BlockAssignmentModalState();
}

class _BlockAssignmentModalState extends State<BlockAssignmentModal> {
  late BlockAssignmentService _service;
  late BlockAssignmentConfig _config;
  
  bool _isLoading = false;
  bool _showSummary = false;
  Map<String, dynamic>? _assignmentResult;

  @override
  void initState() {
    super.initState();
    _service = BlockAssignmentService(apiBase: widget.apiBase);
    _config = BlockAssignmentConfig.defaultConfig();
  }

  void _onConfigChanged(BlockAssignmentConfig newConfig) async {
    setState(() {
      _config = newConfig;
    });
    
    // Actualizar información de bloques
    try {
      await _service.getBlockInfoWithAssigned(newConfig);
      // La información se actualiza automáticamente en el widget de configuración
    } catch (e) {
      // Manejar error si es necesario
    }
  }

  Future<void> _assignCards() async {
    if (_config.validate().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrige los errores de validación antes de continuar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;
      
      if (_config.assignToAllVendors) {
        // Asignar automáticamente a todos los vendedores
        final allVendorIds = _getAllVendorIds();
        if (allVendorIds.isEmpty) {
          throw Exception('No se encontraron vendedores para asignar');
        }
        
        result = await _service.assignBlocksToAllVendors(allVendorIds, _config);
      } else {
        // Asignar a un vendedor específico
        if (widget.vendorId.isEmpty) {
          throw Exception('Debes seleccionar un vendedor');
        }
        
        result = await _service.assignCardsByBlocks(widget.vendorId, _config);
      }

      setState(() {
        _assignmentResult = result;
        _showSummary = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Obtener IDs de todos los vendedores disponibles
  List<String> _getAllVendorIds() {
    if (widget.allVendors == null || widget.allVendors!.isEmpty) {
      print('⚠️ No se proporcionó lista de vendedores, usando lista de ejemplo');
      return ['vendor_1', 'vendor_2', 'vendor_3']; // Fallback
    }
    
    final vendorIds = <String>[];
    
    for (final vendor in widget.allVendors!) {
      final id = vendor['id'] as String? ?? vendor['vendorId'] as String?;
      if (id != null && id.isNotEmpty) {
        vendorIds.add(id);
      }
    }
    
    print('👥 Vendedores encontrados: ${vendorIds.length}');
    print('📋 IDs de vendedores: $vendorIds');
    
    return vendorIds;
  }

  void _resetAssignment() {
    setState(() {
      _showSummary = false;
      _assignmentResult = null;
      _config = BlockAssignmentConfig.defaultConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.grid_on, size: 32, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asignación por Bloques',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Vendedor: ${widget.vendorName}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Contenido principal
            Expanded(
              child: _showSummary
                  ? _buildSummaryView()
                  : _buildConfigView(),
            ),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción simplificada
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.green[700], size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Asignación Automática por Bloques',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'El sistema asignará automáticamente bloques de cartillas a todos los vendedores disponibles:\n'
                  '• Cada bloque contiene 5 cartillas\n'
                  '• Los bloques se seleccionan aleatoriamente\n'
                  '• Se distribuyen equitativamente entre todos los vendedores\n'
                  '• No se repiten bloques ya asignados',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Widget de configuración
          BlockAssignmentConfigWidget(
            initialConfig: _config,
            onConfigChanged: _onConfigChanged,
            service: _service,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    if (_assignmentResult == null) {
      return const Center(
        child: Text('No hay resultados para mostrar'),
      );
    }

    return SingleChildScrollView(
      child: BlockAssignmentSummaryWidget(
        result: _assignmentResult!,
        config: _config,
        vendorName: widget.vendorName,
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_showSummary) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _resetAssignment,
            icon: const Icon(Icons.refresh),
            label: const Text('Nueva Asignación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check),
            label: const Text('Cerrar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.cancel),
          label: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _assignCards,
          icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.assignment),
          label: Text(_isLoading ? 'Asignando...' : 'Asignar Cartillas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
