import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Generador de PDFs para cartillas de Bingo.
/// Diseño igual al widget de descarga de cartillas.
class PdfGenerator {
  // Colores corporativos
  static final PdfColor _orangeColor = PdfColor.fromHex('#FF8C00');
  static final PdfColor _headerBgColor = PdfColor.fromHex('#FF8C00');

  /// Cache para imágenes cargadas
  static pw.MemoryImage? _logoImage;
  static pw.MemoryImage? _freeImage;

  /// Cargar imágenes de assets
  static Future<void> _loadImages() async {
    if (_logoImage == null) {
      try {
        final logoBytes = await rootBundle.load('assets/images/logo.png');
        _logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (e) {
        print('Error cargando logo: $e');
      }
    }
    if (_freeImage == null) {
      try {
        final freeBytes = await rootBundle.load('assets/images/free.png');
        _freeImage = pw.MemoryImage(freeBytes.buffer.asUint8List());
      } catch (e) {
        print('Error cargando free.png: $e');
      }
    }
  }

  /// Genera un PDF con una sola cartilla de bingo (diseño igual al de descarga).
  static Future<Uint8List> generateCartillaPdf({
    required List<List<int>> numbers,
    required dynamic cardNo,
    String? eventDate,
    String? price,
  }) async {
    await _loadImages();
    
    final pdf = pw.Document();
    final dateStr = eventDate ?? DateFormat('dd/MM/yyyy').format(DateTime.now());
    final priceStr = price ?? 'Bs. 20';
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return _buildSingleCard(
            numbers: numbers,
            cardNo: cardNo,
            date: dateStr,
            price: priceStr,
            cellSize: 50,
          );
        },
      ),
    );
    
    return pdf.save();
  }

  /// Genera un PDF con múltiples cartillas (2 por página, diseño igual al de descarga).
  static Future<Uint8List> generateMultipleCartillasPdf({
    required List<Map<String, dynamic>> cards,
    required String vendorName,
    required String eventDate,
    String? price,
  }) async {
    await _loadImages();
    
    final pdf = pw.Document();
    final priceStr = price ?? 'Bs. 20';
    
    // 1 cartilla por página (más grande y visible)
    const int cardsPerPage = 1;
    
    for (int i = 0; i < cards.length; i += cardsPerPage) {
      final pageCards = cards.skip(i).take(cardsPerPage).toList();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header de página
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: pw.BoxDecoration(
                    color: _headerBgColor,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'BINGO IMPERIAL - Cartillas Asignadas',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Vendedor: $vendorName',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                
                // Espaciador superior para centrar
                pw.Spacer(),
                
                // Cartillas
                ...pageCards.map((card) {
                  final cardNumbers = _extractNumbers(card);
                  final cardNo = card['cardNo'] ?? card['id'] ?? '?';
                  
                  return pw.Center(
                    child: _buildSingleCard(
                      numbers: cardNumbers,
                      cardNo: cardNo,
                      date: eventDate,
                      price: priceStr,
                      cellSize: 75,  // Tamaño equilibrado
                    ),
                  );
                }),
                
                // Espaciador inferior para centrar
                pw.Spacer(),
                
                // Footer
                pw.Text(
                  'Página ${(i ~/ cardsPerPage) + 1} de ${(cards.length / cardsPerPage).ceil()} | Total: ${cards.length} cartillas',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                ),
              ],
            );
          },
        ),
      );
    }
    
    return pdf.save();
  }

  /// Extrae los números de una cartilla del mapa
  static List<List<int>> _extractNumbers(Map<String, dynamic> card) {
    if (card['numbers'] != null) {
      return (card['numbers'] as List).map((row) {
        return (row as List).map((n) => n as int).toList();
      }).toList();
    } else if (card['numbersFlat'] != null) {
      final flat = (card['numbersFlat'] as List).cast<int>();
      List<List<int>> numbers = [];
      for (int r = 0; r < 5; r++) {
        numbers.add(flat.sublist(r * 5, (r + 1) * 5));
      }
      return numbers;
    }
    return List.generate(5, (_) => List.generate(5, (_) => 0));
  }

  /// Construye una cartilla individual con el diseño completo
  static pw.Widget _buildSingleCard({
    required List<List<int>> numbers,
    required dynamic cardNo,
    required String date,
    required String price,
    double cellSize = 45,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300, width: 2),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.max,
        children: [
          // Header con número de cartilla, logo y fecha/precio
          _buildCardHeader(cardNo: cardNo, date: date, price: price, cellSize: cellSize),
          pw.SizedBox(height: 15),
          
          // Grid de BINGO
          _buildBingoGrid(numbers: numbers, cellSize: cellSize),
        ],
      ),
    );
  }

  /// Header de la cartilla (número, logo, fecha/precio)
  static pw.Widget _buildCardHeader({
    required dynamic cardNo,
    required String date,
    required String price,
    double cellSize = 45,
  }) {
    // Escalar header proporcionalmente al tamaño de celda
    final scale = cellSize / 45;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Lado izquierdo: número de cartilla (ancho fijo)
        pw.SizedBox(
          width: 120,
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Container(
              width: 70,
              height: 58,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'CARTILLA',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    cardNo.toString(),
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Logo central (con Expanded para ocupar espacio central)
        pw.Expanded(
          child: pw.Center(
            child: pw.Container(
              width: 160 * scale,
              height: 100 * scale,
              child: _logoImage != null
                  ? pw.Image(_logoImage!, fit: pw.BoxFit.contain)
                  : pw.Center(
                      child: pw.Text(
                        'BINGO\nPATUJU',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 18 * scale,
                          fontWeight: pw.FontWeight.bold,
                          color: _orangeColor,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        
        // Lado derecho: fecha y precio (ancho fijo igual al izquierdo)
        pw.SizedBox(
          width: 120,
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('FECHA:', style: pw.TextStyle(fontSize: 11 * scale, fontWeight: pw.FontWeight.bold)),
                pw.Text(date, style: pw.TextStyle(fontSize: 10 * scale)),
                pw.SizedBox(height: 8 * scale),
                pw.Text('PRECIO:', style: pw.TextStyle(fontSize: 11 * scale, fontWeight: pw.FontWeight.bold)),
                pw.Text(price, style: pw.TextStyle(fontSize: 10 * scale)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Grid completo de BINGO con letras y números
  static pw.Widget _buildBingoGrid({
    required List<List<int>> numbers,
    double cellSize = 45,
  }) {
    return pw.Column(
      children: [
        // Fila de letras B-I-N-G-O
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: ['B', 'I', 'N', 'G', 'O'].map((letter) {
            return pw.Container(
              width: cellSize,
              height: cellSize,
              margin: const pw.EdgeInsets.all(1),
              decoration: pw.BoxDecoration(
                color: _headerBgColor,
                border: pw.Border.all(color: PdfColors.black, width: 1.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Center(
                child: pw.Text(
                  letter,
                  style: pw.TextStyle(
                    fontSize: cellSize * 0.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        // Filas de números
        ...List.generate(5, (row) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: List.generate(5, (col) {
              final isFreeSpace = row == 2 && col == 2;
              final number = numbers[row][col];
              
              return pw.Container(
                width: cellSize,
                height: cellSize,
                margin: const pw.EdgeInsets.all(1),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: PdfColors.black, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Center(
                  child: isFreeSpace
                      ? (_freeImage != null
                          ? pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Image(_freeImage!, fit: pw.BoxFit.contain),
                            )
                          : pw.Text(
                              'FREE',
                              style: pw.TextStyle(
                                fontSize: cellSize * 0.25,
                                fontWeight: pw.FontWeight.bold,
                                color: _orangeColor,
                              ),
                            ))
                      : pw.Text(
                          number.toString(),
                          style: pw.TextStyle(
                            fontSize: cellSize * 0.45,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}
