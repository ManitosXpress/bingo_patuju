import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RevenueInfoCard extends StatelessWidget {
  final int totalSold;
  final double cardPrice;
  final double retentionPercentage; // 0.80 para Líderes, 0.70 para Vendedores
  final String title;
  final Color baseColor;

  const RevenueInfoCard({
    Key? key,
    required this.totalSold,
    required this.cardPrice,
    required this.retentionPercentage, // Ejem: 0.8 para 80%
    this.title = "Ingreso Neto Estimado",
    this.baseColor = const Color(0xFF4CAF50), // Verde por defecto
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fórmulas matemáticas simplificadas para rendimiento
    // Líder: (V * P) - (V * P * 0.20) es matemáticamente igual a (V * P) * 0.80
    final double grossTotal = totalSold * cardPrice;
    final double netIncome = grossTotal * retentionPercentage;
    
    final currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs. ');

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                Icon(Icons.monetization_on_outlined, color: baseColor, size: 20),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Cartillas: $totalSold",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  currencyFormat.format(netIncome),
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: baseColor
                  ),
                ),
              ],
            ),
            // Opcional: Mostrar el desglose pequeño
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Retención: ${(retentionPercentage * 100).toInt()}%",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }
}
