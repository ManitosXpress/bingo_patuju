import 'package:flutter/material.dart';
import '../models/block_assignment_config.dart';
import '../services/block_assignment_service.dart';

class BlockAssignmentConfigWidget extends StatefulWidget {
  final BlockAssignmentConfig initialConfig;
  final Function(BlockAssignmentConfig) onConfigChanged;
  final BlockAssignmentService service;

  const BlockAssignmentConfigWidget({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
    required this.service,
  });

  @override
  State<BlockAssignmentConfigWidget> createState() => _BlockAssignmentConfigWidgetState();
}

class _BlockAssignmentConfigWidgetState extends State<BlockAssignmentConfigWidget> {
  late bool _assignToAllVendors;

  Map<String, dynamic>? _blockInfo;
  List<String> _validationErrors = [];
  int _totalCards = 1000; // Valor por defecto, se actualizará dinámicamente
  bool _isLoadingTotalCards = true;

  @override
  void initState() {
    super.initState();
    
    _assignToAllVendors = true; // Siempre habilitado para asignación por bloques
    
    _loadTotalCards();
  }

  Future<void> _loadTotalCards() async {
    try {
      setState(() {
        _isLoadingTotalCards = true;
      });
      
      final totalCards = await widget.service.getTotalCardsAvailable();
      
      setState(() {
        _totalCards = totalCards;
        _isLoadingTotalCards = false;
      });
      
      // Actualizar la información de bloques después de obtener el total
      _updateBlockInfo();
    } catch (e) {
      setState(() {
        _isLoadingTotalCards = false;
      });
      print('Error cargando total de cartillas: $e');
      // Continuar con el valor por defecto
      _updateBlockInfo();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateBlockInfo() async {
    try {
      final config = _createConfigFromInputs();
      if (config != null) {
        _blockInfo = await widget.service.getBlockInfoWithAssigned(config);
        _validationErrors = _blockInfo!['errors'] as List<String>;
        widget.onConfigChanged(config);
        setState(() {}); // Actualizar UI con la nueva información
      }
    } catch (e) {
      _validationErrors = ['Error al procesar configuración: $e'];
      setState(() {});
    }
  }

  BlockAssignmentConfig? _createConfigFromInputs() {
    try {
      // Configuración automática - calcular totalBlocks dinámicamente
      const blockSize = 5;
      const skipBlocks = 0;
      const startCard = 1;
      
      // Calcular totalBlocks basándose en el total de cartillas disponibles
      // totalBlocks = totalCards / blockSize (redondeado hacia arriba)
      final totalBlocks = (_totalCards / blockSize).ceil();
      
      print('📊 Calculando totalBlocks: $_totalCards cartillas / $blockSize = $totalBlocks bloques');
      
      // La cantidad se calculará automáticamente basada en los vendedores disponibles
      const quantityBlocks = 0; // Se calculará automáticamente

      return widget.service.createConfig(
        blockSize: blockSize,
        skipBlocks: skipBlocks,
        startCard: startCard,
        totalBlocks: totalBlocks,
        quantityBlocksToAssign: quantityBlocks,
        useRandomBlocks: true, // Siempre aleatorio
        assignToAllVendors: _assignToAllVendors,
      );
    } catch (e) {
      print('Error creando configuración: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        const Text(
          '🎯 Asignación Automática por Bloques - Sin Configuración Manual',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Información sobre asignación automática
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Configuración Automática',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Campo para editar el total de cartillas
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _totalCards.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Total de Cartillas Disponibles',
                        helperText: 'Ajusta este valor si el detectado es incorrecto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.confirmation_number),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final newValue = int.tryParse(value);
                        if (newValue != null && newValue > 0) {
                          setState(() {
                            _totalCards = newValue;
                          });
                          _updateBlockInfo();
                        }
                      },
                    ),
                  ),
                  if (_isLoadingTotalCards) ...[
                    const SizedBox(width: 16),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'El sistema configurará automáticamente:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '• Tamaño de bloque: 5 cartillas por bloque\n'
                '• Total de cartillas: $_totalCards cartillas configuradas\n'
                '• Total de bloques: ${(_totalCards / 5).ceil()} bloques (calculado dinámicamente)\n'
                '• Cartilla inicial: Desde la cartilla 1\n'
                '• Bloques a saltar: 0 (todos los bloques disponibles)\n'
                '• Selección aleatoria: Habilitada por defecto\n'
                '• Distribución: Equitativa entre todos los vendedores\n'
                '• Cantidad de bloques: Calculada automáticamente\n'
                '• Bloques por vendedor: Optimizados automáticamente\n'
                '• Ajuste inteligente: Se adapta a los bloques disponibles',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Información sobre asignación automática (siempre habilitada)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.group, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Asignación Automática Habilitada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Los bloques se distribuirán automáticamente entre todos los vendedores disponibles de manera equitativa. El sistema calculará la cantidad óptima de bloques para cada vendedor.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: const Text(
                        '💡 El sistema automáticamente:\n'
                        '• Cuenta cuántos vendedores hay disponibles\n'
                        '• Calcula cuántos bloques puede asignar a cada uno\n'
                        '• Distribuye los bloques de manera equitativa\n'
                        '• Evita duplicaciones y conflictos\n'
                        '• Se ajusta automáticamente si hay pocos bloques\n'
                        '• Garantiza que todos los vendedores reciban bloques',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Nueva sección sobre ajuste automático
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.psychology, color: Colors.orange[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajuste Automático Inteligente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Si no hay suficientes bloques para la distribución ideal, el sistema automáticamente se ajusta para garantizar que todos los vendedores reciban al menos 1 bloque.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: const Text(
                        '🔄 Ejemplo de ajuste:\n'
                        '• Si hay 200 bloques y 18 vendedores\n'
                        '• Distribución ideal: 11 bloques por vendedor\n'
                        '• Ajuste automático: 1 bloque por vendedor\n'
                        '• Resultado: Todos reciben al menos 1 bloque',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Información de bloques
        if (_blockInfo != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información de Bloques',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Total de bloques:', '${_blockInfo!['totalBlocks']}'),
                _buildInfoRow('Bloques disponibles:', '${_blockInfo!['availableBlocks']}'),
                _buildInfoRow('Bloques ya asignados:', '${_blockInfo!['alreadyAssignedBlocks']}'),
                _buildInfoRow('Bloques disponibles para asignar:', '${_blockInfo!['availableBlocksForAssignment']}'),
                _buildInfoRow('Rango de cartillas:', '${_blockInfo!['startCard']} - ${_blockInfo!['endCard']}'),
                _buildInfoRow('Selección aleatoria:', _blockInfo!['useRandomBlocks'] ? 'Sí' : 'No'),
                if (_assignToAllVendors) ...[
                  _buildInfoRow('Asignación automática:', 'Sí - A todos los vendedores'),
                  _buildInfoRow('Total vendedores estimados:', '${_blockInfo!['maxVendors']}'),
                  _buildInfoRow('Distribución:', 'Calculada automáticamente por el sistema'),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
        
        // Errores de validación
        if (_validationErrors.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Errores de validación:',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._validationErrors.map((error) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '• $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                )),
              ],
            ),
          ),
        ],
        
        // Botón de depuración
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _debugAssignedCards,
          icon: const Icon(Icons.bug_report),
          label: const Text('Depurar Consulta de Cartillas Asignadas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  void _debugAssignedCards() async {
    try {
      final debugInfo = await widget.service.debugAssignedCardsQuery();
      
      // Mostrar información de depuración en un diálogo
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Información de Depuración'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Estado endpoint 1: ${debugInfo['endpoint1_status'] ?? 'N/A'}'),
                  Text('Estado endpoint 2: ${debugInfo['endpoint2_status'] ?? 'N/A'}'),
                  Text('Cartillas asignadas encontradas: ${debugInfo['assigned_cards_count'] ?? 0}'),
                  if (debugInfo['assigned_cards_sample'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Muestra de cartillas: ${debugInfo['assigned_cards_sample']}'),
                  ],
                  if (debugInfo['endpoint1_error'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Error endpoint 1: ${debugInfo['endpoint1_error']}'),
                  ],
                  if (debugInfo['endpoint2_error'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Error endpoint 2: ${debugInfo['endpoint2_error']}'),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en depuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
