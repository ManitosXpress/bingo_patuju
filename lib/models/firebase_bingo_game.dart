import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para guardar juegos de bingo en Firebase
class FirebaseBingoGame {
  final String id;
  final String eventId; // NUEVO - FK al evento
  final String name;
  final String date;
  final List<FirebaseBingoRound> rounds;
  final int totalCartillas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;

  FirebaseBingoGame({
    required this.id,
    required this.eventId,
    required this.name,
    required this.date,
    required this.rounds,
    required this.totalCartillas,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
  });

  /// Crear desde un documento de Firestore
  factory FirebaseBingoGame.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FirebaseBingoGame(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      name: data['name'] ?? '',
      date: data['date'] ?? '',
      rounds: (data['rounds'] as List<dynamic>?)
          ?.map((round) => FirebaseBingoRound.fromMap(round))
          .toList() ?? [],
      totalCartillas: data['totalCartillas'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  /// Convertir a mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'name': name,
      'date': date,
      'rounds': rounds.map((round) => round.toMap()).toList(),
      'totalCartillas': totalCartillas,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isCompleted': isCompleted,
    };
  }

  /// Crear una copia con cambios
  FirebaseBingoGame copyWith({
    String? id,
    String? eventId,
    String? name,
    String? date,
    List<FirebaseBingoRound>? rounds,
    int? totalCartillas,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
  }) {
    return FirebaseBingoGame(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      date: date ?? this.date,
      rounds: rounds ?? this.rounds,
      totalCartillas: totalCartillas ?? this.totalCartillas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Crear desde el modelo local
  factory FirebaseBingoGame.fromLocalGame(dynamic localGame) {
    return FirebaseBingoGame(
      id: localGame.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      eventId: localGame.eventId ?? localGame.date ?? 'Sin fecha',
      name: localGame.name ?? 'Nuevo Juego',
      date: localGame.date ?? 'Sin fecha',
      rounds: (localGame.rounds as List<dynamic>?)
          ?.map((round) => FirebaseBingoRound.fromLocalRound(round))
          .toList() ?? [],
      totalCartillas: localGame.totalCartillas ?? 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isCompleted: localGame.isCompleted ?? false,
    );
  }

  /// Crear desde un mapa JSON (del backend)
  factory FirebaseBingoGame.fromMap(Map<String, dynamic> map) {
    return FirebaseBingoGame(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? map['date'] ?? '',
      name: map['name'] ?? '',
      date: map['date'] ?? '',
      rounds: (map['rounds'] as List<dynamic>?)
          ?.map((round) => FirebaseBingoRound.fromMap(round))
          .toList() ?? [],
      totalCartillas: map['totalCartillas'] ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  /// Crear desde BingoGameConfig (modelo local del UI)
  factory FirebaseBingoGame.fromBingoGameConfig(
    dynamic gameConfig, {
    required int totalCartillas,
  }) {
    final now = DateTime.now();
    return FirebaseBingoGame(
      id: gameConfig.id,
      eventId: gameConfig.date, // Usar date como eventId
      name: gameConfig.name,
      date: gameConfig.date,
      rounds: (gameConfig.rounds as List<dynamic>)
          .map((round) => FirebaseBingoRound.fromBingoGameRound(round))
          .toList(),
      totalCartillas: totalCartillas,
      createdAt: now,
      updatedAt: now,
      isCompleted: false,
    );
  }
}

/// Modelo para guardar rondas de bingo en Firebase
class FirebaseBingoRound {
  final String id;
  final String name;
  final List<String> patterns;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  FirebaseBingoRound({
    required this.id,
    required this.name,
    required this.patterns,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crear desde un mapa
  factory FirebaseBingoRound.fromMap(Map<String, dynamic> map) {
    return FirebaseBingoRound(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      patterns: List<String>.from(map['patterns'] ?? []),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertir a mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'patterns': patterns,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Crear desde el modelo local
  factory FirebaseBingoRound.fromLocalRound(dynamic localRound) {
    return FirebaseBingoRound(
      id: localRound.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: localRound.name ?? 'Nueva Ronda',
      patterns: (localRound.patterns as List<dynamic>?)
          ?.map((pattern) => pattern.toString())
          .toList() ?? [],
      isCompleted: localRound.isCompleted ?? false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Crear desde BingoGameRound (modelo local del UI)
  factory FirebaseBingoRound.fromBingoGameRound(dynamic gameRound) {
    final now = DateTime.now();
    return FirebaseBingoRound(
      id: gameRound.id,
      name: gameRound.name,
      patterns: (gameRound.patterns as List<dynamic>)
          .map((pattern) => pattern.toString().split('.').last)
          .toList(),
      isCompleted: gameRound.isCompleted ?? false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Crear una copia con cambios
  FirebaseBingoRound copyWith({
    String? id,
    String? name,
    List<String>? patterns,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FirebaseBingoRound(
      id: id ?? this.id,
      name: name ?? this.name,
      patterns: patterns ?? this.patterns,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
