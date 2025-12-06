# Guía de Integración - EventSelectorWidget en Pantallas

## CRM Screen - ✅ COMPLETADO

El `CrmScreen` ya ha sido actualizado con la integración completa del `EventSelectorWidget`:

```dart
// En lib/screens/crm_screen.dart
EventSelectorWidget(
  selectedEventId: _selectedEventId,
  onEventChanged: _onEventChanged,
  showCreateButton: true,
  showAllOption: false,
),
```

**Funcionalidad implementada:**
- Selector de eventos en la parte superior
- Filtrado automático de cartillas por `eventId`
- Banner informativo cuando no hay evento seleccionado
- Carga automática de cartillas al cambiar de evento

---

## Bingo Game Screen - Integración Recomendada

Para `bingo_game_screen.dart`, agregar el selector en el panel de juegos:

### 1. Agregar estado para evento seleccionado

```dart
class _BingoGameScreenState extends State<BingoGameScreen> {
  String? _selectedEventId;
  // ... resto del código
}
```

### 2. Integrar en BingoGamesPanel

El `BingoGamesPanel` debería incluir:

```dart
// En lib/widgets/bingo_games_panel.dart (al inicio del build)
Column(
  children: [
    EventSelectorWidget(
      selectedEventId: widget.selectedEventId,
      onEventChanged: widget.onEventChanged,
      showCreateButton: false,  // No crear desde aquí
      showAllOption: false,
    ),
    const Divider(),
    // ... resto del panel de juegos
  ],
)
```

### 3. Cargar juegos filtrados por evento

```dart
Future<void> _loadGames() async {
  if (_selectedEventId == null) return;
  
  final gamesService = BingoGamesService();
  final games = await gamesService.getEventGames(_selectedEventId!);
  
  setState(() {
    _games = games;
  });
}
```

---

## Otras Pantallas a Considerar

### Cartillas Screen (si existe)
Debería tener el mismo patrón que CRM:
- Selector de evento
- Filtrado automático
- Generación de cartillas requiere eventId

### Reports Screen
Mostrar reportes filtrados por evento:
- Estadísticas por evento
- Ventas por evento
- Comisiones por evento

---

## Patrón de Implementación General

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  String? _selectedEventId;
  
  void _onEventChanged(String? eventId) {
    setState(() {
      _selectedEventId = eventId;
    });
    _loadData(); // Recargar datos con el nuevo filtro
  }
  
  Future<void> _loadData() async {
    if (_selectedEventId == null) return;
    
    // Cargar datos filtrados por eventId
    final data = await myService.getData(eventId: _selectedEventId);
    
    setState(() {
      // Actualizar estado
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          EventSelectorWidget(
            selectedEventId: _selectedEventId,
            onEventChanged: _onEventChanged,
          ),
          // ... resto de la UI
        ],
      ),
    );
  }
}
```

---

## Verificación de integración

✅ Event models creados
✅ Event services funcionando
✅ EventSelectorWidget completo
✅ CRMScreen integrado
⏳ BingoGameScreen (pendiente - opcional)
⏳ Otras pantallas según necesidad

---

## Próximos Pasos

1. **Probar la integración actual**
   - Crear un evento desde el selector
   - Generar cartillas para ese evento
   - Verificar filtrado en CRM

2. **Integrar en pantallas adicionales** (opcional)
   - BingoGamesPanel
   - Cartillas management
   - Reports

3. **Testing end-to-end**
   - Crear evento
   -Generate cartillas
   - Asignar a vendedores
   - Crear juegos/rondas
   - Verificar separación por eventos
