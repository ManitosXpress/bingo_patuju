import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'cartilla_image_renderer.dart';
import 'file_saver/file_saver.dart';

class CartillaHelper {
  static List<List<int>> convertNumbersToColumns(List<dynamic> numbers) {
    final flat = numbers.map((e) => int.tryParse(e.toString()) ?? 0).toList();
    
    // Si la lista está vacía, retornar lista vacía
    if (flat.isEmpty) return [];
    
    // Intentar dividir en 5 columnas (estándar Bingo)
    final columns = <List<int>>[];
    // Asumimos que los números vienen ordenados por columnas o filas para formar 5 columnas
    // Si hay 25 números, son 5 columnas de 5
    // Si hay 24 números, probablemente falta el centro, pero aquí asumimos estructura simple
    
    int chunkSize = 5;
    if (flat.length >= 25) {
      chunkSize = 5;
    } else {
      // Fallback logic if length is weird, try to distribute evenly
      chunkSize = (flat.length / 5).ceil();
      if (chunkSize == 0) chunkSize = 1;
    }

    for (var i = 0; i < flat.length; i += chunkSize) {
      final end = (i + chunkSize < flat.length) ? i + chunkSize : flat.length;
      columns.add(flat.sublist(i, end));
    }
    
    // Asegurar que siempre haya 5 columnas si es posible, o ajustar según necesidad
    return columns;
  }

  static Future<Uint8List?> captureCartillaImage(
      BuildContext context, Map<String, dynamic> card) async {
    try {
      // Obtener la fecha del evento (del card si está disponible, o del provider)
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      String eventDateStr = card['date'] as String? ?? appProvider.selectedDate;
      
      // Formatear la fecha de YYYY-MM-DD a DD/MM/YYYY para la imagen
      String formattedDate;
      try {
        final dateParts = eventDateStr.split('-');
        if (dateParts.length == 3) {
          formattedDate = '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
        } else {
          formattedDate = eventDateStr;
        }
      } catch (e) {
        formattedDate = eventDateStr;
      }
      
      final imageBytes = await renderCartillaImage(
        numbers: convertNumbersToColumns(card['numbers'] ?? []),
        cardNumber: card['cardNo']?.toString() ?? card['id'],
        date: formattedDate,
        price: "Bs. 20",
      );

      return imageBytes;
    } catch (e) {
      debugPrint('Error capturando cartilla: $e');
      return null;
    }
  }

  static Future<void> saveImageToDevice(Uint8List imageBytes, String fileName) async {
    try {
      await FileSaver.saveFile(imageBytes, fileName);
    } catch (e) {
      debugPrint('Error al guardar imagen: $e');
      rethrow;
    }
  }

  static Future<void> downloadCartilla(
      BuildContext context, Map<String, dynamic> card) async {
    try {
      final imageBytes = await captureCartillaImage(context, card);
      
      if (imageBytes == null || imageBytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al capturar la cartilla'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      await saveImageToDevice(imageBytes, 'cartilla_${card['cardNo'] ?? card['id']}.png');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cartilla ${card['cardNo'] ?? card['id']} descargada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> printCartilla(
      BuildContext context, Map<String, dynamic> card) async {
    try {
      final imageBytes = await captureCartillaImage(context, card);
      
      if (imageBytes == null || imageBytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo preparar la cartilla para imprimir'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      await saveImageToDevice(imageBytes, 'cartilla_${card['cardNo'] ?? card['id']}.png');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen guardada. Por favor imprímela desde tu galería.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
