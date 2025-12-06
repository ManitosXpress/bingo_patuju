import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/events_service.dart';

/// Widget para seleccionar el evento activo
class EventSelectorWidget extends StatefulWidget {
  final String? selectedEventId;
  final ValueChanged<String?> onEventChanged;
  final bool showCreateButton;
  final bool showAllOption;

  const EventSelectorWidget({
    Key? key,
    this.selectedEventId,
    required this.onEventChanged,
    this.showCreateButton = true,
    this.showAllOption = false,
  }) : super(key: key);

  @override
  State<EventSelectorWidget> createState() => _EventSelectorWidgetState();
}

class _EventSelectorWidgetState extends State<EventSelectorWidget> {
  final EventsService _eventsService = EventsService();
  List<BingoEvent> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final events = await _eventsService.getEvents();
      setState(() {
        _events = events;
        _loading = false;
      });

      // Si no hay evento seleccionado, seleccionar el primero activo o el primero disponible
      if (widget.selectedEventId == null && _events.isNotEmpty) {
        final activeEvent = _events.firstWhere(
          (e) => e.status == EventStatus.active,
          orElse: () => _events.first,
        );
        widget.onEventChanged(activeEvent.id);
      }
    } catch (e) {
      setState(() {
        _error = 'Error cargando eventos: $e';
        _loading = false;
      });
    }
  }

  Future<void> _showCreateEventDialog() async {
    final nameController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final descriptionController = TextEditingController();
    EventStatus selectedStatus = EventStatus.active;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crear Nuevo Evento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Evento',
                    hintText: 'Ej: Bingo del Lunes',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha (YYYY-MM-DD)',
                    hintText: '2025-12-10',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EventStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: EventStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedStatus = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es requerido')),
                  );
                  return;
                }

                try {
                  final event = await _eventsService.createEvent(
                    name: nameController.text,
                    date: dateController.text,
                    description: descriptionController.text.isEmpty ? null : descriptionController.text,
                    status: selectedStatus,
                  );

                  if (mounted) {
                    Navigator.pop(context, true);
                    widget.onEventChanged(event.id);
                    _loadEvents();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Evento creado exitosamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Cargando eventos...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(child: Text(_error!)),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadEvents,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            const Icon(Icons.event, color: Colors.blue),
            const SizedBox(width: 12),
            const Text(
              'Evento:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String?>(
                value: widget.selectedEventId,
                isExpanded: true,
                hint: const Text('Seleccionar evento'),
                items: [
                  if (widget.showAllOption)
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos los eventos'),
                    ),
                  ..._events.map((event) {
                    return DropdownMenuItem<String?>(
                      value: event.id,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: event.status == EventStatus.active
                                  ? Colors.green
                                  : event.status == EventStatus.upcoming
                                      ? Colors.orange
                                      : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${event.name} (${event.formattedDate})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: widget.onEventChanged,
              ),
            ),
            if (widget.showCreateButton) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: 'Crear nuevo evento',
                onPressed: _showCreateEventDialog,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recargar eventos',
              onPressed: _loadEvents,
            ),
          ],
        ),
      ),
    );
  }
}
