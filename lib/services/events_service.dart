import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../config/backend_config.dart';

/// Servicio para gestionar eventos de Bingo
class EventsService {
  static String get _eventsEndpoint => '${BackendConfig.apiBase}/events';

  /// Crear un nuevo evento
  Future<BingoEvent> createEvent({
    required String name,
    required String date,
    String? description,
    EventStatus status = EventStatus.upcoming,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_eventsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'date': date,
          'description': description,
          'status': status.toJson(),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        print('✅ Evento creado: $name');
        return BingoEvent.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception('Error creando evento: ${error['error']}');
      }
    } catch (e) {
      print('❌ Error en createEvent: $e');
      rethrow;
    }
  }

  /// Obtener todos los eventos
  Future<List<BingoEvent>> getEvents({EventStatus? status}) async {
    try {
      var uri = Uri.parse(_eventsEndpoint);
      
      if (status != null) {
        uri = uri.replace(queryParameters: {'status': status.toJson()});
      }

      final response = await http.get(uri);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = json.decode(response.body);
        final events = data.map((e) => BingoEvent.fromJson(e)).toList();
        print('📋 ${events.length} evento(s) recuperado(s)');
        return events;
      } else {
        throw Exception('Error obteniendo eventos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getEvents: $e');
      rethrow;
    }
  }

  /// Obtener un evento específico por ID
  Future<BingoEvent> getEventById(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$_eventsEndpoint/$eventId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BingoEvent.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Evento no encontrado');
      } else {
        throw Exception('Error obteniendo evento: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getEventById: $e');
      rethrow;
    }
  }

  /// Actualizar un evento
  Future<BingoEvent> updateEvent(String eventId, {
    String? name,
    String? date,
    String? description,
    EventStatus? status,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (date != null) body['date'] = date;
      if (description != null) body['description'] = description;
      if (status != null) body['status'] = status.toJson();

      final response = await http.put(
        Uri.parse('$_eventsEndpoint/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        print('✅ Evento actualizado: $eventId');
        return BingoEvent.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception('Error actualizando evento: ${error['error']}');
      }
    } catch (e) {
      print('❌ Error en updateEvent: $e');
      rethrow;
    }
  }

  /// Eliminar un evento
  Future<void> deleteEvent(String eventId, {bool deleteCards = false}) async {
    try {
      var uri = Uri.parse('$_eventsEndpoint/$eventId');
      
      if (deleteCards) {
        uri = uri.replace(queryParameters: {'deleteCards': 'true'});
      }

      final response = await http.delete(uri);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('🗑️ Evento eliminado: $eventId');
      } else {
        final error = json.decode(response.body);
        throw Exception('Error eliminando evento: ${error['error']}');
      }
    } catch (e) {
      print('❌ Error en deleteEvent: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas de un evento
  Future<Map<String, dynamic>> getEventStats(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$_eventsEndpoint/$eventId/stats'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error obteniendo estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getEventStats: $e');
      rethrow;
    }
  }

  /// Obtener eventos activos
  Future<List<BingoEvent>> getActiveEvents() async {
    return getEvents(status: EventStatus.active);
  }

  /// Obtener eventos próximos
  Future<List<BingoEvent>> getUpcomingEvents() async {
    return getEvents(status: EventStatus.upcoming);
  }

  /// Obtener eventos completados
  Future<List<BingoEvent>> getCompletedEvents() async {
    return getEvents(status: EventStatus.completed);
  }
}
