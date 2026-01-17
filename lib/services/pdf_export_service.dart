import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/firebase_cartilla.dart';

class PdfExportService {
  /// Genera y descarga un PDF con las cartillas asignadas
  /// Compatible con Flutter Web (no usa dart:io)
  Future<void> descargarCartillasPdf(
    List<FirebaseCartilla> cartillas,
    String nombreSorteo,
  ) async {
    // Crear documento PDF
    final pdf = pw.Document();

    // Procesar cartillas en bloques de 2x2 (4 por página)
    final cardsPerPage = 4;
    for (int i = 0; i < cartillas.length; i += cardsPerPage) {
      final pageCards = cartillas.skip(i).take(cardsPerPage).toList();
      pdf.addPage(
        _buildPage(pageCards, nombreSorteo, i ~/ cardsPerPage + 1),
      );
    }

    // Usar printing para abrir el diálogo nativo del navegador
    // Esto funciona perfectamente en Flutter Web
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'cartillas_$nombreSorteo.pdf',
    );
  }

  /// Construye una página del PDF con hasta 4 cartillas en grilla 2x2
  pw.Page _buildPage(
    List<FirebaseCartilla> cards,
    String nombreSorteo,
    int pageNumber,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header de la página
            pw.Text(
              'Cartillas Asignadas - $nombreSorteo',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Página $pageNumber - Total: ${cards.length} cartillas en esta página',
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Grilla 2x2 de cartillas
            pw.Expanded(
              child: pw.GridView(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: cards.map((card) => _buildCartilla(card)).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Dibuja una cartilla individual (vectorial, no imagen)
  pw.Widget _buildCartilla(FirebaseCartilla cartilla) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          // Header de la cartilla
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.orange,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Center(
              child: pw.Text(
                'Cartilla #${cartilla.cardNo ?? cartilla.displayNumber}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          
          // Cabecera "B I N G O"
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: ['B', 'I', 'N', 'G', 'O']
                  .map((letter) => pw.Expanded(
                        child: pw.Center(
                          child: pw.Text(
                            letter,
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Grilla de números 5x5
          pw.Expanded(
            child: _buildNumberGrid(cartilla.numbers),
          ),

          // Footer con fecha
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              cartilla.formattedDate,
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dibuja la grilla de números 5x5
  pw.Widget _buildNumberGrid(List<dynamic> numbers) {
    // Asegurar que tenemos 25 números
    final nums = List<int>.from(numbers.length == 25 ? numbers : List.filled(25, 0));
    
    return pw.GridView(
      crossAxisCount: 5,
      crossAxisSpacing: 0,
      mainAxisSpacing: 0,
      children: List.generate(25, (index) {
        final number = nums[index];
        final isFree = index == 12; // Centro es "FREE"

        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            color: isFree ? PdfColors.orange100 : null,
          ),
          child: pw.Center(
            child: pw.Text(
              isFree ? 'FREE' : number.toString(),
              style: pw.TextStyle(
                fontSize: isFree ? 8 : 12,
                fontWeight: isFree ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
