import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/block_assignment_config.dart';

class BlockAssignmentService {
  final String apiBase;

  BlockAssignmentService({required this.apiBase});

  /// Asignar cartillas por bloques a un vendedor específico
  Future<Map<String, dynamic>> assignCardsByBlocks(
    String vendorId,
    BlockAssignmentConfig config,
  ) async {
    try {
      print('🚀 Iniciando asignación por bloques para vendedor: $vendorId');
      
      // Validar configuración
      final errors = config.validate();
      if (errors.isNotEmpty) {
        print('❌ Error de validación: ${errors.join(', ')}');
        return {
          'success': false,
          'error': 'Configuración inválida: ${errors.join(', ')}',
        };
      }
      
      print('✅ Configuración válida');

      // Obtener bloques ya asignados
      print('🔍 Consultando bloques ya asignados...');
      final alreadyAssignedBlocks = await getAlreadyAssignedBlockNumbers(config);
      final availableBlocksForAssignment = config.availableBlocks - alreadyAssignedBlocks.length;
      
      print('📊 Bloques ya asignados: ${alreadyAssignedBlocks.length}');
      print('📊 Bloques disponibles: $availableBlocksForAssignment');

      // Verificar que hay suficientes bloques disponibles
      if (config.quantityBlocksToAssign > availableBlocksForAssignment) {
        final errorMsg = 'No hay suficientes bloques disponibles para asignar. Se necesitan ${config.quantityBlocksToAssign} bloques pero solo hay $availableBlocksForAssignment disponibles (${config.availableBlocks} total - ${alreadyAssignedBlocks.length} ya asignados).';
        print('❌ $errorMsg');
        return {
          'success': false,
          'error': errorMsg,
        };
      }

      // Generar números de cartillas para la asignación (excluyendo bloques ya asignados)
      print('🎲 Generando números de cartillas...');
      final cardNumbers = await _generateCardNumbersExcludingAssigned(config);
      
      if (cardNumbers.isEmpty) {
        print('❌ No se pudieron generar números de cartillas');
        return {
          'success': false,
          'error': 'No se pudieron generar números de cartillas (todos los bloques solicitados ya están asignados)',
        };
      }

      print('✅ Cartillas generadas: ${cardNumbers.length} (${cardNumbers.take(10).toList()}...)');

      // Llamar a la API para asignar las cartillas
      print('📡 Enviando solicitud a la API: $apiBase/cards/bulk-assign');
      final response = await http.post(
        Uri.parse('$apiBase/cards/bulk-assign'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'vendorId': vendorId,
          'cardNumbers': cardNumbers,
          'assignmentType': 'blocks',
          'config': config.toJson(),
        }),
      );
      
      print('📡 Respuesta de la API: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'data': result,
          'assignedCards': cardNumbers,
          'config': config,
          'blocksUsed': cardNumbers.length ~/ config.blockSize,
          'alreadyAssignedBlocksExcluded': alreadyAssignedBlocks.length,
        };
      } else {
        return {
          'success': false,
          'error': 'Error en la API: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  /// Asignar bloques automáticamente a todos los vendedores disponibles
  Future<Map<String, dynamic>> assignBlocksToAllVendors(
    List<String> vendorIds,
    BlockAssignmentConfig config,
  ) async {
    try {
      print('🚀 INICIANDO ASIGNACIÓN AUTOMÁTICA A TODOS LOS VENDEDORES');
      print('👥 Total de vendedores: ${vendorIds.length}');
      print('📊 Configuración: ${config.toJson()}');
      
      // Validar configuración
      final errors = config.validate();
      if (errors.isNotEmpty) {
        print('❌ Error de validación: ${errors.join(', ')}');
        return {
          'success': false,
          'error': 'Configuración inválida: ${errors.join(', ')}',
        };
      }
      print('✅ Configuración válida');

      // Obtener bloques ya asignados
      print('🔍 Consultando bloques ya asignados...');
      final alreadyAssignedBlocks = await getAlreadyAssignedBlockNumbers(config);
      final availableBlocksForAssignment = config.availableBlocks - alreadyAssignedBlocks.length;
      
      print('📊 Bloques ya asignados: ${alreadyAssignedBlocks.length}');
      print('📊 Bloques disponibles: $availableBlocksForAssignment');

      // CALCULAR AUTOMÁTICAMENTE la cantidad óptima de bloques por vendedor
      // Basándose en los bloques disponibles y el número de vendedores
      final optimalBlocksPerVendor = _calculateOptimalBlocksPerVendor(
        availableBlocksForAssignment, 
        vendorIds.length
      );
      
      print('🎯 Cálculo automático: $optimalBlocksPerVendor bloques por vendedor');
      
      // Si no se pueden asignar bloques, usar distribución mínima
      if (optimalBlocksPerVendor < 1) {
        print('⚠️ No hay suficientes bloques para asignar 1 bloque por vendedor');
        print('🔄 Ajustando a distribución mínima: 1 bloque por vendedor');
        
        // Verificar si al menos podemos asignar 1 bloque por vendedor
        if (vendorIds.length > availableBlocksForAssignment) {
          final errorMsg = 'No hay suficientes bloques para asignar al menos 1 bloque por vendedor. Hay ${vendorIds.length} vendedores pero solo ${availableBlocksForAssignment} bloques disponibles.';
          print('❌ $errorMsg');
          return {
            'success': false,
            'error': errorMsg,
          };
        }
        
        // Usar distribución mínima: 1 bloque por vendedor
        final totalBlocksNeeded = vendorIds.length;
        print('🎯 Distribución mínima: $totalBlocksNeeded bloques (1 por vendedor)');
        
        // Continuar con la asignación mínima
        final selectedBlocks = await _generateUniqueBlocksForAllVendors(config, totalBlocksNeeded);
        
        if (selectedBlocks.isEmpty) {
          print('❌ No se pudieron generar bloques únicos para distribución mínima');
          return {
            'success': false,
            'error': 'No se pudieron generar bloques únicos para la distribución mínima',
          };
        }
        
        // Asignar 1 bloque por vendedor
        final results = <Map<String, dynamic>>[];
        final allAssignedCards = <int>{};
        
        for (int i = 0; i < vendorIds.length; i++) {
          final vendorId = vendorIds[i];
          final vendorBlock = selectedBlocks[i];
          final vendorCards = config.generateCardNumbers([vendorBlock]);
          
          print('👤 Asignando 1 bloque al vendedor $vendorId: bloque $vendorBlock');
          
          final result = await _assignCardsToVendor(vendorId, vendorCards, config);
          results.add(result);
          
          if (result['success']) {
            print('✅ Vendedor $vendorId asignado exitosamente');
            allAssignedCards.addAll(vendorCards);
          } else {
            print('❌ Error asignando vendedor $vendorId: ${result['error']}');
          }
        }
        
        // Verificar resultados
        final failedAssignments = results.where((r) => !r['success']).toList();
        if (failedAssignments.isNotEmpty) {
          print('❌ Algunas asignaciones fallaron: ${failedAssignments.length} de ${results.length}');
          return {
            'success': false,
            'error': 'Algunas asignaciones fallaron: ${failedAssignments.map((r) => r['error']).join(', ')}',
          };
        }
        
        print('🎉 DISTRIBUCIÓN MÍNIMA COMPLETADA EXITOSAMENTE');
        return {
          'success': true,
          'data': {
            'totalVendors': vendorIds.length,
            'totalCardsAssigned': allAssignedCards.length,
            'blocksPerVendor': 1, // Distribución mínima
            'totalBlocksUsed': selectedBlocks.length,
            'results': results,
            'alreadyAssignedBlocksExcluded': alreadyAssignedBlocks.length,
            'distribution': {
              'blocksPerVendor': 1,
              'extraBlocks': 0,
              'vendorsWithExtra': 0,
              'note': 'Distribución mínima: 1 bloque por vendedor',
            },
          },
          'assignedCards': allAssignedCards.toList(),
          'config': config,
        };
      }
      
      // Calcular bloques necesarios para todos los vendedores
      final totalBlocksNeeded = vendorIds.length * optimalBlocksPerVendor;
      print('🎯 Bloques necesarios total: $totalBlocksNeeded (${vendorIds.length} vendedores × $optimalBlocksPerVendor bloques por vendedor)');
      
      if (totalBlocksNeeded > availableBlocksForAssignment) {
        final errorMsg = 'No hay suficientes bloques disponibles para asignar a todos los vendedores. Se necesitan $totalBlocksNeeded bloques pero solo hay $availableBlocksForAssignment disponibles (${config.availableBlocks} total - ${alreadyAssignedBlocks.length} ya asignados).';
        print('❌ $errorMsg');
        return {
          'success': false,
          'error': errorMsg,
        };
      }

      // Generar bloques únicos para toda la asignación
      print('🎲 Generando bloques únicos para todos los vendedores...');
      final selectedBlocks = await _generateUniqueBlocksForAllVendors(config, totalBlocksNeeded);
      
      if (selectedBlocks.isEmpty) {
        print('❌ No se pudieron generar bloques únicos');
        return {
          'success': false,
          'error': 'No se pudieron generar bloques únicos para la asignación',
        };
      }
      
      print('✅ Bloques generados: ${selectedBlocks.length} (${selectedBlocks.take(10).toList()}...)');

      // Distribuir bloques entre vendedores de manera equitativa
      print('📦 Distribuyendo bloques entre vendedores de manera equitativa...');
      final results = <Map<String, dynamic>>[];
      final allAssignedCards = <int>{};

      // Calcular bloques por vendedor de manera equitativa
      final blocksPerVendor = (totalBlocksNeeded / vendorIds.length).ceil();
      final remainingBlocks = totalBlocksNeeded % vendorIds.length;
      
      print('📊 Distribución: $blocksPerVendor bloques por vendedor, $remainingBlocks bloques extra para distribuir');

      for (int i = 0; i < vendorIds.length; i++) {
        final vendorId = vendorIds[i];
        
        // Calcular cuántos bloques le tocan a este vendedor
        int vendorBlockCount = blocksPerVendor;
        if (i < remainingBlocks) {
          vendorBlockCount++; // Dar bloques extra a los primeros vendedores
        }
        
        // Calcular índices de inicio y fin para este vendedor
        int startBlockIndex = 0;
        for (int j = 0; j < i; j++) {
          if (j < remainingBlocks) {
            startBlockIndex += (blocksPerVendor + 1);
          } else {
            startBlockIndex += blocksPerVendor;
          }
        }
        final endBlockIndex = startBlockIndex + vendorBlockCount - 1;
        
        print('👤 Procesando vendedor $vendorId (índice $i): ${vendorBlockCount} bloques (${startBlockIndex + 1} a ${endBlockIndex + 1})');
        
        // Obtener bloques para este vendedor
        final vendorBlocks = selectedBlocks.sublist(startBlockIndex, endBlockIndex + 1);
        print('📦 Bloques para vendedor $vendorId: ${vendorBlocks.length} bloques (${vendorBlocks})');
        
        // Generar cartillas para estos bloques
        final vendorCards = config.generateCardNumbers(vendorBlocks);
        print('🎴 Cartillas generadas para vendedor $vendorId: ${vendorCards.length} cartillas');
        
        // Verificar que no hay duplicados
        if (vendorCards.any((card) => allAssignedCards.contains(card))) {
          print('❌ Se detectaron cartillas duplicadas');
          return {
            'success': false,
            'error': 'Se detectaron cartillas duplicadas en la asignación',
          };
        }

        // Asignar cartillas al vendedor
        print('📡 Asignando cartillas al vendedor $vendorId...');
        final result = await _assignCardsToVendor(vendorId, vendorCards, config);
        results.add(result);
        
        if (result['success']) {
          print('✅ Vendedor $vendorId asignado exitosamente');
        } else {
          print('❌ Error asignando vendedor $vendorId: ${result['error']}');
        }
        
        // Agregar cartillas asignadas al conjunto global
        allAssignedCards.addAll(vendorCards);
      }

      // Verificar que todas las asignaciones fueron exitosas
      final failedAssignments = results.where((r) => !r['success']).toList();
      if (failedAssignments.isNotEmpty) {
        print('❌ Algunas asignaciones fallaron: ${failedAssignments.length} de ${results.length}');
        return {
          'success': false,
          'error': 'Algunas asignaciones fallaron: ${failedAssignments.map((r) => r['error']).join(', ')}',
        };
      }

      print('🎉 ASIGNACIÓN AUTOMÁTICA COMPLETADA EXITOSAMENTE');
      print('📊 Resumen: ${vendorIds.length} vendedores, ${allAssignedCards.length} cartillas asignadas');
      
      return {
        'success': true,
        'data': {
          'totalVendors': vendorIds.length,
          'totalCardsAssigned': allAssignedCards.length,
          'blocksPerVendor': optimalBlocksPerVendor, // Usar el valor calculado automáticamente
          'totalBlocksUsed': selectedBlocks.length,
          'results': results,
          'alreadyAssignedBlocksExcluded': alreadyAssignedBlocks.length,
          'distribution': {
            'blocksPerVendor': optimalBlocksPerVendor,
            'extraBlocks': remainingBlocks,
            'vendorsWithExtra': remainingBlocks,
          },
        },
        'assignedCards': allAssignedCards.toList(),
        'config': config,
      };
    } catch (e) {
      print('💥 Error en asignación automática: $e');
      return {
        'success': false,
        'error': 'Error en asignación automática: $e',
      };
    }
  }

  /// Generar bloques únicos para asignación a todos los vendedores
  Future<List<int>> _generateUniqueBlocksForAllVendors(
    BlockAssignmentConfig config,
    int totalBlocksNeeded,
  ) async {
    if (totalBlocksNeeded <= 0) return [];
    
    print('🎲 Generando $totalBlocksNeeded bloques únicos...');
    
    // Obtener bloques ya asignados
    final alreadyAssignedBlocks = await getAlreadyAssignedBlockNumbers(config);
    print('🚫 Bloques ya asignados: ${alreadyAssignedBlocks.length}');
    
    // Generar lista de bloques disponibles (excluyendo ya asignados)
    final availableBlockNumbers = <int>[];
    for (int i = 0; i < config.availableBlocks; i++) {
      final blockNumber = config.skipBlocks + i;
      if (!alreadyAssignedBlocks.contains(blockNumber)) {
        availableBlockNumbers.add(blockNumber);
      }
    }
    
    print('✅ Bloques disponibles: ${availableBlockNumbers.length}');
    
    if (availableBlockNumbers.length < totalBlocksNeeded) {
      print('❌ No hay suficientes bloques disponibles: se necesitan $totalBlocksNeeded, hay ${availableBlockNumbers.length}');
      return []; // No hay suficientes bloques disponibles
    }
    
    // Seleccionar bloques aleatoriamente o secuencialmente
    if (config.useRandomBlocks) {
      print('🎲 Aplicando selección aleatoria...');
      availableBlockNumbers.shuffle();
    } else {
      print('📊 Manteniendo orden secuencial...');
    }
    
    final selectedBlocks = availableBlockNumbers.take(totalBlocksNeeded).toList();
    print('✅ Bloques seleccionados: ${selectedBlocks.length} (${selectedBlocks.take(10).toList()}...)');
    
    return selectedBlocks;
  }

  /// Generar números de cartillas excluyendo bloques ya asignados
  Future<List<int>> _generateCardNumbersExcludingAssigned(BlockAssignmentConfig config) async {
    if (config.quantityBlocksToAssign <= 0) return [];
    
    // Obtener bloques ya asignados
    final alreadyAssignedBlocks = await getAlreadyAssignedBlockNumbers(config);
    
    List<int> selectedBlocks;
    
    if (config.useRandomBlocks) {
      // Selección aleatoria de bloques (excluyendo ya asignados)
      final availableBlockNumbers = List.generate(config.availableBlocks, (i) => config.skipBlocks + i)
          .where((blockNumber) => !alreadyAssignedBlocks.contains(blockNumber))
          .toList();
      
      if (availableBlockNumbers.length < config.quantityBlocksToAssign) {
        return []; // No hay suficientes bloques disponibles
      }
      
      availableBlockNumbers.shuffle();
      selectedBlocks = availableBlockNumbers.take(config.quantityBlocksToAssign).toList();
    } else {
      // Selección secuencial de bloques (excluyendo ya asignados)
      final availableBlockNumbers = <int>[];
      for (int i = 0; i < config.availableBlocks; i++) {
        final blockNumber = config.skipBlocks + i;
        if (!alreadyAssignedBlocks.contains(blockNumber)) {
          availableBlockNumbers.add(blockNumber);
          if (availableBlockNumbers.length >= config.quantityBlocksToAssign) {
            break;
          }
        }
      }
      
      if (availableBlockNumbers.length < config.quantityBlocksToAssign) {
        return []; // No hay suficientes bloques disponibles
      }
      
      selectedBlocks = availableBlockNumbers.take(config.quantityBlocksToAssign).toList();
    }
    
    return config.generateCardNumbers(selectedBlocks);
  }

  /// Asignar cartillas por bloques a múltiples vendedores
  Future<Map<String, dynamic>> assignCardsByBlocksToMultipleVendors(
    List<String> vendorIds,
    BlockAssignmentConfig config,
  ) async {
    try {
      // Validar configuración
      final errors = config.validate();
      if (errors.isNotEmpty) {
        return {
          'success': false,
          'error': 'Configuración inválida: ${errors.join(', ')}',
        };
      }

      // Verificar que hay suficientes bloques para todos los vendedores
      final totalBlocksNeeded = vendorIds.length * config.blocksPerVendor;
      if (totalBlocksNeeded > config.quantityBlocksToAssign) {
        return {
          'success': false,
          'error': 'No hay suficientes bloques para asignar a todos los vendedores. Se necesitan $totalBlocksNeeded bloques pero solo hay ${config.quantityBlocksToAssign} disponibles.',
        };
      }

      final results = <Map<String, dynamic>>[];
      final allAssignedCards = <int>{};

      // Generar bloques aleatorios únicos para toda la asignación
      final availableBlockNumbers = List.generate(config.availableBlocks, (i) => config.skipBlocks + i);
      availableBlockNumbers.shuffle();
      final selectedBlocks = availableBlockNumbers.take(config.quantityBlocksToAssign).toList();

      // Asignar bloques a cada vendedor
      for (int i = 0; i < vendorIds.length; i++) {
        final vendorId = vendorIds[i];
        final startBlockIndex = i * config.blocksPerVendor;
        final endBlockIndex = (startBlockIndex + config.blocksPerVendor - 1).clamp(0, selectedBlocks.length - 1);
        
        // Obtener bloques para este vendedor
        final vendorBlocks = selectedBlocks.sublist(startBlockIndex, endBlockIndex + 1);
        
        // Generar cartillas para estos bloques
        final vendorCards = config.generateCardNumbers(vendorBlocks);
        
        // Verificar que no hay duplicados
        if (vendorCards.any((card) => allAssignedCards.contains(card))) {
          return {
            'success': false,
            'error': 'Se detectaron cartillas duplicadas en la asignación',
          };
        }

        // Asignar cartillas al vendedor
        final result = await _assignCardsToVendor(vendorId, vendorCards, config);
        results.add(result);
        
        // Agregar cartillas asignadas al conjunto global
        allAssignedCards.addAll(vendorCards);
      }

      // Verificar que todas las asignaciones fueron exitosas
      final failedAssignments = results.where((r) => !r['success']).toList();
      if (failedAssignments.isNotEmpty) {
        return {
          'success': false,
          'error': 'Algunas asignaciones fallaron: ${failedAssignments.map((r) => r['error']).join(', ')}',
        };
      }

      return {
        'success': true,
        'data': {
          'totalVendors': vendorIds.length,
          'totalCardsAssigned': allAssignedCards.length,
          'blocksPerVendor': config.blocksPerVendor,
          'totalBlocksUsed': selectedBlocks.length,
          'results': results,
        },
        'assignedCards': allAssignedCards.toList(),
        'config': config,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error en asignación múltiple: $e',
      };
    }
  }

  /// Asignar cartillas específicas a un vendedor
  Future<Map<String, dynamic>> _assignCardsToVendor(
    String vendorId,
    List<int> cardNumbers,
    BlockAssignmentConfig config,
  ) async {
    try {
      print('📡 Enviando solicitud para vendedor $vendorId: ${cardNumbers.length} cartillas');
      print('🔢 Cartillas: ${cardNumbers.take(10).toList()}...');
      
      final response = await http.post(
        Uri.parse('$apiBase/cards/bulk-assign'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'vendorId': vendorId,
          'cardNumbers': cardNumbers,
          'assignmentType': 'blocks',
          'config': config.toJson(),
        }),
      );

      print('📡 Respuesta de la API para vendedor $vendorId: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ Vendedor $vendorId asignado exitosamente por la API');
        return {
          'success': true,
          'vendorId': vendorId,
          'assignedCards': cardNumbers,
          'data': result,
        };
      } else {
        print('❌ Error en la API para vendedor $vendorId: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'vendorId': vendorId,
          'error': 'Error en la API: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('💥 Error de conexión para vendedor $vendorId: $e');
      return {
        'success': false,
        'vendorId': vendorId,
        'error': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener bloques ya asignados desde la base de datos
  Future<List<int>> getAlreadyAssignedBlocks() async {
    try {
      // Usar el endpoint existente de cartillas para obtener las asignadas
      final response = await http.get(
        Uri.parse('$apiBase/cards'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final allCards = result['cards'] as List<dynamic>? ?? [];
        
        print('🔍 Total de cartillas recibidas: ${allCards.length}');
        
        // Filtrar solo las cartillas que tienen asignación
        final assignedCards = <int>[];
        for (final card in allCards) {
          final assignedTo = card['assignedTo'];
          final cardNo = card['cardNo'];
          
          // Verificar diferentes posibles formatos de asignación
          bool isAssigned = false;
          if (assignedTo != null) {
            final assignedStr = assignedTo.toString();
            if (assignedStr.isNotEmpty && assignedStr != 'null') {
              isAssigned = true;
            }
          }
          
          if (isAssigned && cardNo != null) {
            assignedCards.add(cardNo as int);
          }
        }
        
        print('✅ Cartillas asignadas encontradas: ${assignedCards.length}');
        if (assignedCards.isNotEmpty) {
          print('🔢 Primeras 10: ${assignedCards.take(10).toList()}');
        }
        
        return assignedCards;
      } else {
        // Si no hay endpoint específico, retornar lista vacía
        return [];
      }
    } catch (e) {
      // En caso de error, retornar lista vacía
      return [];
    }
  }

  /// Obtener cartillas ya asignadas usando el endpoint existente
  Future<List<int>> getAssignedCardsFromExistingEndpoint() async {
    try {
      // Intentar obtener cartillas asignadas usando el endpoint existente
      final response = await http.get(
        Uri.parse('$apiBase/cards?assigned=true'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final assignedCards = result['cards'] as List<dynamic>? ?? [];
        return assignedCards.map((card) => card['cardNo'] as int).toList();
      } else {
        // Si no funciona, intentar con el endpoint general
        return await getAlreadyAssignedBlocks();
      }
    } catch (e) {
      // En caso de error, usar el método alternativo
      return await getAlreadyAssignedBlocks();
    }
  }

  /// Obtener bloques ya asignados agrupados por número de bloque
  Future<Set<int>> getAlreadyAssignedBlockNumbers(BlockAssignmentConfig config) async {
    try {
      print('🔍 Calculando bloques ya asignados...');
      
      // Obtener cartillas ya asignadas
      List<int> assignedCards = await getAlreadyAssignedBlocks();
      print('📊 Cartillas asignadas encontradas: ${assignedCards.length}');
      
      final assignedBlockNumbers = <int>{};
      
      for (final cardNumber in assignedCards) {
        // Verificar que la cartilla está en el rango válido
        if (cardNumber >= config.startCard && cardNumber <= config.totalCards) {
          // Calcular el número de bloque
          final blockNumber = (cardNumber - config.startCard) ~/ config.blockSize;
          if (blockNumber >= 0 && blockNumber < config.totalBlocks) {
            assignedBlockNumbers.add(blockNumber);
          }
        }
      }
      
      print('🚫 Bloques ya asignados calculados: ${assignedBlockNumbers.length}');
      if (assignedBlockNumbers.isNotEmpty) {
        print('🔢 Bloques asignados: ${assignedBlockNumbers.take(10).toList()}...');
      }
      
      return assignedBlockNumbers;
    } catch (e) {
      print('💥 Error calculando bloques asignados: $e');
      return <int>{};
    }
  }

  /// Obtener información de bloques para mostrar en la UI (incluyendo bloques ya asignados)
  Future<Map<String, dynamic>> getBlockInfoWithAssigned(BlockAssignmentConfig config) async {
    final errors = config.validate();
    final alreadyAssignedBlocks = await getAlreadyAssignedBlockNumbers(config);
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'totalBlocks': config.totalBlocks,
      'availableBlocks': config.availableBlocks,
      'alreadyAssignedBlocks': alreadyAssignedBlocks.length,
      'availableBlocksForAssignment': config.availableBlocks - alreadyAssignedBlocks.length,
      'totalCardsToAssign': config.totalCardsToAssign,
      'maxVendors': config.maxVendors,
      'blocksPerVendor': config.blocksPerVendor,
      'startCard': config.actualStartCard,
      'endCard': config.actualEndCard,
      'useRandomBlocks': config.useRandomBlocks,
      'assignedBlockNumbers': alreadyAssignedBlocks.toList(),
    };
  }

  /// Crear configuración por defecto
  BlockAssignmentConfig createDefaultConfig() {
    return BlockAssignmentConfig.defaultConfig();
  }

  /// Validar y crear configuración
  BlockAssignmentConfig? createConfig({
    required int blockSize,
    required int skipBlocks,
    required int startCard,
    required int totalBlocks, // Cambiado de totalCards a totalBlocks
    required int quantityBlocksToAssign,
    bool useRandomBlocks = true,
    bool assignToAllVendors = true,
  }) {
    final config = BlockAssignmentConfig(
      blockSize: blockSize,
      skipBlocks: skipBlocks,
      startCard: startCard,
      totalBlocks: totalBlocks, // Cambiado de totalCards a totalBlocks
      quantityBlocksToAssign: quantityBlocksToAssign,
      useRandomBlocks: useRandomBlocks,
      assignToAllVendors: assignToAllVendors,
    );

    final errors = config.validate();
    if (errors.isNotEmpty) {
      return null;
    }

    return config;
  }

  /// Método de depuración para ver qué cartillas se están consultando
  Future<Map<String, dynamic>> debugAssignedCardsQuery() async {
    try {
      final result = <String, dynamic>{};
      
      // Intentar endpoint específico
      try {
        final response1 = await http.get(
          Uri.parse('$apiBase/cards?assigned=true'),
          headers: {'Content-Type': 'application/json'},
        );
        result['endpoint1_status'] = response1.statusCode;
        result['endpoint1_body'] = response1.body;
      } catch (e) {
        result['endpoint1_error'] = e.toString();
      }
      
      // Intentar endpoint general
      try {
        final response2 = await http.get(
          Uri.parse('$apiBase/cards'),
          headers: {'Content-Type': 'application/json'},
        );
        result['endpoint2_status'] = response2.statusCode;
        result['endpoint2_body'] = response2.body;
      } catch (e) {
        result['endpoint2_error'] = e.toString();
      }
      
      // Obtener cartillas asignadas
      final assignedCards = await getAlreadyAssignedBlocks();
      result['assigned_cards_count'] = assignedCards.length;
      result['assigned_cards_sample'] = assignedCards.take(10).toList();
      
      return result;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Calcular automáticamente la cantidad óptima de bloques por vendedor
  int _calculateOptimalBlocksPerVendor(int availableBlocks, int totalVendors) {
    if (totalVendors <= 0 || availableBlocks <= 0) return 0;
    
    print('📊 Cálculo automático: $availableBlocks bloques disponibles, $totalVendors vendedores');
    
    // Calcular bloques por vendedor de manera equitativa
    final baseBlocksPerVendor = availableBlocks ~/ totalVendors;
    
    print('📊 Base: ${baseBlocksPerVendor} bloques por vendedor');
    
    // Asegurar que cada vendedor reciba al menos 1 bloque
    if (baseBlocksPerVendor < 1) {
      print('⚠️ Solo hay suficientes bloques para asignar 1 bloque por vendedor');
      return 1;
    }
    
    // Si hay bloques extra, distribuirlos equitativamente
    final remainingBlocks = availableBlocks % totalVendors;
    final finalBlocksPerVendor = baseBlocksPerVendor + (remainingBlocks > 0 ? 1 : 0);
    
    print('📊 Bloques extra: $remainingBlocks');
    print('📊 Resultado final: $finalBlocksPerVendor bloques por vendedor');
    
    // Verificar que la distribución sea viable
    final totalBlocksNeeded = totalVendors * finalBlocksPerVendor;
    if (totalBlocksNeeded > availableBlocks) {
      // Si no es viable, reducir a la cantidad base
      print('⚠️ Distribución ajustada: ${baseBlocksPerVendor} bloques por vendedor para evitar exceder límite');
      return baseBlocksPerVendor;
    }
    
    return finalBlocksPerVendor;
  }
}
