import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'package:excel/excel.dart' as excel_pkg;
import '../utils/cartilla_image_renderer.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../config/backend_config.dart';
import '../widgets/cartilla_widget.dart';
import '../widgets/date_selector_widget.dart';
import '../block_assignment.dart';
import '../providers/app_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/cartillas_service.dart';
import '../services/storage_service.dart';
import '../utils/pdf_generator.dart';

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> {
  final DateFormat _df = DateFormat('yyyy-MM-dd');
  String? _leaderId;
  List<Map<String, dynamic>> _leaders = [];
  List<Map<String, dynamic>> _vendorsAll = [];
  int _refreshTick = 0;

  // Usar la configuración centralizada del backend
  String get _apiBase => BackendConfig.apiBase;

  Future<void> _showVendorDetail(Map<String, dynamic> vendor) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final selectedDate = appProvider.selectedDate;
    final sellerId = vendor['vendorId'] ?? vendor['id'] ?? vendor['vendorId'];
    final salesUri = Uri.parse('$_apiBase/sales?sellerId=$sellerId');
    final cardsUri = Uri.parse('$_apiBase/cards?assignedTo=$sellerId&sold=false&date=$selectedDate');
    final salesResp = await http.get(salesUri);
    final cardsResp = await http.get(cardsUri);
    final sales = salesResp.statusCode < 300 ? List<Map<String, dynamic>>.from(json.decode(salesResp.body)) : <Map<String, dynamic>>[];
    final cards = cardsResp.statusCode < 300 ? List<Map<String, dynamic>>.from(json.decode(cardsResp.body)) : <Map<String, dynamic>>[];

    await showDialog(context: context, builder: (_) {
      return StatefulBuilder(builder: (context, setSt) {
        return AlertDialog(
          title: Text('Detalle - ${vendor['name'] ?? '—'}'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ventas (${sales.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Text('Cartillas asignadas sin vender (${cards.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (cards.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                            tooltip: 'Compartir reporte por WhatsApp',
                            onPressed: () async {
                              // Show loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (c) => const Center(child: CircularProgressIndicator()),
                              );

                              try {
                                final result = await CartillaService.shareAssignedCards(
                                  assignmentId: sellerId.toString(),
                                  vendorName: vendor['name'] ?? 'Vendedor',
                                  date: selectedDate,
                                );

                                Navigator.pop(context); // Hide loading

                                if (result['url'] != null) {
                                  final url = Uri.parse(result['url']);
                                  final message = Uri.encodeComponent(
                                      'Hola ${vendor['name']}, aquí tienes tu reporte de cartillas asignadas para la fecha $selectedDate: ${result['url']}');
                                  final whatsappUrl = Uri.parse('https://wa.me/?text=$message');

                                  if (await canLaunchUrl(whatsappUrl)) {
                                    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                                  } else {
                                    throw 'No se pudo abrir WhatsApp';
                                  }
                                }
                              } catch (e) {
                                Navigator.pop(context); // Hide loading if error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 240,
                  child: Row(children: [
                    // Ventas
                    Expanded(
                      child: ListView.builder(
                        itemCount: sales.length,
                        itemBuilder: (c, i) {
                          final s = sales[i];
                          return ListTile(
                            dense: true,
                            title: Text('Card ${s['cardId']} - Bs ${s['amount']}'),
                            subtitle: Text(DateTime.fromMillisecondsSinceEpoch((s['createdAt'] ?? 0) as int).toString()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cartillas asignadas
                    Expanded(
                      child: ListView.builder(
                        itemCount: cards.length,
                        itemBuilder: (c, i) {
                          final card = cards[i];
                          return ListTile(
                            dense: true,
                            title: Text('Card ${card['id']}'),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            ElevatedButton.icon(
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Registrar venta'),
              onPressed: () async {
                await _registerSaleDialog(sellerId as String);
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        );
      });
    });
  }

  Future<void> _registerSaleDialog(String sellerId) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final selectedDate = appProvider.selectedDate;
    
    // Cargar cartillas asignadas sin vender
    List<Map<String, dynamic>> cards = [];
    String? lastDocId;
    bool isLoading = true;
    
    // Mostrar diálogo de carga inicial
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      Future<void> loadCardsPage() async {
        final queryParams = <String>['assignedTo=$sellerId', 'sold=false', 'date=$selectedDate', 'limit=2000'];
        if (lastDocId != null) {
          queryParams.add('startAfter=$lastDocId');
        }
        
        final r = await http.get(Uri.parse('$_apiBase/cards?${queryParams.join('&')}'));
        if (r.statusCode < 300) {
          final responseData = json.decode(r.body) as Map<String, dynamic>;
          final pageCards = List<Map<String, dynamic>>.from(responseData['cards'] as List? ?? []);
          final pagination = responseData['pagination'] as Map<String, dynamic>?;
          
          cards.addAll(pageCards);
          lastDocId = pagination?['lastDocId'] as String?;
          
          if (pagination?['hasMore'] == true && lastDocId != null) {
            await loadCardsPage();
          }
        }
      }
      
      await loadCardsPage();
    } catch (e) {
      // debugPrint('Error loading cards: $e');
    } finally {
      Navigator.pop(context); // Cerrar loading
    }

    // Ordenar cartillas por número
    cards.sort((a, b) {
      final aNum = int.tryParse(a['cardNo']?.toString() ?? '0') ?? 0;
      final bNum = int.tryParse(b['cardNo']?.toString() ?? '0') ?? 0;
      return aNum.compareTo(bNum);
    });

    final amountCtrl = TextEditingController(text: '20');
    final Set<String> selectedIds = {};

    await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final double price = double.tryParse(amountCtrl.text) ?? 20.0;
            final double totalAmount = selectedIds.length * price;
            final bool allSelected = cards.isNotEmpty && selectedIds.length == cards.length;

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.point_of_sale, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Registrar Venta'),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cards.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'No hay cartillas asignadas disponibles para vender.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else ...[
                      // Header con Select All y Precio
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: Text(
                                'Seleccionar Todo (${cards.length})',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              value: allSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedIds.addAll(cards.map((c) => c['id'] as String));
                                  } else {
                                    selectedIds.clear();
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          SizedBox(width: 16),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: amountCtrl,
                              decoration: InputDecoration(
                                labelText: 'Precio (Bs)',
                                border: OutlineInputBorder(),
                                isDense: true,
                                prefixIcon: Icon(Icons.attach_money, size: 16),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      // Lista de cartillas
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: cards.length,
                            itemBuilder: (context, index) {
                              final card = cards[index];
                              final cardId = card['id'] as String;
                              final isSelected = selectedIds.contains(cardId);
                              
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedIds.add(cardId);
                                    } else {
                                      selectedIds.remove(cardId);
                                    }
                                  });
                                },
                                title: Text(
                                  'Cartilla ${card['cardNo'] ?? card['id']}',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.blue.shade800 : null,
                                  ),
                                ),
                                subtitle: Text('ID: ${card['id']}'),
                                secondary: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      card['cardNo']?.toString() ?? '#',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.blue.shade800 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Resumen
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resumen de Venta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                Text(
                                  '${selectedIds.length} cartillas seleccionadas',
                                  style: TextStyle(color: Colors.blue.shade600),
                                ),
                              ],
                            ),
                            Text(
                              'Total: Bs ${totalAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                if (cards.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: selectedIds.isEmpty 
                      ? null 
                      : () => Navigator.pop(context, true),
                    icon: Icon(Icons.check),
                    label: Text('Vender (${selectedIds.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
              ],
            );
          },
        );
      },
    ).then((confirm) async {
      if (confirm == true && selectedIds.isNotEmpty) {
        // Procesar ventas
        int successCount = 0;
        int errorCount = 0;
        final total = selectedIds.length;
        
        // Mostrar diálogo de progreso
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('Procesando ventas...'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(
                        value: (successCount + errorCount) / total,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      SizedBox(height: 16),
                      Text('Procesando: ${successCount + errorCount} / $total'),
                      if (errorCount > 0)
                        Text('Errores: $errorCount', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                );
              },
            );
          },
        );

        final double price = double.tryParse(amountCtrl.text) ?? 20.0;
        
        for (final cardId in selectedIds) {
          try {
            final resp = await http.post(
              Uri.parse('$_apiBase/sales'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'cardId': cardId,
                'sellerId': sellerId,
                'amount': price,
                'date': selectedDate,
              }),
            );
            
            if (resp.statusCode < 300) {
              successCount++;
            } else {
              errorCount++;
            }
          } catch (e) {
            errorCount++;
          }
          
          // Actualizar UI del diálogo de progreso (hacky pero funciona si el contexto es válido)
          // En una app real usaríamos un ValueNotifier o Stream
        }
        
        Navigator.pop(context); // Cerrar diálogo de progreso
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta finalizada: $successCount exitosas, $errorCount errores'),
            backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
          ),
        );
        
        setState(() { _refreshTick++; });
      }
    });
  }

  // Captura la cartilla y retorna los bytes de la imagen
  Future<Uint8List?> _captureCartillaImage(Map<String, dynamic> card) async {
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
        numbers: _convertNumbersToIntList(card['numbers'] ?? []),
        cardNumber: card['cardNo']?.toString() ?? card['id'],
        date: formattedDate,
        price: "Bs. 20",
      );

      return imageBytes;
    } catch (e) {
      // debugPrint('Error capturando cartilla: $e');
      return null;
    }
  }

  // Método para descargar cartilla en PNG con resolución optimizada
  Future<void> _downloadCartilla(Map<String, dynamic> card) async {
    try {
      final imageBytes = await _captureCartillaImage(card);
      
      if (imageBytes == null || imageBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al capturar la cartilla'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      await _saveImageToDevice(imageBytes, 'cartilla_${card['cardNo'] ?? card['id']}.png');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cartilla ${card['cardNo'] ?? card['id']} descargada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Abrir ventana de impresión web para evitar recortes al imprimir
  Future<void> _printCartilla(Map<String, dynamic> card) async {
    try {
      final imageBytes = await _captureCartillaImage(card);
      
      if (imageBytes == null || imageBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo preparar la cartilla para imprimir'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final encoded = base64Encode(imageBytes);
      final htmlContent = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Imprimir cartilla ${card['cardNo'] ?? card['id']}</title>
    <style>
      @page {
        size: legal portrait;
        margin: 10mm;
      }
      html, body {
        height: 100%;
        margin: 0;
        background: #ffffff;
        display: flex;
        align-items: center;
        justify-content: center;
      }
      img {
        max-width: 90%;
        max-height: 90%;
        object-fit: contain;
      }
    </style>
  </head>
  <body>
    <img src="data:image/png;base64,$encoded" onload="setTimeout(function(){ window.print(); setTimeout(function(){ window.close(); }, 400); }, 100);" />
  </body>
</html>
''';
      
      final dataUrl = Uri.dataFromString(
        htmlContent,
        mimeType: 'text/html',
        encoding: utf8,
      ).toString();
      
      final printWindow = html.window.open(dataUrl, '_blank');
      if (printWindow == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El navegador bloqueó la ventana de impresión'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al preparar impresión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método helper para convertir números de cartilla a List<List<int>>
  List<List<int>> _convertNumbersToIntList(dynamic numbers) {
    try {
      if (numbers == null) return [];
      
      // Si ya es List<List<int>>, retornarlo directamente
      if (numbers is List<List<int>>) return numbers;
      
      // Si es List<dynamic>, convertir cada elemento
      if (numbers is List) {
        return numbers.map((row) {
          if (row is List<int>) return row;
          if (row is List) {
            return row.map((number) {
              if (number is int) return number;
              if (number is String) return int.tryParse(number) ?? 0;
              if (number is double) return number.toInt();
              return 0;
            }).toList();
          }
          return <int>[];
        }).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error convirtiendo números: $e');
      return [];
    }
  }

  // Método para guardar imagen en el dispositivo
  Future<void> _saveImageToDevice(Uint8List imageBytes, String fileName) async {
    try {
      // Crear un blob y descargar usando dart:html
      final blob = html.Blob([imageBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Crear elemento de descarga
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      
      // Agregar al DOM, hacer clic y limpiar
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      
      // Liberar memoria
      html.Url.revokeObjectUrl(url);
      
      // Pequeña pausa para asegurar que la descarga se inicie
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      // debugPrint('Error al guardar imagen: $e');
      rethrow;
    }
  }

  Future<void> _sellAllAssigned(String sellerId) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final selectedDate = appProvider.selectedDate;
    
    // Cargar cartillas con paginación
    List<Map<String, dynamic>> cards = [];
    String? lastDocId;
    
    // Mostrar loading mientras carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Future<void> loadCardsPage() async {
        final queryParams = <String>['assignedTo=$sellerId', 'sold=false', 'date=$selectedDate', 'limit=2000'];
        if (lastDocId != null) {
          queryParams.add('startAfter=$lastDocId');
        }
        
        final r = await http.get(Uri.parse('$_apiBase/cards?${queryParams.join('&')}'));
        if (r.statusCode >= 300) {
          throw Exception('Error al cargar cartillas: ${r.body}');
        }
        
        final responseData = json.decode(r.body) as Map<String, dynamic>;
        final pageCards = List<Map<String, dynamic>>.from(responseData['cards'] as List? ?? []);
        final pagination = responseData['pagination'] as Map<String, dynamic>?;
        
        cards.addAll(pageCards);
        lastDocId = pagination?['lastDocId'] as String?;
        
        // Si hay más páginas, cargar la siguiente
        if (pagination?['hasMore'] == true && lastDocId != null) {
          await loadCardsPage();
        }
      }
      
      await loadCardsPage();
    } catch (e) {
      // debugPrint('Error loading cards for sell all: $e');
    } finally {
      Navigator.pop(context); // Cerrar loading
    }

    if (cards.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay cartillas asignadas sin vender.')));
      return;
    }

    final count = cards.length;
    final priceCtrl = TextEditingController(text: '20');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final double price = double.tryParse(priceCtrl.text) ?? 0;
            final double total = price * count;
            
            return AlertDialog(
              title: const Text('Confirmar venta en lote'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Se venderán $count cartillas.'),
                  SizedBox(height: 16),
                  TextField(
                    controller: priceCtrl,
                    decoration: InputDecoration(
                      labelText: 'Precio por cartilla (Bs)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total a cobrar:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${total.toStringAsFixed(0)} Bs',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Vender todo'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    final double finalPrice = double.tryParse(priceCtrl.text) ?? 20.0;
    
    // Dialogo de progreso (Indeterminado porque es una sola petición)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          title: Text('Procesando venta masiva...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Por favor espere, esto puede tomar unos segundos...'),
            ],
          ),
        );
      },
    );

    try {
      final salesData = cards.map((c) => {
        'cardId': c['id'],
        'sellerId': sellerId,
        'amount': finalPrice,
        'date': selectedDate,
      }).toList();

      final resp = await http.post(
        Uri.parse('$_apiBase/sales/bulk'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sales': salesData}),
      );

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (resp.statusCode < 300) {
        final body = json.decode(resp.body);
        final successCount = body['success'] ?? 0;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Venta masiva exitosa: $successCount cartillas vendidas'),
              backgroundColor: Colors.green,
            )
          );
        }
        setState(() { _refreshTick++; });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error en venta masiva: ${resp.body}'),
              backgroundColor: Colors.red,
            )
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  // Método para ELIMINAR TODOS LOS DATOS de sales y balances
  Future<void> _clearCommissions() async {
    // Primero mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.dangerous, color: Colors.red),
            SizedBox(width: 8),
            Text('ELIMINAR TODOS LOS DATOS'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚨 ADVERTENCIA CRÍTICA: Esta operación es IRREVERSIBLE',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Se ELIMINARÁN COMPLETAMENTE:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 8),
            Text('• TODA la colección "sales" - Todas las ventas se perderán'),
            Text('• TODA la colección "balances" - Todos los balances se perderán'),
            SizedBox(height: 16),
            Text(
              '⚠️ NO HAY MANERA DE RECUPERAR ESTOS DATOS',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '¿Estás ABSOLUTAMENTE seguro de que quieres proceder?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('ELIMINAR DATOS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar diálogo de confirmación final
    final finalConfirmController = TextEditingController();
    final finalConfirm = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.dangerous, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmación Final'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para confirmar, escribe exactamente:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                'ELIMINAR_DATOS_2024',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: finalConfirmController,
              decoration: InputDecoration(
                labelText: 'Confirmar texto',
                border: OutlineInputBorder(),
                hintText: 'Escribe el texto de confirmación',
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancelar'),
          ),
                      ElevatedButton(
              onPressed: () {
                // Obtener el texto del TextField usando un TextEditingController
                Navigator.pop(context, finalConfirmController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('CONFIRMAR'),
            ),
        ],
      ),
    );

    if (finalConfirm != 'ELIMINAR_DATOS_2024') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Confirmación incorrecta. Operación cancelada.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar indicador de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('ELIMINANDO DATOS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Eliminando TODOS los datos... Por favor espera.'),
            SizedBox(height: 8),
            Text(
              '⚠️ Esta operación es IRREVERSIBLE',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );

    try {
             // Llamar al endpoint de eliminación de datos
       final response = await http.post(
         Uri.parse('$_apiBase/reports/clear-commissions'),
         headers: {'Content-Type': 'application/json'},
         body: json.encode({
           'confirm': 'ELIMINAR_DATOS_2024',
           'dryRun': false,
         }),
       );

      // Cerrar diálogo de progreso
      Navigator.pop(context);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final summary = result['summary'];
        
                 // Mostrar resumen de la operación
         await showDialog(
           context: context,
           builder: (context) => AlertDialog(
             title: Row(
               children: [
                 Icon(Icons.check_circle, color: Colors.green),
                 SizedBox(width: 8),
                 Text('DATOS ELIMINADOS'),
               ],
             ),
             content: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   '✅ ELIMINACIÓN COMPLETADA EXITOSAMENTE',
                   style: TextStyle(
                     color: Colors.green,
                     fontWeight: FontWeight.bold,
                     fontSize: 16,
                   ),
                 ),
                 SizedBox(height: 16),
                 Container(
                   padding: EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Colors.green.shade50,
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: Colors.green.shade200),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Resumen de Eliminación:',
                         style: TextStyle(fontWeight: FontWeight.bold),
                       ),
                       SizedBox(height: 8),
                       Text('• Ventas eliminadas: ${summary['salesDeleted']}'),
                       Text('• Balances eliminados: ${summary['balancesDeleted']}'),
                       Text('• Total registros eliminados: ${summary['totalRecordsDeleted']}'),
                       SizedBox(height: 8),
                       Text(
                         '⚠️ TODOS LOS DATOS HAN SIDO ELIMINADOS PERMANENTEMENTE',
                         style: TextStyle(
                           color: Colors.red,
                           fontWeight: FontWeight.bold,
                           fontSize: 12,
                         ),
                       ),
                       SizedBox(height: 8),
                       Text(
                         'Timestamp: ${DateTime.fromMillisecondsSinceEpoch(summary['timestamp'] ?? 0)}',
                         style: TextStyle(
                           fontSize: 12,
                           color: Colors.grey.shade600,
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
             actions: [
               ElevatedButton(
                 onPressed: () => Navigator.pop(context),
                 child: Text('Aceptar'),
               ),
             ],
           ),
         );

        // Refrescar la interfaz
        setState(() { _refreshTick++; });
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error['error'] ?? response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de progreso
      Navigator.pop(context);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _load({bool withLeaders = false, int? refreshKey}) async {
    // Usar selectedDate del AppProvider para filtrar por fecha del evento
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final selectedDate = appProvider.selectedDate;
    
    final qp = <String>['date=$selectedDate'];
    if (_leaderId != null && _leaderId!.isNotEmpty) qp.add('leaderId=$_leaderId');
    final qs = '?${qp.join('&')}';

    if (withLeaders) {
      final leadersResp = await http.get(Uri.parse('$_apiBase/vendors'));
      if (leadersResp.statusCode < 300) {
        final raw = List<Map<String, dynamic>>.from(json.decode(leadersResp.body));
        _leaders = raw.where((v) => v['role'] == 'LEADER').toList();
        _vendorsAll = raw;
      }
    }

    final uri = Uri.parse('$_apiBase/reports/vendors-summary$qs');
    final resp = await http.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      
      // Obtener conteo de cartillas asignadas para cada vendedor usando endpoint optimizado
      final vendors = List<Map<String, dynamic>>.from(data['vendors'] as List);
      
      // Extraer todos los vendorIds
      final vendorIds = vendors
          .map((v) => v['vendorId'] ?? v['id'])
          .where((id) => id != null)
          .cast<String>()
          .toList();

      // Obtener conteos en batch usando el nuevo endpoint optimizado
      if (vendorIds.isNotEmpty) {
        try {
          final countsResp = await http.post(
            Uri.parse('$_apiBase/cards/counts'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'vendorIds': vendorIds,
              'date': selectedDate,
            }),
          );

          if (countsResp.statusCode < 300) {
            final countsData = json.decode(countsResp.body) as Map<String, dynamic>;
            final counts = countsData['counts'] as Map<String, dynamic>?;

            // Asignar conteos a cada vendor
            for (final vendor in vendors) {
              final vendorId = vendor['vendorId'] ?? vendor['id'];
              if (vendorId != null && counts != null && counts.containsKey(vendorId)) {
                final vendorCounts = counts[vendorId] as Map<String, dynamic>;
                vendor['assignedCount'] = vendorCounts['assigned'] ?? 0;
                // El soldCount ya viene del reports/vendors-summary, pero lo actualizamos si es necesario
                if (vendorCounts['sold'] != null) {
                  vendor['soldCount'] = vendorCounts['sold'];
                }
              } else {
                vendor['assignedCount'] = 0;
              }
            }
          } else {
            // Fallback: inicializar en 0 si falla
            for (final vendor in vendors) {
              vendor['assignedCount'] = 0;
            }
          }
        } catch (e) {
          // Fallback: inicializar en 0 si hay error
          for (final vendor in vendors) {
            vendor['assignedCount'] = 0;
          }
        }
      }
      
      // Obtener el total de cartillas del sistema usando el endpoint optimizado
      try {
        final totalCardsResp = await http.get(Uri.parse('$_apiBase/cards/total?date=$selectedDate'));
        if (totalCardsResp.statusCode < 300) {
          final totalData = json.decode(totalCardsResp.body) as Map<String, dynamic>;
          data['totalCards'] = totalData['totalCards'] ?? 0;
        } else {
          data['totalCards'] = 0;
        }
      } catch (e) {
        data['totalCards'] = 0;
      }
      
      return data;
    }
    throw Exception('Error ${resp.statusCode}: ${resp.body}');
  }



  Future<void> _createVendor({required bool isLeader}) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String? leaderId = _leaderId; // Si hay un filtro de líder seleccionado, usarlo por defecto

    // Si el usuario logueado es un LÍDER (esto dependería de cómo manejes la sesión, 
    // pero por ahora asumimos que si está en esta pantalla es Admin o tiene permisos).
    // Si quisieras restringir que un Líder solo cree Vendedores bajo su mando, 
    // deberías verificar el rol del usuario actual aquí.
    
    await showDialog(context: context, builder: (_) {
      return AlertDialog(
        title: Text(isLeader ? 'Nuevo Líder' : 'Nuevo Vendedor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Teléfono')),
            if (!isLeader)
              DropdownButtonFormField<String>(
                value: leaderId,
                items: _leaders
                    .map((l) => DropdownMenuItem<String>(
                          value: (l['id'] as String),
                          child: Text(l['name'] as String),
                        ))
                    .toList(),
                onChanged: (v) => leaderId = v,
                decoration: const InputDecoration(labelText: 'Líder Asignado'),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Crear')),
        ],
      );
    });

    if (nameController.text.isEmpty) return;

    // Validación: Si es vendedor, DEBE tener un líder
    if (!isLeader && leaderId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe asignar un líder al vendedor')));
      return;
    }

    final role = isLeader ? 'LEADER' : 'SELLER';
    
    final body = {
      'name': nameController.text,
      'phone': phoneController.text,
      'role': role,
      if (!isLeader) 'leaderId': leaderId,
    };
    
    final resp = await http.post(
      Uri.parse('$_apiBase/vendors'), 
      headers: {'Content-Type': 'application/json'}, 
      body: json.encode(body),
    );
    
    if (!mounted) return;
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creado correctamente')));
      setState(() { _refreshTick++; });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${resp.body}')));
    }
  }

  Future<void> _assignCard() async {
    String? vendorId;
    if (_vendorsAll.isEmpty) {
      await _load(withLeaders: true);
    }
    
    // Controllers para el nuevo diálogo
    final cardNumbersCtrl = TextEditingController();
    final startRangeCtrl = TextEditingController();
    final endRangeCtrl = TextEditingController();
    final stepCtrl = TextEditingController(text: '10');
    
    // Controladores para asignación por bloques
    final blockSizeCtrl = TextEditingController(text: '5');
    final skipBlocksCtrl = TextEditingController(text: '0');
    final startCardCtrl = TextEditingController(text: '1');
    final totalCardsCtrl = TextEditingController(text: '1000');
    
    // Estado para el tipo de asignación
    String assignmentType = 'specific'; // 'specific', 'range', o 'blocks'
    
    await showDialog(context: context, builder: (_) {
      return StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Asignar Cartillas'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selector de tipo de asignación
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Números específicos'),
                        value: 'specific',
                        groupValue: assignmentType,
                        onChanged: (value) => setDialogState(() => assignmentType = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Rango de números'),
                        value: 'range',
                        groupValue: assignmentType,
                        onChanged: (value) => setDialogState(() => assignmentType = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Por bloques'),
                        value: 'blocks',
                        groupValue: assignmentType,
                        onChanged: (value) => setDialogState(() => assignmentType = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Campo para vendedor/líder (solo para asignación específica y por rango)
                if (assignmentType != 'blocks') ...[
                  DropdownButtonFormField<String>(
                    value: vendorId,
                    items: _buildVendorDropdownItems(),
                    onChanged: (v) => setDialogState(() => vendorId = v),
                    decoration: const InputDecoration(
                      labelText: 'Vendedor/Líder',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Campos según el tipo de asignación
                if (assignmentType == 'specific') ...[
                  TextField(
                    controller: cardNumbersCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Números de cartilla (separados por comas)',
                      hintText: 'Ej: 1, 5, 10, 15',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                ] else if (assignmentType == 'range') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startRangeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Desde',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.start),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: endRangeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Hasta',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.stop),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stepCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Paso (por defecto 10)',
                      hintText: '10',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.trending_up),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ] else if (assignmentType == 'blocks') ...[
                  // Botón para abrir el modal de asignación por bloques
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.grid_on, color: Colors.blue[700], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Asignación por Bloques',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Haz clic en "Asignar Cartillas" para configurar la asignación por bloques con el nuevo sistema.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Los campos de configuración se manejan en el nuevo modal
                ],
                
                const SizedBox(height: 16),
                
                // Información del rango
                if (assignmentType == 'range' && startRangeCtrl.text.isNotEmpty && endRangeCtrl.text.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _calculateRangeInfo(startRangeCtrl.text, endRangeCtrl.text, stepCtrl.text),
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancelar')
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), 
              child: const Text('Asignar Cartillas')
            ),
          ],
        );
      });
    });
    
    // Para asignación por bloques, no necesitamos vendedor específico
    if (assignmentType == 'blocks') {
      await _showBlockAssignmentModal(context);
      return;
    }
    
    // Para otros tipos de asignación, sí necesitamos vendedor específico
    if (vendorId == null) return;
    
    // Procesar la asignación según el tipo
    if (assignmentType == 'specific') {
      if (cardNumbersCtrl.text.isEmpty) return;
      
      // Parsear números específicos
      final numbers = cardNumbersCtrl.text
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .where((n) => n != null)
          .cast<int>()
          .toList();
      
      if (numbers.isEmpty) return;
      
      await _assignMultipleCards(vendorId!, cardNumbers: numbers);
      
    } else if (assignmentType == 'range') {
      if (startRangeCtrl.text.isEmpty || endRangeCtrl.text.isEmpty) return;
      
      final start = int.tryParse(startRangeCtrl.text);
      final end = int.tryParse(endRangeCtrl.text);
      final step = int.tryParse(stepCtrl.text) ?? 10;
      
      if (start == null || end == null) return;
      
      await _assignMultipleCards(vendorId!, startRange: start, endRange: end, step: step);
    }
  }
  
  String _calculateRangeInfo(String start, String end, String step) {
    final startNum = int.tryParse(start);
    final endNum = int.tryParse(end);
    final stepNum = int.tryParse(step) ?? 10;
    
    if (startNum == null || endNum == null) return '';
    
    if (startNum > endNum) return 'El rango de inicio debe ser menor al rango final';
    
    final count = ((endNum - startNum) / stepNum).floor() + 1;
    final numbers = <int>[];
    
    for (int i = startNum; i <= endNum; i += stepNum) {
      numbers.add(i);
    }
    
    if (numbers.length <= 10) {
      return 'Se asignarán $count cartillas: ${numbers.join(', ')}';
    } else {
      final firstFew = numbers.take(5).join(', ');
      final lastFew = numbers.skip(numbers.length - 3).join(', ');
      return 'Se asignarán $count cartillas: $firstFew, ..., $lastFew';
    }
  }
  
  /// Mostrar modal de asignación por bloques
  Future<void> _showBlockAssignmentModal(BuildContext context, [String? vendorId]) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final selectedDate = appProvider.selectedDate;

    final vendor = vendorId != null 
        ? _vendorsAll.firstWhere(
            (v) => v['id'] == vendorId,
            orElse: () => {'name': 'Vendedor'},
          )
        : {'name': 'Todos los vendedores'};

    // URGENT FIX: DESBLOQUEO TOTAL
    // Pasamos TODOS los vendedores (Líderes y Vendedores) para que el Admin pueda asignar a quien quiera.
    // El backend ya ha sido actualizado para permitir esto.
    
    await showDialog(
      context: context,
      builder: (context) => BlockAssignmentModal(
        apiBase: _apiBase,
        vendorId: vendorId ?? '',
        vendorName: vendor['name'] ?? 'Vendedor',
        date: selectedDate,
        allVendors: _vendorsAll, // Pasar la lista completa SIN FILTROS
        onSuccess: () {
          setState(() { _refreshTick++; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cartillas asignadas exitosamente por bloques'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
  
  Future<void> _assignMultipleCards(String vendorId, {
    List<int>? cardNumbers,
    int? startRange,
    int? endRange,
    int? step,
  }) async {
    try {
      // Obtener la fecha seleccionada del AppProvider
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final selectedDate = appProvider.selectedDate;
      
      final body = <String, dynamic>{
        'vendorId': vendorId,
        'date': selectedDate, // REQUERIDO por el backend
      };
      
      if (cardNumbers != null) {
        body['cardNumbers'] = cardNumbers;
      } else if (startRange != null && endRange != null) {
        body['startRange'] = startRange;
        body['endRange'] = endRange;
        if (step != null) body['step'] = step;
      }
      
      final resp = await http.post(
        Uri.parse('$_apiBase/cards/bulk-assign'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      
      if (!mounted) return;
      
      if (resp.statusCode < 300) {
        final result = json.decode(resp.body);
        final assignedCount = result['assignedCount'] ?? 0;
        final notFoundCount = result['notFoundCards']?.length ?? 0;
        final summary = result['summary'];
        
        // Mostrar resumen detallado en un diálogo
        await _showAssignmentSummary(result);
        
        setState(() {});
      } else {
        final error = json.decode(resp.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error['error'] ?? resp.body}'),
            backgroundColor: Colors.red,
          )
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        )
      );
    }
  }
  
  Future<void> _showAssignmentSummary(Map<String, dynamic> result) async {
    final assignedCount = result['assignedCount'] ?? 0;
    final notFoundCount = result['notFoundCards']?.length ?? 0;
    final totalRequested = result['totalRequested'] ?? 0;
    final summary = result['summary'];
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              assignedCount > 0 ? Icons.check_circle : Icons.error,
              color: assignedCount > 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text('Resumen de Asignación'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen general
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: assignedCount > 0 ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: assignedCount > 0 ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      assignedCount > 0 ? Icons.check_circle : Icons.error,
                      color: assignedCount > 0 ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solicitadas: $totalRequested cartillas',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Asignadas: $assignedCount cartillas',
                            style: TextStyle(
                              color: assignedCount > 0 ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (notFoundCount > 0)
                            Text(
                              'No encontradas: $notFoundCount cartillas',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Detalles de cartillas asignadas
              if (assignedCount > 0) ...[
                const Text(
                  '✅ Cartillas Asignadas:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (summary?['assigned'] as List<dynamic>? ?? []).map((cardNo) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$cardNo',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Cartilla',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Detalles de cartillas no encontradas
              if (notFoundCount > 0) ...[
                const Text(
                  '❌ Cartillas No Encontradas:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (summary?['notFound'] as List<dynamic>? ?? []).map((cardNo) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Text(
                          'Cartilla $cardNo',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Información adicional
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Las cartillas asignadas ahora están disponibles para venta en el inventario del vendedor/líder seleccionado.',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  // Método para mostrar diálogo de cartillas asignadas
  Future<void> _showAssignedCardsDialog(String vendorId) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final selectedDate = appProvider.selectedDate;
    // Buscar datos del vendedor
    final vendor = _vendorsAll.firstWhere(
      (v) => (v['vendorId'] ?? v['id']) == vendorId,
      orElse: () => {'name': 'Vendedor', 'phone': ''},
    );
    
    final vendorName = vendor['name'] ?? 'Vendedor';
    final vendorPhone = vendor['phone'] ?? '';

    // Mostrar diálogo inmediatamente con widget optimizado
    await showDialog(
      context: context,
      builder: (context) => _AssignedCardsDialog(
        vendorId: vendorId,
        vendorName: vendorName,
        vendorPhone: vendorPhone,
        apiBase: _apiBase,
        eventDate: selectedDate,
        onDownloadAll: (cards) => _downloadAllAssignedCards(cards, vendorId),
        onDeleteAll: (cards) => _deleteAllAssignedCards(cards, vendorId),
        onOpenCartilla: (card) => _openCartilla(card),
        onDeleteCard: (card) => _deleteIndividualCard(card, vendorId),
      ),
    );
  }


  // Método para abrir una cartilla específica
  Future<void> _openCartilla(Map<String, dynamic> card) async {
    try {
      // Cerrar el diálogo de cartillas asignadas
      Navigator.pop(context);
      
      // Obtener la fecha del evento (del card si está disponible, o del provider)
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      String eventDateStr = card['date'] as String? ?? appProvider.selectedDate;
      
      // Formatear la fecha de YYYY-MM-DD a DD/MM/YYYY
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
      
      // Mostrar la cartilla en un diálogo
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.grid_on, color: Colors.blue),
              SizedBox(width: 8),
              Text('Cartilla ${card['cardNo'] ?? card['id']}'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // Información de la cartilla
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Número: ${card['cardNo'] ?? card['id']}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('ID: ${card['id']}'),
                            Text('Asignada a: ${card['assignedTo'] ?? 'Sin asignar'}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // La cartilla en sí
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: CartillaWidget(
                        numbers: _convertNumbersToIntList(card['numbers'] ?? []),
                        cardNumber: card['cardNo']?.toString() ?? card['id'],
                        date: formattedDate,
                        price: "Bs. 20",
                        compact: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () => _downloadCartilla(card),
              icon: Icon(Icons.download),
              label: Text('Descargar PNG'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir cartilla: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showInventoryDialog() async {
    List<Map<String, dynamic>> cards = [];
    bool isLoadingCards = false;
    
    // Crear mapa de IDs a nombres para búsqueda rápida
    Map<String, String> vendorIdToName = {};
    
    // Cargar vendedores y construir mapa
    await _load(withLeaders: true);
    for (var vendor in _vendorsAll) {
      final id = vendor['id'] as String?;
      final name = vendor['name'] as String?;
      if (id != null && name != null) {
        vendorIdToName[id] = name;
      }
    }
    
    // Función helper para obtener el nombre del vendedor
    String getVendorName(String? vendorId) {
      if (vendorId == null) return 'Sin asignar';
      return vendorIdToName[vendorId] ?? vendorId;
    }
    
    // Cargar cartillas inicialmente con paginación
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final eventDate = appProvider.selectedDate;
    String? lastDocId;
    
    Future<void> loadCardsPage() async {
      final queryParams = <String>['sold=false', 'date=$eventDate', 'limit=2000'];
      if (lastDocId != null) {
        queryParams.add('startAfter=$lastDocId');
      }
      
      final initialResp = await http.get(Uri.parse('$_apiBase/cards?${queryParams.join('&')}'));
      if (initialResp.statusCode < 300) {
        final responseData = json.decode(initialResp.body) as Map<String, dynamic>;
        final pageCards = List<Map<String, dynamic>>.from(responseData['cards'] as List? ?? []);
        final pagination = responseData['pagination'] as Map<String, dynamic>?;
        
        cards.addAll(pageCards);
        lastDocId = pagination?['lastDocId'] as String?;
        
        // Si hay más páginas, cargar la siguiente
        if (pagination?['hasMore'] == true && lastDocId != null) {
          await loadCardsPage();
        }
      }
    }
    
    await loadCardsPage();
    
    String? vendorId;
    int displayedCount = 10; // Mostrar inicialmente 10 cartillas
    String filterType = 'Todas'; // 'Todas', 'Asignadas', 'No asignadas'
    final searchController = TextEditingController();
    
    await showDialog(context: context, builder: (_) {
      return StatefulBuilder(builder: (context, setSt) {
        Future<void> loadCards() async {
          setSt(() => isLoadingCards = true);
          cards.clear();
          String? pageLastDocId;
          
          Future<void> loadPage() async {
            final queryParams = <String>['sold=false', 'date=$eventDate', 'limit=2000'];
            if (pageLastDocId != null) {
              queryParams.add('startAfter=$pageLastDocId');
            }
            
            final r = await http.get(Uri.parse('$_apiBase/cards?${queryParams.join('&')}'));
            if (r.statusCode < 300) {
              final responseData = json.decode(r.body) as Map<String, dynamic>;
              final pageCards = List<Map<String, dynamic>>.from(responseData['cards'] as List? ?? []);
              final pagination = responseData['pagination'] as Map<String, dynamic>?;
              
              cards.addAll(pageCards);
              pageLastDocId = pagination?['lastDocId'] as String?;
              
              // Si hay más páginas, cargar la siguiente
              if (pagination?['hasMore'] == true && pageLastDocId != null) {
                await loadPage();
              }
            }
          }
          
          await loadPage();
          
          setSt(() {
            isLoadingCards = false;
            displayedCount = 10; // Resetear a 10 al recargar
          });
        }
        
        // Aplicar búsqueda y filtro
        final searchQuery = searchController.text;
        
        var filteredCards = filterType == 'Asignadas' 
            ? cards.where((c) => c['assignedTo'] != null).toList()
            : filterType == 'No asignadas'
                ? cards.where((c) => c['assignedTo'] == null).toList()
                : cards;
        
        // Aplicar búsqueda por número
        if (searchQuery.isNotEmpty) {
          filteredCards = filteredCards.where((c) {
            final cardNo = c['cardNo'];
            final cardNoStr = cardNo?.toString() ?? '';
            final cardId = (c['id'] ?? '').toString();
            
            // Buscar coincidencia exacta en el número
            if (cardNoStr == searchQuery) return true;
            
            // Buscar coincidencia en el ID
            if (cardId.toLowerCase().contains(searchQuery.toLowerCase())) return true;
            
            // Buscar coincidencia parcial en el número
            return cardNoStr.contains(searchQuery);
          }).toList();
        }
        
        final displayedCards = filteredCards.take(displayedCount).toList();
        final hasMore = displayedCount < filteredCards.length;
        
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Inventario de Cartillas (backend)'),
              Text(
                searchQuery.isNotEmpty
                    ? 'Mostrando ${displayedCards.length} de ${filteredCards.length} resultados para "$searchQuery"'
                    : 'Mostrando ${displayedCards.length} de ${filteredCards.length} cartillas ${filterType != 'Todas' ? '($filterType)' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: vendorId,
                        items: _buildVendorDropdownItems(),
                        onChanged: (v) => setSt(() => vendorId = v),
                        decoration: const InputDecoration(labelText: 'Asignar a'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: isLoadingCards ? null : () async { 
                        await loadCards(); 
                      },
                      icon: isLoadingCards 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Buscador por número de cartilla
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar por número de cartilla',
                          hintText: 'Ej: 11, 25, 100',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    setSt(() {
                                      displayedCount = 10;
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setSt(() {
                            displayedCount = 10; // Resetear contador al buscar
                          });
                        },
                      ),
                    ),
                    if (searchQuery.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          searchController.clear();
                          setSt(() {
                            displayedCount = 10;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpiar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Filtro de cartillas
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 20, color: Colors.indigo),
                    const SizedBox(width: 8),
                    const Text(
                      'Filtrar:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: filterType,
                        items: const [
                          DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                          DropdownMenuItem(value: 'Asignadas', child: Text('Asignadas')),
                          DropdownMenuItem(value: 'No asignadas', child: Text('No asignadas')),
                        ],
                        onChanged: (v) {
                          setSt(() {
                            filterType = v ?? 'Todas';
                            displayedCount = 10; // Resetear contador al cambiar filtro
                          });
                        },
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filteredCards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.isNotEmpty
                                    ? 'No se encontraron cartillas con el número "$searchQuery"'
                                    : 'No hay cartillas ${filterType == 'Todas' ? '' : filterType.toLowerCase()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    searchController.clear();
                                    setSt(() {
                                      displayedCount = 10;
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Limpiar búsqueda'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.separated(
                              itemCount: displayedCards.length + (hasMore ? 1 : 0),
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (_, i) {
                                // Botón "Cargar más" al final
                                if (i == displayedCards.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        setSt(() {
                                          displayedCount += 10;
                                        });
                                      },
                                      icon: const Icon(Icons.expand_more),
                                      label: Text('Cargar más (${filteredCards.length - displayedCount} restantes)'),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 48),
                                      ),
                                    ),
                                  );
                                }
                                
                                final c = displayedCards[i];
                                final assignedToId = c['assignedTo'] as String?;
                                final assignedToName = getVendorName(assignedToId);
                                final cardNumber = c['cardNo']?.toString() ?? c['id'];
                                
                                return Card(
                                  child: ListTile(
                                    title: Text('Cartilla $cardNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ID: ${c['id']}'),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              assignedToId != null ? Icons.person : Icons.person_outline,
                                              size: 14,
                                              color: assignedToId != null ? Colors.green : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              assignedToId != null ? 'Asignada a: $assignedToName' : 'Sin asignar',
                                              style: TextStyle(
                                                color: assignedToId != null ? Colors.green.shade700 : Colors.grey,
                                                fontWeight: assignedToId != null ? FontWeight.w500 : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: vendorId == null || isLoadingCards
                                          ? null
                                          : () async {
                                              setSt(() => isLoadingCards = true);
                                              final rr = await http.post(
                                                Uri.parse('$_apiBase/cards/${c['id']}/assign'), 
                                                headers: {'Content-Type': 'application/json'}, 
                                                body: json.encode({'vendorId': vendorId}),
                                              );
                                              setSt(() => isLoadingCards = false);
                                              
                                              if (rr.statusCode < 300) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Cartilla asignada exitosamente'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                                await loadCards();
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: ${rr.body}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                      child: const Text('Asignar'),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ],
        );
      });
    });
  }

  // Método para eliminar vendor (líder o vendedor)
  Future<void> _deleteVendor(Map<String, dynamic> vendor) async {
    final vendorId = vendor['vendorId'] ?? vendor['id'];
    final vendorName = vendor['name'] ?? 'Vendor';
    final vendorRole = vendor['role'] ?? 'VENDOR';
    
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar ${vendorRole == 'LEADER' ? 'Líder' : 'Vendedor'}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres eliminar a "$vendorName"?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Esta acción desasignará la cartilla',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (vendorRole == 'LEADER') ...[
                    Text('• Se eliminará el líder y todos sus datos'),
                    Text('• Los vendedores quedarán sin líder asignado'),
                  ] else ...[
                    Text('• Se eliminará el vendedor y todos sus datos'),
                    Text('• Las cartillas asignadas quedarán sin asignar'),
                  ],
                  Text('• No se pueden eliminar vendors con historial de ventas'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('DESASIGNAR'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar indicador de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Desasignando...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Eliminando $vendorName...'),
          ],
        ),
      ),
    );

    try {
      // Llamar al endpoint de eliminación
      final response = await http.delete(
        Uri.parse('$_apiBase/vendors/$vendorId'),
        headers: {'Content-Type': 'application/json'},
      );

      // Cerrar diálogo de progreso
      Navigator.pop(context);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vendorRole == 'LEADER' ? 'Líder' : 'Vendedor'} eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Refrescar la interfaz
        setState(() { _refreshTick++; });
      } else {
        final error = json.decode(response.body);
        final errorMessage = error['error'] ?? 'Error desconocido';
        
        // Mostrar error específico
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de progreso
      Navigator.pop(context);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reassignLeader(Map<String, dynamic> seller) async {
    await _load(withLeaders: true);
    String? selected = (seller['leaderId'] as String?);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${((selected?.isEmpty) ?? true) ? 'Asignar' : 'Reasignar'} líder a ${seller['name'] ?? 'vendedor'}'),
        content: DropdownButtonFormField<String>(
          value: selected,
          items: _leaders
              .map((l) => DropdownMenuItem<String>(
                    value: (l['id'] as String),
                    child: Text(l['name'] as String),
                  ))
              .toList(),
          onChanged: (v) => selected = v,
          decoration: const InputDecoration(labelText: 'Líder'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true || selected == null) return;
    final resp = await http.patch(
      Uri.parse('$_apiBase/vendors/${seller['vendorId'] ?? seller['id']}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'leaderId': selected}),
    );
    if (!mounted) return;
    if (resp.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Líder asignado')));
      setState(() { _refreshTick++; });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${resp.body}')));
    }
  }

  // Método para eliminar una cartilla individual
  Future<void> _deleteIndividualCard(Map<String, dynamic> card, String vendorId) async {
    final cardNumber = card['cardNo']?.toString() ?? card['id'];
    
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_remove, color: Colors.red),
            SizedBox(width: 8),
            Text('Desasignar Cartilla'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres desasignar la cartilla $cardNumber?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Esta acción desasignará la cartilla',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• La cartilla se desasignará del vendedor/líder'),
                  Text('• Quedará disponible para futuras asignaciones'),
                  Text('• Se liberará el número del inventario actual'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('DESASIGNAR'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar indicador de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Desasignando...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Desasignando cartilla $cardNumber...'),
          ],
        ),
      ),
    );

    try {
      // Desasignar cartilla usando el método del AppProvider
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final success = await appProvider.unassignFirebaseCartilla(card['id']);

      // Cerrar diálogo de progreso
      Navigator.pop(context);

      if (!mounted) return;

      if (success) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cartilla $cardNumber desasignada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Cerrar el diálogo de cartillas asignadas y refrescar
        Navigator.pop(context);
        
        // Mostrar el diálogo actualizado
        await _showAssignedCardsDialog(vendorId);
        
        // Refrescar la interfaz principal
        setState(() { _refreshTick++; });
      } else {
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al desasignar la cartilla $cardNumber'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de progreso
      Navigator.pop(context);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM - Vendedores', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          const DateSelectorWidget(),
          IconButton(
            tooltip: 'Exportar CSV',
            icon: const Icon(Icons.download),
            onPressed: () async {
              final data = await _load();
              final vendors = List<Map<String, dynamic>>.from(data['vendors'] as List);
              await _exportToCsv(vendors);
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load(withLeaders: true, refreshKey: _refreshTick),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final vendors = List<Map<String, dynamic>>.from(snap.data!['vendors'] as List);
          // Ordenar por nombre alfabéticamente
          vendors.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));

          return Column(
            children: [
              // Barra Azul Compacta (Estadísticas)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                height: 65,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Total
                    Expanded(
                      child: _buildCompactStat(
                        label: 'TOTAL',
                        value: '${snap.data!['totalCards'] ?? 0}',
                        icon: Icons.grid_view_rounded,
                      ),
                    ),
                    // Separador
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    // Vendidas
                    Expanded(
                      child: _buildCompactStat(
                        label: 'VENDIDAS',
                        value: _getTotalSold(vendors).toString(),
                        icon: Icons.monetization_on_rounded,
                      ),
                    ),
                    // Separador
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    // Asignadas
                    Expanded(
                      child: _buildCompactStat(
                        label: 'ASIGNADAS',
                        value: _getTotalAssigned(vendors).toString(),
                        icon: Icons.assignment_ind_rounded,
                      ),
                    ),
                    // Separador
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    // Disponibles
                    Expanded(
                      child: _buildCompactStat(
                        label: 'DISPONIBLES',
                        value: '${(snap.data!['totalCards'] ?? 0) - _getTotalAssigned(vendors)}',
                        icon: Icons.inventory_2_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // Acciones (Compactas)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filtro
                      PopupMenuButton<String?>(
                        tooltip: 'Filtrar por líder',
                        onSelected: (v) => setState(() => _leaderId = v),
                        offset: const Offset(0, 40),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.filter_list, size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text(
                                _leaderId != null ? 'Filtro Activo' : 'Filtrar Líder',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem<String?>(
                            value: null,
                            child: const Text('Todos los líderes'),
                          ),
                          ..._leaders.map((l) => PopupMenuItem<String>(
                            value: l['id'] as String,
                            child: Text(l['name'] as String),
                          )),
                        ],
                      ),
                      const SizedBox(width: 8),
                      _compactIconButton(Icons.refresh, 'Actualizar', () => setState(() {}), Colors.indigo),
                      const SizedBox(width: 8),
                      _compactIconButton(Icons.star, 'Nuevo Líder', () => _createVendor(isLeader: true), Colors.amber.shade700),
                      const SizedBox(width: 8),
                      _compactIconButton(Icons.person_add, 'Nuevo Vendedor', () => _createVendor(isLeader: false), Colors.blue),
                      const SizedBox(width: 8),
                      _compactIconButton(Icons.assignment_ind, 'Asignar', _assignCard, Colors.teal),
                      const SizedBox(width: 8),
                      _compactIconButton(Icons.inventory_2, 'Inventario', _showInventoryDialog, Colors.blueGrey),
                      const SizedBox(width: 8),
                      // Eliminar datos
                      Consumer<AppProvider>(
                        builder: (context, appProvider, child) {
                          return IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                            tooltip: 'Eliminar datos del ${appProvider.selectedDate}',
                            onPressed: _clearCommissions,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Lista jerárquica moderna: líderes con vendedores y subvendedores
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey[50]!,
                        Colors.grey[100]!,
                      ],
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Mostrar líderes primero con diseño moderno
                      ...vendors.where((v) => (v['role'] ?? '') == 'LEADER').map((leader) {
                        final rawChildren = (leader['children'] as List?) ?? [];
                        List<Map<String, dynamic>> sellerObjs;
                        if (rawChildren.isNotEmpty && rawChildren.first is String) {
                          final ids = rawChildren.cast<String>();
                          sellerObjs = vendors.where((s) => (s['role'] ?? '') != 'LEADER' && ids.contains((s['vendorId'] ?? s['id']).toString())).toList();
                        } else if (rawChildren.isNotEmpty && rawChildren.first is Map) {
                          sellerObjs = List<Map<String, dynamic>>.from(rawChildren);
                        } else {
                          sellerObjs = vendors.where((s) => (s['role'] ?? '') != 'LEADER' && (s['leaderId'] == leader['vendorId'])).toList();
                        }
                        
                        // Separar vendedores y subvendedores
                        final sellers = sellerObjs.where((s) => (s['role'] ?? '') == 'SELLER').toList();
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              childrenPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    (leader['name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                leader['name'] ?? '—',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '👑 LÍDER',
                                      style: TextStyle(
                                        color: Color(0xFFFF6B35),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${sellers.length} vendedores',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                // Estadísticas del líder con diseño horizontal compacto
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      // Stats (Izquierda)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            _modernStatCompact(
                                              'Vendidas',
                                              leader['soldCount'].toString(),
                                              icon: Icons.confirmation_number_outlined,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 16),
                                            _modernStatCompact(
                                              'Asignadas',
                                              (leader['assignedCount'] ?? 0).toString(),
                                              icon: Icons.assignment_ind_outlined,
                                              color: Colors.orange,
                                              onTap: () => _showAssignedCardsDialog(leader['vendorId'] ?? leader['id']),
                                            ),
                                            const SizedBox(width: 16),
                                            _modernStatCompact(
                                              'Ingreso',
                                              '${((leader['totalAmount'] ?? 0) * 0.75).toStringAsFixed(2)} Bs',
                                              icon: Icons.monetization_on_outlined,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 16),
                                            _modernStatCompact(
                                              'Comisión',
                                              '${(((leader['totalAmount'] ?? 0) * 0.25) + (sellerObjs.fold<double>(0.0, (sum, s) => sum + (s['totalAmount'] ?? 0)) * 0.10)).toStringAsFixed(2)} Bs',
                                              icon: Icons.account_balance_wallet_outlined,
                                              color: Colors.purple,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Acciones (Derecha)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _modernButton(
                                            'Vender',
                                            Icons.point_of_sale,
                                            () => _registerSaleDialog(leader['vendorId'] ?? leader['id']),
                                            Colors.blue,
                                            isSmall: true,
                                          ),
                                          const SizedBox(width: 8),
                                          _modernButton(
                                            'Todo',
                                            Icons.sell_outlined,
                                            () => _sellAllAssigned(leader['vendorId'] ?? leader['id']),
                                            Colors.green,
                                            isSmall: true,
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                                            tooltip: 'Eliminar Líder',
                                            onPressed: () => _deleteVendor(leader),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.deepOrange),
                                            tooltip: 'Eliminar datos de ventas',
                                            onPressed: () => _clearCommissionsForVendor(leader['vendorId'] ?? leader['id'], leader['name'] ?? 'Líder'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Vendedores con diseño jerárquico (incluyendo sus subvendedores)
                                if (sellers.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.group, color: Colors.blue, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'VENDEDORES',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...sellers.map((seller) => _buildSellerCard(seller)),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      
                      // Mostrar vendedores sin líder (huérfanos) con diseño moderno
                      ...vendors.where((v) => (v['role'] ?? '') != 'LEADER' && (v['leaderId'] == null || v['leaderId'] == '')).map((s) => 
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Icon(Icons.person, color: Colors.grey),
                              ),
                              title: Text(
                                s['name'] ?? '—',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Vendedor sin líder',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _modernButton(
                                    'Asignar líder',
                                    Icons.person_add_alt,
                                    () => _reassignLeader(s),
                                    Colors.blue,
                                    isSmall: true,
                                  ),
                                  const SizedBox(width: 8),
                                  _modernButton(
                                    'Eliminar',
                                    Icons.delete_forever,
                                    () => _deleteVendor(s),
                                    Colors.red,
                                    isSmall: true,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.cleaning_services_rounded, color: Colors.deepOrange),
                                    tooltip: 'Eliminar datos de ventas',
                                    onPressed: () => _clearCommissionsForVendor(s['vendorId'] ?? s['id'], s['name'] ?? 'Vendedor'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _clearCommissionsForVendor(String vendorId, String vendorName) async {
    // Primero mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
            SizedBox(width: 8),
            Expanded(child: Text('ELIMINAR DATOS DE $vendorName')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres eliminar los datos de ventas de este vendedor?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Se ELIMINARÁN:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            SizedBox(height: 8),
            Text('• Todas las ventas registradas por este vendedor'),
            Text('• Todos los balances asociados'),
            SizedBox(height: 16),
            Text(
              'Esta acción NO se puede deshacer.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: Text('ELIMINAR DATOS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar diálogo de confirmación final
    final finalConfirmController = TextEditingController();
    final finalConfirm = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.dangerous, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmación Final'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para confirmar, escribe exactamente:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                'ELIMINAR_DATOS_2024',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: finalConfirmController,
              decoration: InputDecoration(
                labelText: 'Confirmar texto',
                border: OutlineInputBorder(),
                hintText: 'Escribe el texto de arriba',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (finalConfirmController.text == 'ELIMINAR_DATOS_2024') {
                Navigator.pop(context, finalConfirmController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('El texto no coincide')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('CONFIRMAR ELIMINACIÓN'),
          ),
        ],
      ),
    );

    if (finalConfirm != 'ELIMINAR_DATOS_2024') return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final resp = await http.post(
        Uri.parse('$_apiBase/reports/clear-commissions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'confirm': 'ELIMINAR_DATOS_2024',
          'dryRun': false,
          'vendorId': vendorId,
        }),
      );

      Navigator.pop(context); // Cerrar loading

      if (resp.statusCode < 300) {
        final result = json.decode(resp.body);
        final summary = result['summary'];
        
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Datos Eliminados'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Se han eliminado los datos correctamente para $vendorName.'),
                SizedBox(height: 16),
                Text('Resumen:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Ventas eliminadas: ${summary['salesDeleted']}'),
                Text('• Balances eliminados: ${summary['balancesDeleted']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CERRAR'),
              ),
            ],
          ),
        );

        setState(() {
          _refreshTick++;
        });
      } else {
        final error = json.decode(resp.body);
        throw Exception(error['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _modernStatCompact(String label, String value, {required IconData icon, required Color color, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (onTap != null)
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(1.0),
                    ),
                  ),
                ),
              )
            else
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.8),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _modernButton(String label, IconData icon, VoidCallback onPressed, Color color, {bool isSmall = false}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isSmall ? 16 : 20),
      label: Text(label, style: TextStyle(fontSize: isSmall ? 12 : 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16, vertical: isSmall ? 8 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSellerCard(Map<String, dynamic> seller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
      child: Card(
        elevation: 0,
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller['name'] ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Vendedor',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Acciones del vendedor
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _modernButton(
                        'Vender',
                        Icons.point_of_sale,
                        () => _registerSaleDialog(seller['vendorId'] ?? seller['id']),
                        Colors.blue,
                        isSmall: true,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                        tooltip: 'Eliminar Vendedor',
                        onPressed: () => _deleteVendor(seller),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.cleaning_services_rounded, color: Colors.deepOrange, size: 20),
                        tooltip: 'Eliminar datos de ventas',
                        onPressed: () => _clearCommissionsForVendor(seller['vendorId'] ?? seller['id'], seller['name'] ?? 'Vendedor'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Estadísticas del vendedor
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _modernStatCompact(
                      'Vendidas',
                      seller['soldCount'].toString(),
                      icon: Icons.confirmation_number_outlined,
                      color: Colors.blue,
                    ),
                    _modernStatCompact(
                      'Asignadas',
                      (seller['assignedCount'] ?? 0).toString(),
                      icon: Icons.assignment_ind_outlined,
                      color: Colors.orange,
                      onTap: () => _showAssignedCardsDialog(seller['vendorId'] ?? seller['id']),
                    ),
                    _modernStatCompact(
                      'Ingreso',
                      '${((seller['totalAmount'] ?? 0) * 0.65).toStringAsFixed(2)} Bs',
                      icon: Icons.monetization_on_outlined,
                      color: Colors.green,
                    ),
                    _modernStatCompact(
                      'Comisión',
                      '${((seller['totalAmount'] ?? 0) * 0.25).toStringAsFixed(2)} Bs',
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStat({required String label, required String value, required IconData icon}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _compactIconButton(IconData icon, String tooltip, VoidCallback onPressed, Color color) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
  int _getTotalSold(List<Map<String, dynamic>> vendors) {
    return vendors.fold<int>(0, (sum, vendor) => sum + (_toInt(vendor['soldCount'])));
  }

  int _getTotalAssigned(List<Map<String, dynamic>> vendors) {
    return vendors.fold<int>(0, (sum, vendor) => sum + (_toInt(vendor['assignedCount'])));
  }

  int _getTotalAvailable(List<Map<String, dynamic>> vendors) {
    return _getTotalAssigned(vendors) - _getTotalSold(vendors);
  }

  int _getTotalUnassigned(List<Map<String, dynamic>> vendors, int totalCards) {
    return totalCards - _getTotalAssigned(vendors);
  }

  // Método para construir items del dropdown ordenados por líderes y vendedores
  List<DropdownMenuItem<String>> _buildVendorDropdownItems() {
    final items = <DropdownMenuItem<String>>[];
    
    // Ordenar vendedores por nombre alfabéticamente
    final sortedVendors = List<Map<String, dynamic>>.from(_vendorsAll);
    sortedVendors.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
    
    // Agrupar por líderes
    final leaders = sortedVendors.where((v) => (v['role'] ?? '') == 'LEADER').toList();
    
    for (final leader in leaders) {
      // Agregar el líder
      items.add(DropdownMenuItem<String>(
        value: leader['id'] as String,
        child: Text('👑 Líder: ${leader['name']}'),
      ));
      
      // Agregar sus vendedores
      final leaderId = leader['vendorId'] ?? leader['id'];
      final sellers = sortedVendors.where((v) => 
        (v['role'] ?? '') != 'LEADER' && 
        (v['leaderId'] == leaderId || v['leaderId'] == leaderId.toString())
      ).toList();
      
      for (final seller in sellers) {
        final sellerRole = 'Vendedor';
        final sellerIcon = '👤';
        
        items.add(DropdownMenuItem<String>(
          value: seller['id'] as String,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text('$sellerIcon $sellerRole: ${seller['name']}'),
          ),
        ));
      }
    }
    
    // Agregar vendedores sin líder (huérfanos)
    final orphanSellers = sortedVendors.where((v) => 
      (v['role'] ?? '') != 'LEADER' && 
      (v['leaderId'] == null || v['leaderId'] == '' || v['leaderId'] == 'null')
    ).toList();
    
    if (orphanSellers.isNotEmpty) {
      items.add(DropdownMenuItem<String>(
        value: 'divider',
        child: Text('--- Vendedores sin líder ---', style: TextStyle(color: Colors.grey.shade600)),
        enabled: false,
      ));
      
      for (final seller in orphanSellers) {
        final sellerRole = 'Vendedor';
        final sellerIcon = '👤';
        
        items.add(DropdownMenuItem<String>(
          value: seller['id'] as String,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text('$sellerIcon $sellerRole: ${seller['name']}'),
          ),
        ));
      }
    }
    
    return items;
  }

  // Método helper para convertir valores de Firebase a int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Widget _summaryStat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, {String? assignedValue, String? vendorId}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (assignedValue != null) ...[
          Tooltip(
            message: 'Haz clic para ver todas las cartillas asignadas',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () => _showAssignedCardsDialog(vendorId!),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        assignedValue,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'asig',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  // Método para descargar todas las cartillas asignadas de una vez con resolución optimizada (720x1020)
  Future<void> _downloadAllAssignedCards(List<Map<String, dynamic>> cards, String vendorId) async {
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay cartillas para descargar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: Colors.green),
            SizedBox(width: 8),
            Text('Descargar Todas las Cartillas'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Quieres descargar todas las ${cards.length} cartillas asignadas?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Información de la descarga:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Se descargarán ${cards.length} cartillas en formato PNG'),
                  Text('• Cada cartilla tendrá su número único'),
                  Text('• Resolución optimizada: 720x1020 píxeles'),
                  Text('• Las descargas se realizarán secuencialmente'),
                  Text('• El proceso puede tomar varios segundos'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('DESCARGAR TODAS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar diálogo de progreso
    final total = cards.length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Descargando Cartillas...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: 0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 16),
            Text(
              'Descargadas: 0 / $total',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Descargando cartilla 1 de $total...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );

    try {
      // Obtener la fecha del evento del provider
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final eventDateStr = appProvider.selectedDate;
      
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
      
      int successCount = 0;
      int errorCount = 0;
      
      for (int i = 0; i < cards.length; i++) {
        final card = cards[i];
        final cardNumber = card['cardNo']?.toString() ?? card['id'];
        
        // Usar la fecha del evento del card si está disponible, sino usar la del provider
        String cardDate = card['date'] as String? ?? eventDateStr;
        String cardFormattedDate;
        try {
          final dateParts = cardDate.split('-');
          if (dateParts.length == 3) {
            cardFormattedDate = '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
          } else {
            cardFormattedDate = formattedDate;
          }
        } catch (e) {
          cardFormattedDate = formattedDate;
        }
        
        try {
          final imageBytes = await renderCartillaImage(
            numbers: _convertNumbersToIntList(card['numbers'] ?? []),
            cardNumber: cardNumber,
            date: cardFormattedDate,
            price: "Bs. 20",
            pixelRatio: 1.0,
          );
          
          if (imageBytes.isNotEmpty) {
            // Descargar la imagen
            await _saveImageToDevice(imageBytes, 'cartilla_$cardNumber.png');
            successCount++;
          } else {
            errorCount++;
          }
          
          // Actualizar progreso
          if (mounted) {
            // Cerrar diálogo anterior y mostrar uno nuevo con progreso actualizado
            Navigator.pop(context);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text('Descargando Cartillas...'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: (i + 1) / total,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Descargadas: ${i + 1} / $total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Descargando cartilla ${i + 2 > total ? total : i + 2} de $total...',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '✅ Exitosas: $successCount  •  ❌ Errores: $errorCount',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Pequeña pausa para evitar sobrecargar el sistema
          await Future.delayed(const Duration(milliseconds: 200));
          
        } catch (e) {
          errorCount++;
          debugPrint('Error descargando cartilla $cardNumber: $e');
        }
      }
      
      // Cerrar diálogo de progreso
      if (mounted) Navigator.pop(context);
      
      // Mostrar resumen final
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  successCount > 0 ? Icons.check_circle : Icons.error,
                  color: successCount > 0 ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text('Descarga Completada'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: successCount > 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: successCount > 0 ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de Descarga:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('• Total de cartillas: $total'),
                      Text(
                        '• Descargadas exitosamente: $successCount',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (errorCount > 0)
                        Text(
                          '• Errores: $errorCount',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (successCount > 0) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Las cartillas se han descargado en tu carpeta de descargas. Cada archivo tiene el formato "cartilla_[número].png"',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Aceptar'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      // Cerrar diálogo de progreso
      if (mounted) Navigator.pop(context);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error durante la descarga masiva: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // Método para eliminar todas las cartillas asignadas de una vez
  Future<void> _deleteAllAssignedCards(List<Map<String, dynamic>> cards, String vendorId) async {
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay cartillas para desasignar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_remove, color: Colors.red),
            SizedBox(width: 8),
            Text('DESASIGNAR TODAS LAS CARTILLAS'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚨 ADVERTENCIA CRÍTICA: Esta operación desasignará todas las cartillas',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '¿Estás seguro de que quieres desasignar TODAS las ${cards.length} cartillas asignadas?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ CONSECUENCIAS DE ESTA ACCIÓN:',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• Se DESASIGNARÁN ${cards.length} cartillas del vendedor/líder'),
                  Text('• Las cartillas quedarán disponibles para futuras asignaciones'),
                  Text('• Los números se liberarán del inventario actual'),
                  Text('• Se limpiará completamente la asignación'),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta operación es útil para desasignar completamente el inventario de un vendedor o líder.',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('DESASIGNAR TODAS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar diálogo de progreso
    final total = cards.length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('DESASIGNANDO CARTILLAS...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: 0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
            SizedBox(height: 16),
            Text(
              'Desasignadas: 0 / $total',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Desasignando cartilla 1 de $total...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );

    try {
      int successCount = 0;
      int errorCount = 0;
      
      for (int i = 0; i < cards.length; i++) {
        final card = cards[i];
        final cardNumber = card['cardNo']?.toString() ?? card['id'];
        
        try {
          // Desasignar cartilla usando el método del AppProvider
          final appProvider = Provider.of<AppProvider>(context, listen: false);
          final success = await appProvider.unassignFirebaseCartilla(card['id']);
          
          if (success) {
            successCount++;
          } else {
            errorCount++;
            debugPrint('Error desasignando cartilla $cardNumber');
          }
          
          // Actualizar progreso
          if (mounted) {
            // Cerrar diálogo anterior y mostrar uno nuevo con progreso actualizado
            Navigator.pop(context);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text('DESASIGNANDO CARTILLAS...'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: (i + 1) / total,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Desasignadas: ${i + 1} / $total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Desasignando cartilla ${i + 2 > total ? total : i + 2} de $total...',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '✅ Exitosas: $successCount  •  ❌ Errores: $errorCount',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Pequeña pausa para evitar sobrecargar el sistema
          await Future.delayed(const Duration(milliseconds: 100));
          
        } catch (e) {
          errorCount++;
          debugPrint('Error desasignando cartilla $cardNumber: $e');
        }
      }
      
      // Cerrar diálogo de progreso
      if (mounted) Navigator.pop(context);
      
      // Mostrar resumen final
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  successCount > 0 ? Icons.check_circle : Icons.error,
                  color: successCount > 0 ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text('Desasignación Completada'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: successCount > 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: successCount > 0 ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de Desasignación:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('• Total de cartillas: $total'),
                      Text(
                        '• Desasignadas exitosamente: $successCount',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (errorCount > 0)
                        Text(
                          '• Errores: $errorCount',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (successCount > 0) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El inventario ha sido desasignado completamente. Los números de cartilla están disponibles para futuras asignaciones.',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Aceptar'),
              ),
            ],
          ),
        );
      }
      
      // Refrescar la interfaz principal
      if (mounted) {
        setState(() { _refreshTick++; });
      }
      
    } catch (e) {
      // Cerrar diálogo de progreso
      if (mounted) Navigator.pop(context);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error durante la eliminación masiva: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // Método para exportar datos del CRM a Excel
  Future<void> _exportToExcel() async {
    try {
      // Mostrar diálogo de opciones de exportación
      final exportType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.green),
              SizedBox(width: 8),
              Text('Exportar CRM'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selecciona el formato de exportación:'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'excel'),
                    icon: Icon(Icons.table_chart, color: Colors.white),
                    label: Text('Excel (.xlsx)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'csv'),
                    icon: Icon(Icons.description, color: Colors.white),
                    label: Text('CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'sheets'),
                icon: Icon(Icons.cloud, color: Colors.white),
                label: Text('Google Sheets'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
          ],
        ),
      );

      if (exportType == null) return;

      // Mostrar indicador de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Exportando datos...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparando datos para exportación...'),
            ],
          ),
        ),
      );

      // Cargar datos completos del CRM
      final data = await _load(withLeaders: true);
      final vendors = List<Map<String, dynamic>>.from(data['vendors'] ?? []);
      
      // Cerrar diálogo de progreso
      if (mounted) Navigator.pop(context);

      // Exportar según el tipo seleccionado
      switch (exportType) {
        case 'excel':
          await _exportToExcelFile(vendors);
          break;
        case 'csv':
          await _exportToCsv(vendors);
          break;
        case 'sheets':
          await _exportToGoogleSheets(vendors);
          break;
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Exportar a archivo Excel (.xlsx)
  Future<void> _exportToExcelFile(List<Map<String, dynamic>> vendors) async {
    try {
      // Crear un nuevo libro de Excel
      final excel = excel_pkg.Excel.createExcel();
      
      // Obtener la hoja por defecto y renombrarla
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.delete(defaultSheet);
      }
      
      // Crear una nueva hoja llamada "CRM Bingo Patuju"
      final sheet = excel['CRM Bingo Patuju'];
      
      // Preparar los datos
      final excelData = await _prepareExcelData(vendors);
      
      // Agregar los datos a la hoja
      for (int rowIndex = 0; rowIndex < excelData.length; rowIndex++) {
        final rowData = excelData[rowIndex];
        
        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          final cell = sheet.cell(
            excel_pkg.CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex)
          );
          
          // Intentar convertir a número si es posible, sino usar texto
          final cellValue = rowData[colIndex];
          final numValue = num.tryParse(cellValue);
          
          if (numValue != null) {
            // Usar el constructor apropiado según el tipo de número
            if (numValue is int || numValue == numValue.toInt()) {
              cell.value = excel_pkg.IntCellValue(numValue.toInt());
            } else {
              cell.value = excel_pkg.DoubleCellValue(numValue.toDouble());
            }
          } else {
            cell.value = excel_pkg.TextCellValue(cellValue);
          }
          
          // Estilo para la primera fila (encabezados)
          if (rowIndex == 0) {
            cell.cellStyle = excel_pkg.CellStyle(
              bold: true,
              backgroundColorHex: excel_pkg.ExcelColor.fromHexString('#4CAF50'),
              fontColorHex: excel_pkg.ExcelColor.white,
            );
          }
        }
      }
      
      // Codificar el archivo a bytes
      final List<int>? excelBytes = excel.encode();
      
      if (excelBytes == null) {
        throw Exception('No se pudo codificar el archivo Excel');
      }
      
      // Crear Blob con el tipo MIME correcto para archivos Excel
      final blob = html.Blob(
        [Uint8List.fromList(excelBytes)],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      );
      
      // Crear URL y descargar
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'CRM_Bingo_Patuju_${DateTime.now().millisecondsSinceEpoch}.xlsx')
        ..click();
      
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Datos exportados a Excel exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al exportar a Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Exportar a Google Sheets
  Future<void> _exportToGoogleSheets(List<Map<String, dynamic>> vendors) async {
    try {
      // Google Sheets no permite importación directa desde URL sin autenticación
      // La mejor alternativa es descargar un Excel que el usuario puede subir a Sheets
      
      // Mostrar diálogo informativo
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Exportar a Google Sheets'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se descargará un archivo Excel (.xlsx) compatible con Google Sheets.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Para importarlo a Google Sheets:'),
              SizedBox(height: 8),
              Text('1. Ve a sheets.google.com'),
              Text('2. Haz clic en "Archivo" → "Importar"'),
              Text('3. Selecciona "Subir" y elige el archivo descargado'),
              Text('4. Haz clic en "Importar datos"'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: Icon(Icons.download),
              label: Text('Descargar Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
      
      if (shouldProceed != true) return;
      
      // Descargar el archivo Excel
      await _exportToExcelFile(vendors);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📊 Archivo descargado. Súbelo a Google Sheets para continuar'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Preparar datos para Excel/Google Sheets
  Future<List<List<String>>> _prepareExcelData(List<Map<String, dynamic>> vendors) async {
    final data = <List<String>>[];
    
    // Encabezados
    data.add([
      'Nombre',
      'Rol',
      'Lider',
      'Cartillas Asignadas',
      'Numeros de Cartillas',
      'Cartillas Vendidas', // Cantidad
      'Ingresos (Bs)',
      'Comision (Bs)',
      'Fecha Ultima Venta',
      'Estado'
    ]);
    
    // Datos de cada vendedor
    for (final vendor in vendors) {
      final role = vendor['role'] ?? '';
      final isLeader = role == 'LEADER';
      
      // Buscar líder si es vendedor
      String leaderName = '';
      if (!isLeader) {
        final leaderId = vendor['leaderId'];
        if (leaderId != null) {
          final leader = vendors.firstWhere(
            (v) => (v['vendorId'] ?? v['id']) == leaderId,
            orElse: () => <String, dynamic>{},
          );
          leaderName = leader['name'] ?? '';
        }
      }
      
      final vendorId = vendor['vendorId'] ?? vendor['id'];
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final selectedDate = appProvider.selectedDate;

      // Obtener números específicos de cartillas asignadas (sold=false)
      String assignedCardNumbers = '';
      try {
        final assignedResp = await http.get(
          Uri.parse('$_apiBase/cards?assignedTo=$vendorId&date=$selectedDate&sold=false')
        );
        
        if (assignedResp.statusCode < 300) {
          final responseBody = assignedResp.body;
          dynamic parsedData = json.decode(responseBody);
          List<Map<String, dynamic>> assignedCards;
          
          if (parsedData is List) {
            assignedCards = List<Map<String, dynamic>>.from(parsedData);
          } else if (parsedData is Map && parsedData['cards'] != null) {
            assignedCards = List<Map<String, dynamic>>.from(parsedData['cards']);
          } else {
            assignedCards = [];
          }
          
          if (assignedCards.isNotEmpty) {
            final cardNumbers = assignedCards
              .map((card) => card['cardNo']?.toString() ?? '')
              .where((cardNum) => cardNum.isNotEmpty)
              .toList();
            
            cardNumbers.sort((a, b) {
              final aNum = int.tryParse(a) ?? 0;
              final bNum = int.tryParse(b) ?? 0;
              return aNum.compareTo(bNum);
            });
            
            assignedCardNumbers = cardNumbers.join(', ');
          }
        }
      } catch (e) {
        assignedCardNumbers = 'Error: $e';
      }


      
      // Estado del vendedor
      String status = 'Activo';
      if (vendor['soldCount'] != null && vendor['soldCount'] > 0) {
        status = 'Con Ventas';
      } else if (vendor['assignedCount'] != null && vendor['assignedCount'] > 0) {
        status = 'Con Cartillas Asignadas';
      }

      // Calcular Ingresos y Comisión según fórmula del UI
      double ingreso = 0.0;
      double comision = 0.0;
      final double totalAmount = (vendor['totalAmount'] ?? 0).toDouble();

      if (isLeader) {
        // Fórmula Líder UI: 
        // Ingreso: totalAmount * 0.75
        // Comisión: (totalAmount * 0.25) + (10% de ventas de sus vendedores)
        
        ingreso = totalAmount * 0.75;
        
        // Calcular 10% de ventas de sus vendedores
        double sellersTotalAmount = 0.0;
        final rawChildren = (vendor['children'] as List?) ?? [];
        
        if (rawChildren.isNotEmpty && rawChildren.first is String) {
           final ids = rawChildren.cast<String>();
           final mySellers = vendors.where((s) => (s['role'] ?? '') != 'LEADER' && ids.contains((s['vendorId'] ?? s['id']).toString()));
           sellersTotalAmount = mySellers.fold<double>(0.0, (sum, s) => sum + ((s['totalAmount'] ?? 0).toDouble()));
        } else if (rawChildren.isNotEmpty && rawChildren.first is Map) {
           sellersTotalAmount = rawChildren.fold<double>(0.0, (sum, s) => sum + ((s['totalAmount'] ?? 0).toDouble()));
        } else {
           // Fallback: buscar por leaderId
           final mySellers = vendors.where((s) => (s['role'] ?? '') != 'LEADER' && (s['leaderId'] == vendorId));
           sellersTotalAmount = mySellers.fold<double>(0.0, (sum, s) => sum + ((s['totalAmount'] ?? 0).toDouble()));
        }

        comision = (totalAmount * 0.25) + (sellersTotalAmount * 0.10);

      } else {
        // Fórmula Vendedor UI:
        // Ingreso: totalAmount * 0.65
        // Comisión: totalAmount * 0.25
        ingreso = totalAmount * 0.65;
        comision = totalAmount * 0.25;
      }
      
      data.add([
        vendor['name'] ?? '',
        role,
        leaderName,
        (vendor['assignedCount'] ?? 0).toString(),
        assignedCardNumbers,
        (vendor['soldCount'] ?? 0).toString(),
        ingreso.toStringAsFixed(2),
        comision.toStringAsFixed(2),
        vendor['lastSaleDate'] ?? '',
        status
      ]);
    }
    
    return data;
  }

  // Crear contenido CSV
  String _createCsvContent(List<List<String>> data) {
    final csv = StringBuffer();
    
    for (final row in data) {
      final csvRow = row.map((cell) {
        // Escapar comillas y envolver en comillas si contiene comas
        final escaped = cell.replaceAll('"', '""');
        return '"$escaped"';
      }).join(',');
      csv.writeln(csvRow);
    }
    
    return csv.toString();
  }

  // Método mejorado para exportar CSV
  Future<void> _exportToCsv(List<Map<String, dynamic>> vendors) async {
    try {
      final data = await _prepareExcelData(vendors);
      final csvContent = _createCsvContent(data);
      
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'CRM_Bingo_Patuju_${DateTime.now().millisecondsSinceEpoch}.csv')
        ..click();
      
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Datos exportados a CSV exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Widget optimizado para el diálogo de cartillas asignadas
class _AssignedCardsDialog extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String vendorPhone;
  final String apiBase;
  final String eventDate;
  final Function(List<Map<String, dynamic>>) onDownloadAll;
  final Function(List<Map<String, dynamic>>) onDeleteAll;
  final Function(Map<String, dynamic>) onOpenCartilla;
  final Function(Map<String, dynamic>) onDeleteCard;

  const _AssignedCardsDialog({
    required this.vendorId,
    required this.vendorName,
    required this.vendorPhone,
    required this.apiBase,
    required this.eventDate,
    required this.onDownloadAll,
    required this.onDeleteAll,
    required this.onOpenCartilla,
    required this.onDeleteCard,
  });

  @override
  State<_AssignedCardsDialog> createState() => _AssignedCardsDialogState();
}

class _AssignedCardsDialogState extends State<_AssignedCardsDialog> {
  List<Map<String, dynamic>>? _cards;
  bool _isLoading = true;
  bool _isSharing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      List<Map<String, dynamic>> unsoldCards = [];
      List<Map<String, dynamic>> soldCards = [];
      
      // Función helper para cargar cartillas con paginación
      Future<void> loadCardsPage(String sold, List<Map<String, dynamic>> targetList) async {
        String? lastDocId;
        
        Future<void> loadPage() async {
          final queryParams = <String>[
            'assignedTo=${widget.vendorId}',
            'sold=$sold',
            'date=${widget.eventDate}',
            'limit=2000'
          ];
          if (lastDocId != null) {
            queryParams.add('startAfter=$lastDocId');
          }
          
          final resp = await http.get(Uri.parse('${widget.apiBase}/cards?${queryParams.join('&')}'));
          
          if (!mounted) return;
          
          if (resp.statusCode >= 300) {
            throw Exception('Error ${resp.statusCode}: ${resp.body}');
          }
          
          final responseData = json.decode(resp.body) as Map<String, dynamic>;
          final pageCards = List<Map<String, dynamic>>.from(responseData['cards'] as List? ?? []);
          final pagination = responseData['pagination'] as Map<String, dynamic>?;
          
          targetList.addAll(pageCards);
          lastDocId = pagination?['lastDocId'] as String?;
          
          // Si hay más páginas, cargar la siguiente
          if (pagination?['hasMore'] == true && lastDocId != null) {
            await loadPage();
          }
        }
        
        await loadPage();
      }
      
      // Cargar cartillas no vendidas y vendidas en paralelo
      await Future.wait([
        loadCardsPage('false', unsoldCards),
        loadCardsPage('true', soldCards),
      ]);
      
      if (!mounted) return;
      
      // Merge and sort by card number
      final allCards = [...unsoldCards, ...soldCards];
      allCards.sort((a, b) {
        final aNum = int.tryParse(a['cardNo']?.toString() ?? '0') ?? 0;
        final bNum = int.tryParse(b['cardNo']?.toString() ?? '0') ?? 0;
        return aNum.compareTo(bNum);
      });
      
      if (mounted) {
        setState(() {
          _cards = allCards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de conexión: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _refreshCards() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _loadCards();
  }

  Future<void> _shareOnWhatsApp() async {
    setState(() => _isSharing = true);
    try {
      // Verificar que hay cartillas cargadas
      if (_cards == null || _cards!.isEmpty) {
        throw Exception('No hay cartillas para compartir');
      }

      // 1. Generar el PDF localmente con las cartillas asignadas
      final Uint8List pdfBytes = await PdfGenerator.generateMultipleCartillasPdf(
        cards: _cards!,
        vendorName: widget.vendorName,
        eventDate: widget.eventDate,
      );

      // 2. Subir el PDF a Firebase Storage
      final String pdfUrl = await StorageService.uploadMultipleCartillasPdf(
        bytes: pdfBytes,
        vendorId: widget.vendorId,
        vendorName: widget.vendorName,
        eventDate: widget.eventDate,
      );

      // 3. Preparar número de teléfono (Bolivia: código +591)
      String phone = widget.vendorPhone.replaceAll(RegExp(r'[^\d]'), '');
      if (phone.isEmpty) {
        throw Exception('El vendedor no tiene número de teléfono registrado');
      }
      if (!phone.startsWith('591')) {
        phone = '591$phone';
      }

      // 4. Crear mensaje con la URL del PDF
      final message = 'Hola ${widget.vendorName}, aquí están tus cartillas asignadas de Bingo Imperial para el evento del ${widget.eventDate}:\n\n📥 $pdfUrl';
      
      // 5. Construir URL de WhatsApp Web
      final whatsappUrl = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

      // 6. Abrir WhatsApp en nueva pestaña/aplicación externa
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ WhatsApp abierto con el enlace del PDF'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('No se pudo abrir WhatsApp');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.assignment, color: Colors.green),
          SizedBox(width: 8),
          Text('Cartillas Asignadas'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.6,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando cartillas...'),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshCards,
                          icon: Icon(Icons.refresh),
                          label: Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _cards == null || _cards!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, color: Colors.grey, size: 48),
                            SizedBox(height: 16),
                            Text('No hay cartillas asignadas'),
                          ],
                        ),
                      )
                    : _buildContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final soldCount = _cards!.where((c) {
      final soldVal = c['sold'];
      return soldVal == true || soldVal == 'true' || soldVal == 1;
    }).length;

    return Column(
      children: [
        Text(
          'Total: ${_cards!.length} cartillas asignadas ($soldCount vendidas)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green.shade700,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Haz clic en el botón rojo para desasignar',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => widget.onDownloadAll(_cards!),
              icon: Icon(Icons.download, color: Colors.white),
              label: Text('Descargar (${_cards!.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await widget.onDeleteAll(_cards!);
                _refreshCards();
              },
              icon: Icon(Icons.person_remove, color: Colors.white),
              label: Text('Desasignar (${_cards!.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isSharing ? null : _shareOnWhatsApp,
              icon: _isSharing 
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(FontAwesomeIcons.whatsapp, color: Colors.white),
              label: Text('WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            // Optimizaciones de rendimiento
            cacheExtent: 500,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _cards!.length,
            itemBuilder: (context, index) {
              final card = _cards![index];
              final cardNumber = card['cardNo']?.toString() ?? card['id'];
              
              return RepaintBoundary(
                child: _CardItemWidget(
                  card: card,
                  cardNumber: cardNumber,
                  onTap: () => widget.onOpenCartilla(card),
                  onDelete: () {
                    widget.onDeleteCard(card);
                    _refreshCards();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Widget optimizado para cada item de cartilla
class _CardItemWidget extends StatelessWidget {
  final Map<String, dynamic> card;
  final String cardNumber;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CardItemWidget({
    required this.card,
    required this.cardNumber,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Check for various truthy values just in case
    final soldVal = card['sold'];
    final isSold = soldVal == true || soldVal == 'true' || soldVal == 1;
    
    final bgColor = isSold ? Colors.blue.shade100 : Colors.green.shade100;
    final borderColor = isSold ? Colors.blue.shade300 : Colors.green.shade300;
    final textColor = isSold ? Colors.blue.shade800 : Colors.green.shade800;
    final subTextColor = isSold ? Colors.blue.shade600 : Colors.green.shade600;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Stack(
        children: [
          // Botón de eliminación (solo si NO está vendida)
          if (!isSold)
            Positioned(
              top: 2,
              right: 2,
              child: Tooltip(
                message: 'Desasignar cartilla $cardNumber',
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          // Contenido principal
          GestureDetector(
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cardNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isSold ? 'VENDIDA' : 'Cartilla',
                    style: TextStyle(
                      fontSize: 10,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
