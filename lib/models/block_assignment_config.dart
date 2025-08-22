class BlockAssignmentConfig {
  final int blockSize;
  final int skipBlocks;
  final int startCard;
  final int totalBlocks; // Cambiado de totalCards a totalBlocks
  final int quantityBlocksToAssign; // Nueva: cantidad de bloques a asignar
  final bool useRandomBlocks; // Nueva: si usar selección aleatoria de bloques
  final bool assignToAllVendors;

  const BlockAssignmentConfig({
    required this.blockSize,
    required this.skipBlocks,
    required this.startCard,
    required this.totalBlocks, // Cambiado de totalCards a totalBlocks
    required this.quantityBlocksToAssign,
    this.useRandomBlocks = true,
    this.assignToAllVendors = true,
  });

  /// Calcular bloques por vendedor automáticamente
  int get blocksPerVendor => 1; // Por defecto 1 bloque por vendedor

  /// Total de cartillas disponibles
  int get totalCards => totalBlocks * blockSize;

  /// Bloques disponibles después de saltar los primeros
  int get availableBlocks => totalBlocks - skipBlocks;

  /// Cartilla inicial real (considerando startCard)
  int get actualStartCard => startCard;

  /// Cartilla final real
  int get actualEndCard => totalCards;

  /// Cantidad total de cartillas que se asignarán
  int get totalCardsToAssign => quantityBlocksToAssign * blockSize;

  /// Cantidad de vendedores/líderes que se pueden asignar
  int get maxVendors => (quantityBlocksToAssign / blocksPerVendor).ceil();

  /// Validar configuración
  List<String> validate() {
    final errors = <String>[];

    if (blockSize <= 0) {
      errors.add('El tamaño del bloque debe ser mayor a 0');
    }

    if (skipBlocks < 0) {
      errors.add('Los bloques a saltar no pueden ser negativos');
    }

    if (startCard < 1) {
      errors.add('La cartilla inicial debe ser mayor a 0');
    }

    if (totalBlocks <= 0) {
      errors.add('El total de bloques debe ser mayor a 0');
    }

    if (startCard > totalCards) {
      errors.add('La cartilla inicial no puede ser mayor al total de cartillas');
    }

    // Solo validar cantidad de bloques si NO es asignación automática
    if (!assignToAllVendors && quantityBlocksToAssign <= 0) {
      errors.add('La cantidad de bloques a asignar debe ser mayor a 0');
    }

    // Solo validar límite de bloques si NO es asignación automática
    if (!assignToAllVendors && quantityBlocksToAssign > availableBlocks) {
      errors.add('No hay suficientes bloques disponibles (${availableBlocks}) para asignar ${quantityBlocksToAssign}');
    }

    if (blockSize > totalCards) {
      errors.add('El tamaño del bloque no puede ser mayor al total de cartillas');
    }

    return errors;
  }

  /// Generar números de cartillas para bloques específicos
  List<int> generateCardNumbers(List<int> blockNumbers) {
    final cards = <int>[];
    
    for (final blockNumber in blockNumbers) {
      if (blockNumber < 0 || blockNumber >= totalBlocks) continue;
      
      final startCardInBlock = startCard + (blockNumber * blockSize);
      final endCardInBlock = (startCardInBlock + blockSize - 1).clamp(0, totalCards);
      
      for (int i = startCardInBlock; i <= endCardInBlock; i++) {
        if (i <= totalCards) {
          cards.add(i);
        }
      }
    }
    
    return cards;
  }

  /// Generar números de cartillas para la asignación completa
  List<int> generateAllCardNumbers() {
    if (quantityBlocksToAssign <= 0) return [];
    
    List<int> selectedBlocks;
    
    if (useRandomBlocks) {
      // Selección aleatoria de bloques
      final availableBlockNumbers = List.generate(availableBlocks, (i) => skipBlocks + i);
      availableBlockNumbers.shuffle();
      selectedBlocks = availableBlockNumbers.take(quantityBlocksToAssign).toList();
    } else {
      // Selección secuencial de bloques
      selectedBlocks = List.generate(quantityBlocksToAssign, (i) => skipBlocks + i);
    }
    
    return generateCardNumbers(selectedBlocks);
  }

  /// Generar números de cartillas para un vendedor específico
  List<int> generateCardsForVendor(int vendorIndex) {
    final startBlock = vendorIndex; // 1 bloque por vendedor
    final endBlock = startBlock;
    
    final blockNumbers = [startBlock];
    
    return generateCardNumbers(blockNumbers);
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'blockSize': blockSize,
      'skipBlocks': skipBlocks,
      'startCard': startCard,
      'totalBlocks': totalBlocks, // Cambiado de totalCards a totalBlocks
      'quantityBlocksToAssign': quantityBlocksToAssign,
      'useRandomBlocks': useRandomBlocks,
      'assignToAllVendors': assignToAllVendors,
    };
  }

  /// Crear desde JSON
  factory BlockAssignmentConfig.fromJson(Map<String, dynamic> json) {
    return BlockAssignmentConfig(
      blockSize: json['blockSize'] ?? 5,
      skipBlocks: json['skipBlocks'] ?? 0,
      startCard: json['startCard'] ?? 1,
      totalBlocks: json['totalBlocks'] ?? 200, // Cambiado de totalCards a totalBlocks
      quantityBlocksToAssign: json['quantityBlocksToAssign'] ?? 10,
      useRandomBlocks: json['useRandomBlocks'] ?? true,
      assignToAllVendors: json['assignToAllVendors'] ?? true,
    );
  }

  /// Crear copia con cambios
  BlockAssignmentConfig copyWith({
    int? blockSize,
    int? skipBlocks,
    int? startCard,
    int? totalBlocks, // Cambiado de totalCards a totalBlocks
    int? quantityBlocksToAssign,
    bool? useRandomBlocks,
    bool? assignToAllVendors,
  }) {
    return BlockAssignmentConfig(
      blockSize: blockSize ?? this.blockSize,
      skipBlocks: skipBlocks ?? this.skipBlocks,
      startCard: startCard ?? this.startCard,
      totalBlocks: totalBlocks ?? this.totalBlocks, // Cambiado de totalCards a totalBlocks
      quantityBlocksToAssign: quantityBlocksToAssign ?? this.quantityBlocksToAssign,
      useRandomBlocks: useRandomBlocks ?? this.useRandomBlocks,
      assignToAllVendors: assignToAllVendors ?? this.assignToAllVendors,
    );
  }

  /// Configuración por defecto
  factory BlockAssignmentConfig.defaultConfig() {
    return const BlockAssignmentConfig(
      blockSize: 5,
      skipBlocks: 0,
      startCard: 1,
      totalBlocks: 200, // Cambiado de totalCards a totalBlocks
      quantityBlocksToAssign: 10,
      useRandomBlocks: true,
      assignToAllVendors: true,
    );
  }
}
