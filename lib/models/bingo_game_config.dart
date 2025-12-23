import 'package:flutter/foundation.dart';

enum BingoPattern {
  diagonalPrincipal,
  diagonalSecundaria,
  lineaHorizontal,
  lineaVertical, // Agregado
  marcoCompleto,
  marcoPequeno,
  spoutnik,
  corazon,
  cartonLleno,
  consuelo,
  x,
  // Patrones adicionales
  figuraAvion, // Agregado
  caidaNieve, // Agregado
  arbolFlecha, // Agregado
  letraI, // Agregado
  letraN, // Agregado
  autopista, // Agregado
  // Nuevas figuras legendarias
  relojArena,
  dobleLineaV,
  figuraSuegra,
  figuraComodin,
  letraFE,
  figuraCLoca,
  figuraBandera,
  figuraTripleLinea,
}

class BingoGameConfig {
  final String id;
  final String name;
  final String date;
  final List<BingoGameRound> rounds;
  final bool isActive;

  BingoGameConfig({
    required this.id,
    required this.name,
    required this.date,
    required this.rounds,
    this.isActive = false,
  });

  factory BingoGameConfig.fromJson(Map<String, dynamic> json) {
    return BingoGameConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      rounds: (json['rounds'] as List<dynamic>?)
          ?.map((round) => BingoGameRound.fromJson(round))
          .toList() ?? [],
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'rounds': rounds.map((round) => round.toJson()).toList(),
      'isActive': isActive,
    };
  }

  BingoGameConfig copyWith({
    String? id,
    String? name,
    String? date,
    List<BingoGameRound>? rounds,
    bool? isActive,
  }) {
    return BingoGameConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      rounds: rounds ?? this.rounds,
      isActive: isActive ?? this.isActive,
    );
  }
}

class BingoGameRound {
  final String id;
  final String name;
  final List<BingoPattern> patterns;
  final String? description;
  bool isCompleted;

  BingoGameRound({
    required this.id,
    required this.name,
    required this.patterns,
    this.description,
    this.isCompleted = false,
  });

  factory BingoGameRound.fromJson(Map<String, dynamic> json) {
    return BingoGameRound(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      patterns: (json['patterns'] as List<dynamic>?)
          ?.map((pattern) => BingoPattern.values.firstWhere(
                (e) => e.toString().split('.').last == pattern,
                orElse: () => BingoPattern.cartonLleno,
              ))
          .toList() ?? [],
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'patterns': patterns.map((pattern) => pattern.toString().split('.').last).toList(),
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  BingoGameRound copyWith({
    String? id,
    String? name,
    List<BingoPattern>? patterns,
    String? description,
    bool? isCompleted,
  }) {
    return BingoGameRound(
      id: id ?? this.id,
      name: name ?? this.name,
      patterns: patterns ?? this.patterns,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  String get patternsDisplay {
    return patterns.map((pattern) => _getPatternDisplayName(pattern)).join(' • ');
  }

  String _getPatternDisplayName(BingoPattern pattern) {
    switch (pattern) {
      case BingoPattern.diagonalPrincipal:
        return 'Diagonal Principal';
      case BingoPattern.diagonalSecundaria:
        return 'Diagonal Secundaria';
      case BingoPattern.lineaHorizontal:
        return 'Línea Horizontal';
      case BingoPattern.lineaVertical:
        return 'Línea Vertical';
      case BingoPattern.marcoCompleto:
        return 'Marco Completo';
      case BingoPattern.marcoPequeno:
        return 'Marco Pequeño';
      case BingoPattern.spoutnik:
        return 'Spoutnik';
      case BingoPattern.corazon:
        return 'Corazón';
      case BingoPattern.cartonLleno:
        return 'Cartón Lleno';
      case BingoPattern.consuelo:
        return 'Consuelo';
      case BingoPattern.x:
        return 'X';
      // Patrones adicionales
      case BingoPattern.figuraAvion:
        return 'Figura Avión';
      case BingoPattern.caidaNieve:
        return 'Caída de Nieve';
      case BingoPattern.arbolFlecha:
        return 'Árbol o Flecha';
      case BingoPattern.letraI:
        return 'LETRA I';
      case BingoPattern.letraN:
        return 'LETRA N';
      case BingoPattern.autopista:
        return 'Autopista';
      // Nuevas figuras legendarias
      case BingoPattern.relojArena:
        return 'Reloj de Arena';
      case BingoPattern.dobleLineaV:
        return 'Doble Línea V';
      case BingoPattern.figuraSuegra:
        return 'Figura la Suegra';
      case BingoPattern.figuraComodin:
        return 'Figura Infinito';
      case BingoPattern.letraFE:
        return 'Letra FE';
      case BingoPattern.figuraCLoca:
        return 'Figura C Loca';
      case BingoPattern.figuraBandera:
        return 'Figura Bandera';
      case BingoPattern.figuraTripleLinea:
        return 'Figura Triple Línea';
    }
  }
}

// Configuraciones predefinidas de juegos
class BingoGamePresets {
  static List<BingoGameConfig> get defaultGames => [
    BingoGameConfig(
      id: 'lunes',
      name: 'Partida de Bingo Lunes',
      date: 'Lunes',
      rounds: [], // Sin rondas predefinidas - el usuario las crea desde cero
    ),
    BingoGameConfig(
      id: 'martes',
      name: 'Partida de Bingo Martes',
      date: 'Martes',
      rounds: [], // Sin rondas predefinidas - el usuario las crea desde cero
    ),
    BingoGameConfig(
      id: 'miercoles',
      name: 'Partida de Bingo Miércoles',
      date: 'Miércoles',
      rounds: [], // Sin rondas predefinidas - el usuario las crea desde cero
    ),
    BingoGameConfig(
      id: 'jueves',
      name: 'Partida de Bingo Jueves',
      date: 'Jueves',
      rounds: [], // Sin rondas predefinidas - el usuario las crea desde cero
    ),
    BingoGameConfig(
      id: 'viernes',
      name: 'Partida de Bingo Viernes',
      date: 'Viernes',
      rounds: [], // Sin rondas predefinidas - el usuario las crea desde cero
    ),
    BingoGameConfig(
      id: 'sabado',
      name: 'Partida de Bingo Sábado',
      date: 'Sábado',
      rounds: [], // Sin rondas predefinidas - el usuario las crea desde cero
    ),
    BingoGameConfig(
      id: 'domingo',
      name: 'Partida de Bingo Domingo',
      date: 'Domingo',
      rounds: [], // Sin rondas predefinidas - el usuario las crea desde cero
    ),
  ];
  
  // Método para generar juegos con figuras legendarias incluidas
  static List<BingoGameConfig> getGamesWithLegendaryFigures() {
    return [
      _createGameWithLegendaryFigures('lunes', 'Partida de Bingo Lunes', 'Lunes', 8),
      _createGameWithLegendaryFigures('martes', 'Partida de Bingo Martes', 'Martes', 4),
      _createGameWithLegendaryFigures('miercoles', 'Partida de Bingo Miércoles', 'Miércoles', 4),
      _createGameWithLegendaryFigures('jueves', 'Partida de Bingo Jueves', 'Jueves', 5),
      _createGameWithLegendaryFigures('viernes', 'Partida de Bingo Viernes', 'Viernes', 5),
      _createGameWithLegendaryFigures('sabado', 'Partida de Bingo Sábado', 'Sábado', 6),
      _createGameWithLegendaryFigures('domingo', 'Partida de Bingo Domingo', 'Domingo', 6),
    ];
  }
  
  // Método auxiliar para crear un juego con figuras legendarias
  static BingoGameConfig _createGameWithLegendaryFigures(String id, String name, String date, int roundCount) {
    final rounds = <BingoGameRound>[];
    
    // Crear rondas con figuras legendarias incluidas
    for (int i = 0; i < roundCount; i++) {
      final isConsuelo = i % 2 == 1; // Rondas alternas son consuelos
      
      if (isConsuelo) {
        // Ronda de consuelo
        rounds.add(BingoGameRound(
          id: 'consuelo_${i + 1}',
          name: 'Consuelo ${i + 1}',
          patterns: [BingoPattern.cartonLleno],
          description: 'Ronda de consuelo con cartón lleno',
        ));
      } else {
        // Ronda principal con figuras legendarias
        final patterns = <BingoPattern>[];
        
        // Agregar figuras básicas
        patterns.addAll([
          BingoPattern.diagonalPrincipal,
          BingoPattern.marcoPequeno,
        ]);
        
        // Agregar figuras legendarias según el índice de la ronda
        switch (i) {
          case 0:
            patterns.addAll([
              BingoPattern.relojArena,
              BingoPattern.dobleLineaV,
            ]);
            break;
          case 2:
            patterns.addAll([
              BingoPattern.figuraSuegra,
              BingoPattern.figuraComodin,
            ]);
            break;
          case 4:
            patterns.addAll([
              BingoPattern.letraFE,
              BingoPattern.figuraCLoca,
            ]);
            break;
          case 6:
            patterns.addAll([
              BingoPattern.figuraBandera,
              BingoPattern.figuraTripleLinea,
            ]);
            break;
          default:
            patterns.addAll([
              BingoPattern.x,
            ]);
        }
        
        rounds.add(BingoGameRound(
          id: 'ronda_${i + 1}',
          name: 'Ronda ${i + 1}',
          patterns: patterns,
          description: 'Ronda con figuras legendarias incluidas',
        ));
      }
    }
    
    return BingoGameConfig(
      id: id,
      name: name,
      date: date,
      rounds: rounds,
    );
  }
} 