import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';

/// Servicio para subir archivos a Firebase Storage.
/// Implementa el patrón "Upload & Link" para compartir PDFs vía WhatsApp.
/// 
/// En Flutter Web, usa el backend para subir (más confiable).
/// En otras plataformas, usa Firebase Storage directamente.
class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube un PDF de cartilla a Firebase Storage y retorna la URL de descarga.
  /// 
  /// [bytes] - Los bytes del PDF generado.
  /// [cartillaId] - ID único de la cartilla.
  /// [vendorId] - ID del vendedor al que se envía.
  /// 
  /// Returns: URL pública de descarga del PDF.
  static Future<String> uploadCartillaPdf({
    required Uint8List bytes,
    required String cartillaId,
    required String vendorId,
  }) async {
    // En Web, usar el backend para evitar problemas de interoperabilidad JS
    if (kIsWeb) {
      return _uploadViaBackend(
        bytes: bytes,
        vendorId: vendorId,
        fileName: '${cartillaId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    }
    
    // En otras plataformas, usar Firebase Storage directamente
    return _uploadDirectly(
      bytes: bytes,
      path: 'cartillas_enviadas/$vendorId/${cartillaId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      metadata: {
        'vendorId': vendorId,
        'cartillaId': cartillaId,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Sube múltiples cartillas como un solo PDF consolidado.
  static Future<String> uploadMultipleCartillasPdf({
    required Uint8List bytes,
    required String vendorId,
    required String vendorName,
    required String eventDate,
  }) async {
    final String safeName = vendorName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String fileName = 'reporte_${eventDate}_$timestamp.pdf';
    
    // En Web, usar el backend para evitar problemas de interoperabilidad JS
    if (kIsWeb) {
      return _uploadViaBackend(
        bytes: bytes,
        vendorId: vendorId,
        fileName: fileName,
        metadata: {
          'vendorName': safeName,
          'eventDate': eventDate,
          'type': 'assigned_cards_report',
        },
      );
    }
    
    // En otras plataformas, usar Firebase Storage directamente
    return _uploadDirectly(
      bytes: bytes,
      path: 'cartillas_enviadas/$vendorId/$fileName',
      metadata: {
        'vendorId': vendorId,
        'vendorName': safeName,
        'eventDate': eventDate,
        'type': 'assigned_cards_report',
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Subida directa a Firebase Storage (para plataformas móviles/desktop).
  static Future<String> _uploadDirectly({
    required Uint8List bytes,
    required String path,
    required Map<String, String> metadata,
  }) async {
    try {
      final Reference ref = _storage.ref().child(path);
      
      final SettableMetadata settableMetadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: metadata,
      );
      
      final UploadTask uploadTask = ref.putData(bytes, settableMetadata);
      final TaskSnapshot snapshot = await uploadTask;
      
      if (kDebugMode) {
        print('📤 PDF subido exitosamente: ${snapshot.bytesTransferred} bytes');
      }
      
      final String downloadUrl = await ref.getDownloadURL();
      
      if (kDebugMode) {
        print('🔗 URL de descarga: $downloadUrl');
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('❌ Error de Firebase Storage: ${e.code} - ${e.message}');
      }
      throw Exception('Error al subir PDF: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inesperado al subir PDF: $e');
      }
      throw Exception('Error inesperado al subir PDF: $e');
    }
  }

  /// Subida a través del backend (para Flutter Web).
  /// Envía el PDF como base64 al backend, que lo sube a Storage.
  static Future<String> _uploadViaBackend({
    required Uint8List bytes,
    required String vendorId,
    required String fileName,
    Map<String, String>? metadata,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Subiendo PDF via backend (${bytes.length} bytes)...');
      }
      
      final String base64Pdf = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse('${BackendConfig.apiBase}/reports/upload-pdf'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'pdfBase64': base64Pdf,
          'vendorId': vendorId,
          'fileName': fileName,
          'metadata': metadata ?? {},
        }),
      ).timeout(const Duration(seconds: 60));
      
      if (response.statusCode >= 300) {
        throw Exception('Error del servidor: ${response.body}');
      }
      
      final data = json.decode(response.body);
      final String? url = data['url'];
      
      if (url == null) {
        throw Exception('No se recibió la URL del PDF');
      }
      
      if (kDebugMode) {
        print('✅ PDF subido via backend: $url');
      }
      
      return url;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al subir via backend: $e');
      }
      throw Exception('Error al subir PDF: $e');
    }
  }

  /// Elimina un archivo de Storage por su URL.
  static Future<void> deleteByUrl(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
      if (kDebugMode) {
        print('🗑️ Archivo eliminado de Storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error al eliminar archivo: $e');
      }
    }
  }
}
