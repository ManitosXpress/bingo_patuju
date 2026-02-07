// Exportar todos los modelos de asignación por bloques
export 'block_assignment_config.dart';

class VendorBlockAssignment {
  final String vendorId;
  final String vendorName;
  final List<int> assignedCards;
  final List<String> soldCartillas;
  final int soldCount;

  VendorBlockAssignment({
    required this.vendorId,
    required this.vendorName,
    required this.assignedCards,
    this.soldCartillas = const [],
    this.soldCount = 0,
  });

  factory VendorBlockAssignment.fromJson(Map<String, dynamic> json) {
    // Parsear assignedCards
    List<int> assigned = [];
    if (json['assignedCards'] != null) {
      if (json['assignedCards'] is List) {
        assigned = (json['assignedCards'] as List).map((e) {
          if (e is int) return e;
          if (e is Map) return e['cardNo'] as int? ?? 0;
          return int.tryParse(e.toString()) ?? 0;
        }).toList();
      }
    }

    // Parsear soldCartillas
    List<String> sold = [];
    if (json['soldCartillas'] != null) {
      sold = (json['soldCartillas'] as List).map((e) => e.toString()).toList();
    } else if (json['cartillas_vendidas'] != null) {
      sold = (json['cartillas_vendidas'] as List).map((e) => e.toString()).toList();
    }

    return VendorBlockAssignment(
      vendorId: json['vendorId']?.toString() ?? '',
      vendorName: json['vendorName']?.toString() ?? 'Vendedor',
      assignedCards: assigned,
      soldCartillas: sold,
      soldCount: json['soldCount'] as int? ?? sold.length,
    );
  }
}
