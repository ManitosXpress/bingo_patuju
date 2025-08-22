import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import '../config/backend_config.dart';
import '../widgets/cartilla_widget.dart';
import '../block_assignment.dart';

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> {
  final DateFormat _df = DateFormat('yyyy-MM-dd');
  DateTime? _from;
  DateTime? _to;
  String? _leaderId;
  List<Map<String, dynamic>> _leaders = [];
  List<Map<String, dynamic>> _vendorsAll = [];
  int _refreshTick = 0;

  // Usar la configuración centralizada del backend
  String get _apiBase => BackendConfig.apiBase;

  Future<void> _showVendorDetail(Map<String, dynamic> vendor) async {
    final sellerId = vendor['vendorId'] ?? vendor['id'] ?? vendor['vendorId'];
    final salesUri = Uri.parse('$_apiBase/sales?sellerId=$sellerId');
    final cardsUri = Uri.parse('$_apiBase/cards?assignedTo=$sellerId&sold=false');
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
                    Text('Cartillas asignadas sin vender (${cards.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    // Cargar cartillas asignadas sin vender para este usuario
    final r = await http.get(Uri.parse('$_apiBase/cards?assignedTo=$sellerId&sold=false'));
    List<Map<String, dynamic>> cards = [];
    if (r.statusCode < 300) {
      cards = List<Map<String, dynamic>>.from(json.decode(r.body));
    }

    String? selectedCardId = cards.isNotEmpty ? (cards.first['id'] as String) : null;
    final amountCtrl = TextEditingController(text: '20');

    final ok = await showDialog<bool>(context: context, builder: (_) {
      return AlertDialog(
        title: const Text('Registrar venta'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cards.isEmpty)
                const Text('No hay cartillas asignadas sin vender.'),
              if (cards.isNotEmpty) ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Cartillas asignadas disponibles:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Haz clic en el ícono de descarga para obtener la cartilla en PNG (720x1020)',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: Center(
                              child: Text(
                                card['cardNo']?.toString() ?? 'ID',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            'Cartilla ${card['cardNo'] ?? card['id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('ID: ${card['id']}'),
                          trailing: IconButton(
                            onPressed: () => _downloadCartilla(card),
                            icon: const Icon(Icons.download, color: Colors.blue),
                            tooltip: 'Descargar cartilla en PNG',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuración de venta:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cartilla seleccionada:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedCardId,
                        items: cards
                            .map((c) => DropdownMenuItem<String>(
                                  value: (c['id'] as String),
                                  child: Text('Cartilla ${c['cardNo'] ?? c['id']}'),
                                ))
                            .toList(),
                        onChanged: (v) => selectedCardId = v,
                        decoration: const InputDecoration(
                          labelText: 'Cartilla asignada',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Monto de venta:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Monto (Bs)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vender'),
            ),
        ],
      );
    });

    if (ok != true || selectedCardId == null) return;
    final resp = await http.post(
      Uri.parse('$_apiBase/sales'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({ 'cardId': selectedCardId, 'sellerId': sellerId, 'amount': double.tryParse(amountCtrl.text) ?? 20 }),
    );
    if (!mounted) return;
    if (resp.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta registrada')));
      setState(() { _refreshTick++; });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${resp.body}')));
    }
  }

  // Método para descargar cartilla en PNG con resolución optimizada (720x1020)
  Future<void> _downloadCartilla(Map<String, dynamic> card) async {
    try {
      // Crear un ScreenshotController para capturar la cartilla
      final screenshotController = ScreenshotController();
      
      // Crear un widget temporal con la cartilla para capturar
      final cartillaWidget = MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Container(
              width: 720, // Ancho optimizado para mejor calidad (720 píxeles)
              height: 1020, // Alto optimizado para mejor calidad (1020 píxeles)
              child: SingleChildScrollView(
                child: CartillaWidget(
                  numbers: _convertNumbersToIntList(card['numbers'] ?? []),
                  cardNumber: card['cardNo']?.toString() ?? card['id'],
                  date: DateTime.now().toString().split(' ')[0],
                  price: "Bs. 20",
                  compact: false,
                ),
              ),
            ),
          ),
        ),
      );
      
      // Capturar la cartilla con resolución optimizada
      final imageBytes = await screenshotController.captureFromWidget(
        cartillaWidget,
        context: context,
        delay: const Duration(milliseconds: 500),
        pixelRatio: 2.0, // Aumentar la densidad de píxeles para mejor calidad
      );
      
      if (imageBytes.isNotEmpty) {
        // Descargar la imagen
        await _saveImageToDevice(imageBytes, 'cartilla_${card['cardNo'] ?? card['id']}.png');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cartilla ${card['cardNo'] ?? card['id']} descargada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al capturar la cartilla'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      debugPrint('Error al guardar imagen: $e');
      rethrow;
    }
  }

  Future<void> _sellAllAssigned(String sellerId) async {
    final r = await http.get(Uri.parse('$_apiBase/cards?assignedTo=$sellerId&sold=false'));
    if (r.statusCode >= 300) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar cartillas: ${r.body}')));
      return;
    }
    final cards = List<Map<String, dynamic>>.from(json.decode(r.body));
    if (cards.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay cartillas asignadas sin vender.')));
      return;
    }
    final count = cards.length;
    final total = 20 * count;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar venta en lote'),
        content: Text('Se venderán $count cartillas por un total de $total Bs. ¿Confirmar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Vender todo')),
        ],
      ),
    );
    if (confirm != true) return;

    int ok = 0, fail = 0, done = 0;
    // Dialogo de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(builder: (context, setSt) {
          final progress = done / count;
          return AlertDialog(
            title: const Text('Procesando ventas...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress == 0 ? null : progress),
                const SizedBox(height: 8),
                Text('Completadas: $done / $count  •  OK: $ok  •  Error: $fail'),
              ],
            ),
          );
        });
      },
    );

    for (final c in cards) {
      final resp = await http.post(
        Uri.parse('$_apiBase/sales'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'cardId': c['id'], 'sellerId': sellerId, 'amount': 20}),
      );
      if (resp.statusCode < 300) {
        ok++;
      } else {
        fail++;
      }
      done++;
      if (mounted) {
        // Redibujar el diálogo con los nuevos valores
        setState(() {});
      }
    }
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ventas completadas: $ok ok, $fail error(es)')));
    setState(() { _refreshTick++; });
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
    final qp = <String>[];
    if (_from != null) qp.add('from=${DateTime(_from!.year, _from!.month, _from!.day).millisecondsSinceEpoch}');
    if (_to != null) qp.add('to=${DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59).millisecondsSinceEpoch}');
    if (_leaderId != null && _leaderId!.isNotEmpty) qp.add('leaderId=$_leaderId');
    final qs = qp.isEmpty ? '' : '?${qp.join('&')}';

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
      
      // Obtener conteo de cartillas asignadas para cada vendedor
      final vendors = List<Map<String, dynamic>>.from(data['vendors'] as List);
      for (final vendor in vendors) {
        final vendorId = vendor['vendorId'] ?? vendor['id'];
        try {
          final assignedResp = await http.get(Uri.parse('$_apiBase/cards?assignedTo=$vendorId'));
          if (assignedResp.statusCode < 300) {
            final assignedCards = List<Map<String, dynamic>>.from(json.decode(assignedResp.body));
            vendor['assignedCount'] = assignedCards.length;
          } else {
            vendor['assignedCount'] = 0;
          }
        } catch (e) {
          vendor['assignedCount'] = 0;
        }
      }
      
      // Obtener el total de cartillas del sistema
      try {
        final totalCardsResp = await http.get(Uri.parse('$_apiBase/cards'));
        if (totalCardsResp.statusCode < 300) {
          final allCards = List<Map<String, dynamic>>.from(json.decode(totalCardsResp.body));
          data['totalCards'] = allCards.length;
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

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_from ?? now) : (_to ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => isFrom ? _from = picked : _to = picked);
  }

  Future<void> _exportCsv(List<Map<String, dynamic>> vendors) async {
    final headers = ['Nombre', 'Rol', 'Vendidas', 'Ingresos(Bs)', 'Comisión(Bs)'];
    final rows = vendors.map((v) => [
      (v['name'] ?? '').toString(),
      (v['role'] ?? '').toString(),
      (v['soldCount'] ?? 0).toString(),
      (v['revenueBs'] ?? 0).toString(),
      (v['commissionsBs'] ?? 0).toString(),
    ]);
    final csv = StringBuffer()
      ..writeln(headers.join(','));
    for (final r in rows) {
      csv.writeln(r.map((c) => '"${c.replaceAll('"', '""')}"').join(','));
    }

    final bytes = utf8.encode(csv.toString());
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'reporte.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _createVendor({required bool isLeader}) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String? leaderId = _leaderId;
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
                decoration: const InputDecoration(labelText: 'Líder'),
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

    final body = {
      'name': nameController.text,
      'phone': phoneController.text,
      'role': isLeader ? 'LEADER' : 'SELLER',
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
      setState(() {});
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
    final vendor = vendorId != null 
        ? _vendorsAll.firstWhere(
            (v) => v['id'] == vendorId,
            orElse: () => {'name': 'Vendedor'},
          )
        : {'name': 'Todos los vendedores'};

    await showDialog(
      context: context,
      builder: (context) => BlockAssignmentModal(
        apiBase: _apiBase,
        vendorId: vendorId ?? '',
        vendorName: vendor['name'] ?? 'Vendedor',
        allVendors: _vendorsAll, // Pasar la lista completa de vendedores
        onSuccess: () {
          setState(() {});
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
      final body = <String, dynamic>{
        'vendorId': vendorId,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'Cartilla $cardNo',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
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
    try {
      // Cargar todas las cartillas asignadas a este vendedor
      final response = await http.get(Uri.parse('$_apiBase/cards?assignedTo=$vendorId'));
      
      if (!mounted) return;
      
      if (response.statusCode >= 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar cartillas: ${response.body}')),
        );
        return;
      }
      
      final cards = List<Map<String, dynamic>>.from(json.decode(response.body));
      
      if (cards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay cartillas asignadas a este vendedor')),
        );
        return;
      }
      
      // Mostrar diálogo con todas las cartillas asignadas
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
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
            child: Column(
              children: [
                Text(
                  'Total: ${cards.length} cartillas asignadas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                              'Haz clic en el botón rojo para eliminar cartillas individuales',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                                         SizedBox(width: 12),
                     ElevatedButton.icon(
                       onPressed: () => _downloadAllAssignedCards(cards, vendorId),
                       icon: Icon(Icons.download, color: Colors.white),
                       label: Text('Descargar Todas (${cards.length})'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.green,
                         foregroundColor: Colors.white,
                         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       ),
                     ),
                     SizedBox(width: 8),
                     ElevatedButton.icon(
                       onPressed: () => _deleteAllAssignedCards(cards, vendorId),
                       icon: Icon(Icons.delete_forever, color: Colors.white),
                       label: Text('Eliminar Todas (${cards.length})'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.red,
                         foregroundColor: Colors.white,
                         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       ),
                     ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final cardNumber = card['cardNo']?.toString() ?? card['id'];
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade200,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Botón de eliminación en la esquina superior derecha
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Tooltip(
                                message: 'Eliminar cartilla $cardNumber',
                                child: GestureDetector(
                                  onTap: () => _deleteIndividualCard(card, vendorId),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.shade300,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
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
                            // Contenido principal de la cartilla
                            GestureDetector(
                              onTap: () => _openCartilla(card),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      cardNumber,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Cartilla',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para abrir una cartilla específica
  Future<void> _openCartilla(Map<String, dynamic> card) async {
    try {
      // Cerrar el diálogo de cartillas asignadas
      Navigator.pop(context);
      
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
                        date: DateTime.now().toString().split(' ')[0],
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
    Future<void> load() async {
      final r = await http.get(Uri.parse('$_apiBase/cards?sold=false'));
      if (r.statusCode < 300) {
        cards = List<Map<String, dynamic>>.from(json.decode(r.body));
      }
    }
    await _load(withLeaders: true);
    await load();
    String? vendorId;
    await showDialog(context: context, builder: (_) {
      return StatefulBuilder(builder: (context, setSt) {
        return AlertDialog(
          title: const Text('Inventario de Cartillas (backend)'),
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
                      onPressed: () async { await load(); setSt(() {}); },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final c = cards[i];
                      return Card(
                        child: ListTile(
                          title: Text('Card ${c['id']}'),
                          subtitle: Text(c['assignedTo'] != null ? 'Asignada a: ${c['assignedTo']}' : 'Sin asignar'),
                          trailing: ElevatedButton(
                            onPressed: vendorId == null
                                ? null
                                : () async {
                                    final rr = await http.post(
                                      Uri.parse('$_apiBase/cards/${c['id']}/assign'), 
                                      headers: {'Content-Type': 'application/json'}, 
                                      body: json.encode({'vendorId': vendorId}),
                                    );
                                    if (rr.statusCode < 300) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asignada')));
                                      await load();
                                      setSt(() {});
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${rr.body}')));
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
                    '⚠️ Esta acción es IRREVERSIBLE',
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
            child: Text('ELIMINAR'),
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
        title: Text('Eliminando...'),
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
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Cartilla'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres eliminar la cartilla $cardNumber?',
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
                    '⚠️ Esta acción es IRREVERSIBLE',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• La cartilla se eliminará permanentemente del sistema'),
                  Text('• No se podrá recuperar'),
                  Text('• Se liberará el número para futuras asignaciones'),
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
            child: Text('ELIMINAR'),
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
        title: Text('Eliminando...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Eliminando cartilla $cardNumber...'),
          ],
        ),
      ),
    );

    try {
      // Llamar al endpoint de eliminación
      final response = await http.delete(
        Uri.parse('$_apiBase/cards/${card['id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      // Cerrar diálogo de progreso
      Navigator.pop(context);

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cartilla $cardNumber eliminada exitosamente'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM - Vendedores y Líderes'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            icon: const Icon(Icons.download),
            onPressed: () async {
              final data = await _load();
              final vendors = List<Map<String, dynamic>>.from(data['vendors'] as List);
              await _exportCsv(vendors);
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
              // Filtros
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                                         // Resumen de cartillas
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.grey.shade50,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.grey.shade300),
                       ),
                       child: Column(
                         children: [
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceAround,
                             children: [
                               _summaryStat('Total Cartillas', snap.data!['totalCards'] ?? 0),
                               _summaryStat('Total Vendidas', _getTotalSold(vendors)),
                               _summaryStat('Total Asignadas', _getTotalAssigned(vendors)),
                             ],
                           ),
                           const SizedBox(height: 16),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceAround,
                             children: [
                               _summaryStat('Sin Asignar', _getTotalUnassigned(vendors, snap.data!['totalCards'] ?? 0)),
                               _summaryStat('Disponibles', _getTotalAvailable(vendors)),
                             ],
                           ),
                         ],
                       ),
                     ),
                    const SizedBox(height: 16),
                    // Filtros existentes
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(_from == null ? 'Desde' : _df.format(_from!)),
                          onPressed: () async { await _pickDate(isFrom: true); setState(() {}); },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.date_range_outlined),
                          label: Text(_to == null ? 'Hasta' : _df.format(_to!)),
                          onPressed: () async { await _pickDate(isFrom: false); setState(() {}); },
                        ),
                        DropdownButton<String>(
                          value: _leaderId,
                          hint: const Text('Filtrar por líder'),
                          items: _leaders
                              .map((l) => DropdownMenuItem<String>(
                                    value: (l['id'] as String),
                                    child: Text(l['name'] as String),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _leaderId = v),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Aplicar'),
                        ),
                        const SizedBox(width: 12),
                        // Acciones rápidas
                        ElevatedButton.icon(
                          onPressed: () => _createVendor(isLeader: true),
                          icon: const Icon(Icons.star),
                          label: const Text('Nuevo Líder'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _createVendor(isLeader: false),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Nuevo Vendedor'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _assignCard,
                          icon: const Icon(Icons.assignment_ind),
                          label: const Text('Asignar Cartillas (Rango/Números)'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showInventoryDialog,
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Inventario'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _clearCommissions,
                          icon: const Icon(Icons.delete_forever, color: Colors.white),
                          label: const Text('ELIMINAR DATOS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Lista agrupada: líderes con sus vendedores debajo
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Mostrar líderes primero
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
                      return Card(
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Text((leader['name'] ?? '?').toString().substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(leader['name'] ?? '—'),
                          subtitle: const Text('Líder'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                                                     _stat(
                                     'Vendidas', 
                                     leader['soldCount'].toString(),
                                     assignedValue: (leader['assignedCount'] ?? 0).toString(),
                                     vendorId: leader['vendorId'] ?? leader['id'],
                                   ),
                                  _stat('Ingresos (Bs)', leader['revenueBs'].toString()),
                                  _stat('Comisión (Bs)', leader['commissionsBs'].toString()),
                                  ElevatedButton.icon(
                                    onPressed: () => _registerSaleDialog(leader['vendorId'] ?? leader['id']),
                                    icon: const Icon(Icons.point_of_sale),
                                    label: const Text('Vender'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _sellAllAssigned(leader['vendorId'] ?? leader['id']),
                                    icon: const Icon(Icons.sell_outlined),
                                    label: const Text('Vender todo'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _deleteVendor(leader),
                                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                                    label: const Text('Eliminar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (sellerObjs.isNotEmpty)
                              Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: const Text('Vendedores', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            // Vendedores del líder
                            ...sellerObjs.map((s) => ListTile(
                              contentPadding: const EdgeInsets.only(left: 24, right: 12),
                              leading: const Icon(Icons.person, color: Colors.blue),
                              title: Text(s['name'] ?? '—'),
                              subtitle: const Text('Vendedor'),
                              onTap: () => _showVendorDetail(s),
                              trailing: Wrap(
                                spacing: 12, 
                                crossAxisAlignment: WrapCrossAlignment.center, 
                                children: [
                                                                     _stat(
                                     'Vendidas', 
                                     (s['soldCount'] ?? 0).toString(),
                                     assignedValue: (s['assignedCount'] ?? 0).toString(),
                                     vendorId: s['vendorId'] ?? s['id'],
                                   ),
                                  _stat('Comisión (Bs)', (s['commissionsBs'] ?? 0).toString()),
                                  OutlinedButton.icon(
                                    onPressed: () => _reassignLeader(s),
                                    icon: const Icon(Icons.swap_horiz),
                                    label: const Text('Reasignar líder'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _registerSaleDialog(s['vendorId'] ?? s['id']),
                                    icon: const Icon(Icons.point_of_sale),
                                    label: const Text('Vender'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _sellAllAssigned(s['vendorId'] ?? s['id']),
                                    icon: const Icon(Icons.sell_outlined),
                                    label: const Text('Vender todo'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _deleteVendor(s),
                                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                                    label: const Text('Eliminar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      );
                    }),
                    // Mostrar vendedores sin líder (huérfanos) si existieran
                    ...vendors.where((v) => (v['role'] ?? '') != 'LEADER' && (v['leaderId'] == null || v['leaderId'] == '')).map((s) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text(s['name'] ?? '—'),
                        subtitle: const Text('Vendedor'),
                        onTap: () => _showVendorDetail(s),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _reassignLeader(s),
                              icon: const Icon(Icons.person_add_alt),
                              label: const Text('Asignar líder'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _deleteVendor(s),
                              icon: const Icon(Icons.delete_forever, color: Colors.white),
                              label: const Text('Eliminar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Métodos helper para calcular totales
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
        items.add(DropdownMenuItem<String>(
          value: seller['id'] as String,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text('👤 Vendedor: ${seller['name']}'),
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
        items.add(DropdownMenuItem<String>(
          value: seller['id'] as String,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text('👤 Vendedor: ${seller['name']}'),
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
      int successCount = 0;
      int errorCount = 0;
      
      // Crear un ScreenshotController para capturar las cartillas con resolución optimizada
      final screenshotController = ScreenshotController();
      
      for (int i = 0; i < cards.length; i++) {
        final card = cards[i];
        final cardNumber = card['cardNo']?.toString() ?? card['id'];
        
        try {
          // Crear un widget temporal con la cartilla para capturar
          final cartillaWidget = MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Container(
                  width: 720, // Ancho optimizado para mejor calidad (720 píxeles)
                  height: 1020, // Alto optimizado para mejor calidad (1020 píxeles)
                  child: SingleChildScrollView(
                    child: CartillaWidget(
                      numbers: _convertNumbersToIntList(card['numbers'] ?? []),
                      cardNumber: cardNumber,
                      date: DateTime.now().toString().split(' ')[0],
                      price: "Bs. 20",
                      compact: false,
                    ),
                  ),
                ),
              ),
            ),
          );
          
          // Capturar la cartilla con resolución optimizada
          final imageBytes = await screenshotController.captureFromWidget(
            cartillaWidget,
            context: context,
            delay: const Duration(milliseconds: 300),
            pixelRatio: 2.0, // Aumentar la densidad de píxeles para mejor calidad
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
          content: Text('No hay cartillas para eliminar'),
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
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('ELIMINAR TODAS LAS CARTILLAS'),
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
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '¿Estás seguro de que quieres eliminar TODAS las ${cards.length} cartillas asignadas?',
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
                  Text('• Se ELIMINARÁN PERMANENTEMENTE ${cards.length} cartillas'),
                  Text('• NO se podrán recuperar'),
                  Text('• Los números quedarán disponibles para futuras asignaciones'),
                  Text('• Se liberará todo el inventario del vendedor/líder'),
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
                      'Esta operación es útil para limpiar completamente el inventario de un vendedor o líder.',
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
            child: Text('ELIMINAR TODAS'),
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
        title: Text('ELIMINANDO CARTILLAS...'),
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
              'Eliminadas: 0 / $total',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Eliminando cartilla 1 de $total...',
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
          // Llamar al endpoint de eliminación
          final response = await http.delete(
            Uri.parse('$_apiBase/cards/${card['id']}'),
            headers: {'Content-Type': 'application/json'},
          );
          
          if (response.statusCode == 200) {
            successCount++;
          } else {
            errorCount++;
            debugPrint('Error eliminando cartilla $cardNumber: ${response.body}');
          }
          
          // Actualizar progreso
          if (mounted) {
            // Cerrar diálogo anterior y mostrar uno nuevo con progreso actualizado
            Navigator.pop(context);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text('ELIMINANDO CARTILLAS...'),
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
                      'Eliminadas: ${i + 1} / $total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Eliminando cartilla ${i + 2 > total ? total : i + 2} de $total...',
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
          debugPrint('Error eliminando cartilla $cardNumber: $e');
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
                Text('Eliminación Completada'),
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
                        'Resumen de Eliminación:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('• Total de cartillas: $total'),
                      Text(
                        '• Eliminadas exitosamente: $successCount',
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
                            'El inventario ha sido limpiado completamente. Los números de cartilla están disponibles para futuras asignaciones.',
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
}
