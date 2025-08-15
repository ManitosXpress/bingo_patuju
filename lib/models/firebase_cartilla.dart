class FirebaseCartilla {
  final String id;
  final List<List<int>> numbers;
  final String? assignedTo;
  final bool sold;
  final int createdAt;
  final int? cardNo;

  FirebaseCartilla({
    required this.id,
    required this.numbers,
    this.assignedTo,
    required this.sold,
    required this.createdAt,
    this.cardNo,
  });

  factory FirebaseCartilla.fromJson(Map<String, dynamic> json) {
    try {
      // DEBUG: Imprimir el JSON recibido
      print('DEBUG: FirebaseCartilla.fromJson - JSON recibido: $json');
      
      // Validar que el ID exista y sea una cadena
      final id = json['id'] as String?;
      if (id == null || id.isEmpty) {
        throw FormatException('ID de cartilla inválido o faltante');
      }
      
      // DEBUG: Verificar cardNo
      final cardNo = json['cardNo'];
      print('DEBUG: cardNo raw: $cardNo, tipo: ${cardNo.runtimeType}');
      
      // Validar que numbers exista y sea una lista
      final numbersData = json['numbers'] as List?;
      if (numbersData == null) {
        throw FormatException('Números de cartilla faltantes');
      }
      
      // Convertir los números con validación
      final numbers = <List<int>>[];
      for (int i = 0; i < numbersData.length; i++) {
        final row = numbersData[i];
        if (row is! List) {
          throw FormatException('Fila $i no es una lista válida');
        }
        
        final rowNumbers = <int>[];
        for (int j = 0; j < row.length; j++) {
          final num = row[j];
          if (num is! int) {
            throw FormatException('Número en posición [$i][$j] no es un entero válido');
          }
          rowNumbers.add(num);
        }
        numbers.add(rowNumbers);
      }
      
      final cartilla = FirebaseCartilla(
        id: id,
        numbers: numbers,
        assignedTo: json['assignedTo'] as String?,
        sold: json['sold'] as bool? ?? false,
        createdAt: json['createdAt'] as int? ?? 0,
        cardNo: json['cardNo'] as int?,
      );
      
      // DEBUG: Verificar el objeto creado
      print('DEBUG: FirebaseCartilla creada - cardNo: ${cartilla.cardNo}, displayNumber: ${cartilla.displayNumber}');
      
      return cartilla;
    } catch (e) {
      // Si hay un error de formato, crear una cartilla por defecto o re-lanzar
      print('Error creando FirebaseCartilla desde JSON: $e');
      print('JSON recibido: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numbers': numbers,
      'assignedTo': assignedTo,
      'sold': sold,
      'createdAt': createdAt,
      if (cardNo != null) 'cardNo': cardNo,
    };
  }

  // Convertir a formato de cartilla local
  List<List<int>> toLocalCartilla() {
    return numbers;
  }

  // Verificar si la cartilla está asignada
  bool get isAssigned => assignedTo != null;

  // Verificar que la estructura de la cartilla sea válida
  bool get isValidStructure {
    if (numbers.length != 5) return false;
    for (final row in numbers) {
      if (row.length != 5) return false;
    }
    return true;
  }

  // Obtener el número de cartilla para mostrar
  String get displayNumber {
    print('DEBUG: displayNumber - cardNo: $cardNo, id: $id');
    
    if (cardNo != null) {
      final result = 'Cartilla $cardNo';
      print('DEBUG: displayNumber retorna: $result');
      return result;
    }
    
    // Fallback: mostrar ID truncado si no hay número de cartilla
    if (id.length >= 8) {
      final result = 'Cartilla ${id.substring(0, 8)}...';
      print('DEBUG: displayNumber fallback: $result');
      return result;
    } else {
      final result = 'Cartilla $id';
      print('DEBUG: displayNumber fallback corto: $result');
      return result;
    }
  }

  // Obtener una representación visual de los números de la cartilla
  String get numbersDisplay {
    if (numbers.isEmpty) return 'Sin números';
    
    final List<String> rows = [];
    for (int i = 0; i < numbers.length; i++) {
      final row = numbers[i];
      if (row.isNotEmpty) {
        final rowStr = row.map((n) => n.toString().padLeft(2)).join(' ');
        rows.add(rowStr);
      }
    }
    
    return rows.join('\n');
  }

  // Obtener fecha formateada
  String get formattedDate {
    final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
    return '${date.day}/${date.month}/${date.year}';
  }
} 