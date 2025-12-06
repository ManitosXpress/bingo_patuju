import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados posibles de un evento
enum EventStatus {
  upcoming,
  active,
  completed;

  String toJson() => name;

  static EventStatus fromJson(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventStatus.upcoming,
    );
  }

  String get displayName {
    switch (this) {
      case EventStatus.upcoming:
        return 'Próximo';
      case EventStatus.active:
        return 'Activo';
      case EventStatus.completed:
        return 'Completado';
    }
  }
}

/// Modelo para eventos de Bingo
class BingoEvent {
  final String id;
  final String name;
  final String date; // ISO 8601
  final String? description;
  final EventStatus status;
  final int totalCartillas;
  final DateTime createdAt;
  final DateTime updatedAt;

  BingoEvent({
    required this.id,
    required this.name,
    required this.date,
    this.description,
    required this.status,
    required this.totalCartillas,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crear desde JSON (del backend)
  factory BingoEvent.fromJson(Map<String, dynamic> json) {
    return BingoEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      date: json['date'] as String,
      description: json['description'] as String?,
      status: EventStatus.fromJson(json['status'] as String? ?? 'upcoming'),
      totalCartillas: json['totalCartillas'] as int? ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  /// Crear desde Firestore DocumentSnapshot
  factory BingoEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BingoEvent(
      id: doc.id,
      name: data['name'] as String,
      date: data['date'] as String,
      description: data['description'] as String?,
      status: EventStatus.fromJson(data['status'] as String? ?? 'upcoming'),
      totalCartillas: data['totalCartillas'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertir a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'description': description,
      'status': status.toJson(),
      'totalCartillas': totalCartillas,
    };
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'date': date,
      'description': description ?? '',
      'status': status.toJson(),
      'totalCartillas': totalCartillas,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Crear copia con cambios
  BingoEvent copyWith({
    String? id,
    String? name,
    String? date,
    String? description,
    EventStatus? status,
    int? totalCartillas,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BingoEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      description: description ?? this.description,
      status: status ?? this.status,
      totalCartillas: totalCartillas ?? this.totalCartillas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper para parsear DateTime desde diferentes formatos
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    
    if (value is String) {
      return DateTime.parse(value);
    }
    
    return DateTime.now();
  }

  /// Obtener fecha formateada
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  /// Verificar si el evento está activo
  bool get isActive => status == EventStatus.active;

  /// Verificar si el evento está completado
  bool get isCompleted => status == EventStatus.completed;

  @override
  String toString() {
    return 'BingoEvent(id: $id, name: $name, date: $date, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is BingoEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
