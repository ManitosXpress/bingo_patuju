import 'package:flutter/foundation.dart';

enum BingoPattern {
  diagonalPrincipal,
  diagonalSecundaria,
  lineaHorizontal,
  marcoCompleto,
  marcoPequeno,
  spoutnik,
  corazon,
  cartonLleno,
  consuelo,
  x,
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
      rounds: [
        BingoGameRound(
          id: 'juego1',
          name: 'Juego 1',
          patterns: [BingoPattern.diagonalPrincipal, BingoPattern.marcoPequeno, BingoPattern.cartonLleno],
          description: 'Diagonal Principal, Marco Pequeño, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego1_consuelo',
          name: 'Consuelo (2do Cartón Lleno)',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego2',
          name: 'Juego 2',
          patterns: [BingoPattern.diagonalSecundaria, BingoPattern.marcoCompleto, BingoPattern.cartonLleno],
          description: 'Diagonal Secundaria, Marco Completo, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego2_consuelo',
          name: 'Consuelo (2do Cartón Lleno)',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego3',
          name: 'Juego 3',
          patterns: [BingoPattern.lineaHorizontal, BingoPattern.x, BingoPattern.marcoCompleto, BingoPattern.cartonLleno],
          description: 'Línea Horizontal, X, Marco Completo, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego3_consuelo',
          name: 'Consuelo (2do Cartón Lleno)',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego4',
          name: 'Juego 4',
          patterns: [BingoPattern.x, BingoPattern.spoutnik, BingoPattern.corazon, BingoPattern.cartonLleno],
          description: 'X, Spoutnik, Corazón, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego4_consuelo',
          name: 'Consuelo (2do Cartón Lleno)',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
      ],
    ),
    BingoGameConfig(
      id: 'martes',
      name: 'Partida de Bingo Martes',
      date: 'Martes',
      rounds: [
        BingoGameRound(
          id: 'juego1',
          name: 'Juego 1',
          patterns: [BingoPattern.marcoCompleto, BingoPattern.cartonLleno],
          description: 'Marco Completo, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego1_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego2',
          name: 'Juego 2',
          patterns: [BingoPattern.diagonalPrincipal, BingoPattern.corazon, BingoPattern.cartonLleno],
          description: 'Diagonal Principal, Corazón, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego2_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
      ],
    ),
    BingoGameConfig(
      id: 'miercoles',
      name: 'Partida de Bingo Miércoles',
      date: 'Miércoles',
      rounds: [
        BingoGameRound(
          id: 'juego1',
          name: 'Juego 1',
          patterns: [BingoPattern.spoutnik, BingoPattern.marcoPequeno, BingoPattern.cartonLleno],
          description: 'Spoutnik, Marco Pequeño, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego1_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego2',
          name: 'Juego 2',
          patterns: [BingoPattern.lineaHorizontal, BingoPattern.x, BingoPattern.cartonLleno],
          description: 'Línea Horizontal, X, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego2_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
      ],
    ),
    BingoGameConfig(
      id: 'jueves',
      name: 'Partida de Bingo Jueves',
      date: 'Jueves',
      rounds: [
        BingoGameRound(
          id: 'juego1',
          name: 'Juego 1',
          patterns: [BingoPattern.diagonalSecundaria, BingoPattern.marcoPequeno, BingoPattern.cartonLleno],
          description: 'Diagonal Secundaria, Marco Pequeño, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego1_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego2',
          name: 'Juego 2',
          patterns: [BingoPattern.x, BingoPattern.corazon, BingoPattern.marcoCompleto, BingoPattern.cartonLleno],
          description: 'X, Corazón, Marco Completo, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego2_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego3',
          name: 'Juego 3',
          patterns: [BingoPattern.lineaHorizontal, BingoPattern.spoutnik, BingoPattern.cartonLleno],
          description: 'Línea Horizontal, Spoutnik, Cartón Lleno',
        ),
      ],
    ),
    BingoGameConfig(
      id: 'viernes',
      name: 'Partida de Bingo Viernes',
      date: 'Viernes',
      rounds: [
        BingoGameRound(
          id: 'juego1',
          name: 'Juego 1',
          patterns: [BingoPattern.diagonalPrincipal, BingoPattern.marcoCompleto, BingoPattern.cartonLleno],
          description: 'Diagonal Principal, Marco Completo, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego1_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego2',
          name: 'Juego 2',
          patterns: [BingoPattern.corazon, BingoPattern.x, BingoPattern.cartonLleno],
          description: 'Corazón, X, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego2_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego3',
          name: 'Juego 3',
          patterns: [BingoPattern.spoutnik, BingoPattern.lineaHorizontal, BingoPattern.marcoPequeno, BingoPattern.cartonLleno],
          description: 'Spoutnik, Línea Horizontal, Marco Pequeño, Cartón Lleno',
        ),
      ],
    ),
    BingoGameConfig(
      id: 'sabado',
      name: 'Partida de Bingo Sábado',
      date: 'Sábado',
      rounds: [
        BingoGameRound(
          id: 'juego1',
          name: 'Juego 1',
          patterns: [BingoPattern.marcoPequeno, BingoPattern.diagonalSecundaria, BingoPattern.cartonLleno],
          description: 'Marco Pequeño, Diagonal Secundaria, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego1_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego2',
          name: 'Juego 2',
          patterns: [BingoPattern.lineaHorizontal, BingoPattern.corazon, BingoPattern.cartonLleno],
          description: 'Línea Horizontal, Corazón, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego2_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego3',
          name: 'Juego 3',
          patterns: [BingoPattern.x, BingoPattern.marcoCompleto, BingoPattern.cartonLleno],
          description: 'X, Marco Completo, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego3_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
      ],
    ),
    BingoGameConfig(
      id: 'domingo',
      name: 'Partida de Bingo Domingo',
      date: 'Domingo',
      rounds: [
        BingoGameRound(
          id: 'juego1',
          name: 'Juego 1',
          patterns: [BingoPattern.diagonalPrincipal, BingoPattern.x, BingoPattern.cartonLleno],
          description: 'Diagonal Principal, X, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego1_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego2',
          name: 'Juego 2',
          patterns: [BingoPattern.marcoCompleto, BingoPattern.spoutnik, BingoPattern.cartonLleno],
          description: 'Marco Completo, Spoutnik, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego2_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
        BingoGameRound(
          id: 'juego3',
          name: 'Juego 3',
          patterns: [BingoPattern.lineaHorizontal, BingoPattern.marcoPequeno, BingoPattern.corazon, BingoPattern.cartonLleno],
          description: 'Línea Horizontal, Marco Pequeño, Corazón, Cartón Lleno',
        ),
        BingoGameRound(
          id: 'juego3_consuelo',
          name: 'Consuelo',
          patterns: [BingoPattern.cartonLleno],
          description: 'Segundo cartón lleno',
        ),
      ],
    ),
  ];
} 