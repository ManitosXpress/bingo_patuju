import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

/// Widget selector de fecha para filtrar cartillas por día
class DateSelectorWidget extends StatelessWidget {
  const DateSelectorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final selectedDate = appProvider.selectedDate;
    
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.parse(selectedDate),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          helpText: 'Seleccionar fecha del evento',
          cancelText: 'Cancelar',
          confirmText: 'Seleccionar',
        );
        
        if (picked != null) {
          // Formatear fecha como YYYY-MM-DD
          final dateStr = DateFormat('yyyy-MM-dd').format(picked);
          appProvider.setSelectedDate(dateStr);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Fecha del evento:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: Colors.blue, size: 24),
          ],
        ),
      ),
    );
  }
  
  /// Formatea la fecha de YYYY-MM-DD a formato legible DD/MM/YYYY
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return isoDate;
    }
  }
}
