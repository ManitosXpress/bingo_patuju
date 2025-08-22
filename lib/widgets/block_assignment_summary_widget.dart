import 'package:flutter/material.dart';
import '../models/block_assignment_config.dart';

class BlockAssignmentSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> result;
  final BlockAssignmentConfig config;
  final String vendorName;

  const BlockAssignmentSummaryWidget({
    super.key,
    required this.result,
    required this.config,
    required this.vendorName,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = result['success'] == true;
    final assignedCards = result['assignedCards'] as List<int>? ?? [];
    final data = result['data'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título del resumen
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSuccess ? Colors.green[200]! : Colors.red[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSuccess ? 'Asignación Exitosa' : 'Error en la Asignación',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      isSuccess 
                          ? 'Cartillas asignadas correctamente a $vendorName'
                          : 'No se pudieron asignar las cartillas',
                      style: TextStyle(
                        color: isSuccess ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Resumen de la configuración
        _buildSection(
          'Configuración de Bloques',
          Icons.settings,
          [
            _buildInfoRow('Tamaño del bloque:', '${config.blockSize} cartillas'),
            _buildInfoRow('Total de bloques:', '${config.totalBlocks}'),
            _buildInfoRow('Cartilla inicial:', '${config.startCard}'),
            _buildInfoRow('Bloques a saltar:', '${config.skipBlocks}'),
            if (config.assignToAllVendors) ...[
              _buildInfoRow('Cantidad de bloques:', 'Calculada automáticamente por el sistema'),
            ] else ...[
              _buildInfoRow('Cantidad de bloques a asignar:', '${config.quantityBlocksToAssign}'),
            ],
            _buildInfoRow('Selección aleatoria:', config.useRandomBlocks ? 'Sí' : 'No'),
            _buildInfoRow('Asignación automática:', config.assignToAllVendors ? 'Sí - A todos los vendedores' : 'No - Vendedor específico'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Información de bloques
        _buildSection(
          'Información de Bloques',
          Icons.grid_on,
          [
            _buildInfoRow('Total de bloques disponibles:', '${config.totalBlocks}'),
            _buildInfoRow('Bloques disponibles después de saltar:', '${config.availableBlocks}'),
            _buildInfoRow('Bloques ya asignados anteriormente:', '${_getAlreadyAssignedBlocksCount()}'),
            _buildInfoRow('Bloques disponibles para asignar:', '${_getAvailableBlocksForAssignment()}'),
            if (config.assignToAllVendors) ...[
              _buildInfoRow('Total de cartillas a asignar:', 'Calculado automáticamente'),
              _buildInfoRow('Máximo vendedores posibles:', 'Calculado automáticamente'),
            ] else ...[
              _buildInfoRow('Total de cartillas a asignar:', '${config.totalCardsToAssign}'),
              _buildInfoRow('Máximo vendedores posibles:', '${config.maxVendors}'),
            ],
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Resultado de la asignación
        if (isSuccess) ...[
          _buildSection(
            'Resultado de la Asignación',
            Icons.assignment_turned_in,
            [
              if (config.assignToAllVendors) ...[
                _buildInfoRow('Tipo de asignación:', 'Automática a todos los vendedores'),
                _buildInfoRow('Total de vendedores:', '${data['totalVendors'] ?? 'N/A'}'),
                _buildInfoRow('Total de bloques utilizados:', '${data['totalBlocksUsed'] ?? 'N/A'}'),
              ] else ...[
                _buildInfoRow('Vendedor asignado:', vendorName),
              ],
              _buildInfoRow('Cartillas asignadas:', '${assignedCards.length}'),
              _buildInfoRow('Primera cartilla:', '${assignedCards.isNotEmpty ? assignedCards.first : 'N/A'}'),
              _buildInfoRow('Última cartilla:', '${assignedCards.isNotEmpty ? assignedCards.last : 'N/A'}'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Nueva sección para distribución automática
          if (config.assignToAllVendors && data['distribution'] != null) ...[
            _buildSection(
              'Distribución Automática Calculada',
              Icons.auto_awesome,
              [
                _buildInfoRow('Bloques por vendedor:', '${data['distribution']['blocksPerVendor'] ?? 'N/A'}'),
                _buildInfoRow('Bloques extra distribuidos:', '${data['distribution']['extraBlocks'] ?? 'N/A'}'),
                _buildInfoRow('Vendedores con bloques extra:', '${data['distribution']['vendorsWithExtra'] ?? 'N/A'}'),
                _buildInfoRow('Total de cartillas por vendedor:', '${(data['distribution']['blocksPerVendor'] ?? 0) * config.blockSize}'),
                if (data['distribution']['note'] != null) ...[
                  _buildInfoRow('Nota:', '${data['distribution']['note']}'),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
          ],
          
          // Lista de cartillas asignadas
          _buildSection(
            'Cartillas Asignadas',
            Icons.list,
            [
              if (assignedCards.length <= 20) ...[
                _buildInfoRow('Números:', assignedCards.join(', ')),
              ] else ...[
                _buildInfoRow('Primeras 10:', assignedCards.take(10).join(', ')),
                _buildInfoRow('Últimas 10:', assignedCards.skip(assignedCards.length - 10).join(', ')),
                _buildInfoRow('Total:', '${assignedCards.length} cartillas'),
              ],
            ],
          ),
        ] else ...[
          // Información del error
          _buildSection(
            'Detalles del Error',
            Icons.error_outline,
            [
              _buildInfoRow('Error:', result['error'] ?? 'Error desconocido'),
            ],
          ),
        ],
        
        // Información adicional de la API
        if (data.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSection(
            'Información Adicional',
            Icons.info_outline,
            data.entries.map((entry) => 
              _buildInfoRow('${entry.key}:', '${entry.value}')
            ).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getAlreadyAssignedBlocksCount() {
    final data = result['data'] as Map<String, dynamic>? ?? {};
    return (data['alreadyAssignedBlocksExcluded'] ?? 0) as int;
  }

  int _getAvailableBlocksForAssignment() {
    final data = result['data'] as Map<String, dynamic>? ?? {};
    final alreadyAssigned = data['alreadyAssignedBlocksExcluded'] ?? 0;
    return (config.availableBlocks - alreadyAssigned).toInt();
  }
}
