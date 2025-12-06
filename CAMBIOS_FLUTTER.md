# Cambios Necesarios en Flutter

## lib/models/firebase_cartilla.dart

### 1. Agregar campo eventId (línea 6)

Después de `final List<List<int>> numbers;` agregar:

```dart
final String eventId; // NUEVO - FK al evento
```

### 2. Actualizar constructor (línea 13)

Después de `required this.numbers,` agregar:

```dart
required this.eventId, // NUEVO
```

### 3. Actualizar fromJson (línea 60)

Después de `numbers: numbers,` agregar:

```dart
eventId: json['eventId'] as String? ?? '', // NUEVO
```

### 4. Actualizar toJson (línea 81)

Después de `'numbers': numbers,` agregar:

```dart
'eventId': eventId, // NUEVO
```

---

## lib/models/firebase_bingo_game.dart

### Agregar campo eventId (línea 6)

Después de `final String id;` agregar:

```dart
final String eventId; // NUEVO - FK al evento
```

### Actualizar constructor (línea 15)

Después de `required this.id,` agregar:

```dart
required this.eventId,
```

### Actualizar todos los factory methods para incluir eventId

---

## lib/services/cartillas_service.dart

### 1. Actualizar getCartillas() para filtrar por eventId

```dart
Future<List<FirebaseCartilla>> getCartillas({String? eventId}) async {
  final queryParams = <String, String>{};
  if (eventId != null) {
    queryParams['eventId'] = eventId;
  }
  
  final uri = Uri.parse(BackendConfig.cardsUrl).replace(queryParameters: queryParams);
  // ...resto del código
}
```

### 2. Actualizar generateCartillas() para incluir eventId

```dart
Future<List<FirebaseCartilla>> generateCartillas(int count, String eventId) async {
  final response = await http.post(
    Uri.parse('${BackendConfig.apiBase}/cards/generate'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'count': count,
      'eventId': eventId, // NUEVO
    }),
  );
  // ...resto del código
}
```

---

## lib/services/bingo_games_service.dart

### Actualizar para usar eventos

Cambiar todos los paths de:
- `bingo_games` → `events/{eventId}/games`

Ejemplo:

```dart
Future<String> saveBingoGame(String eventId, FirebaseBingoGame game) async {
  try {
    final docRef = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('games')
        .doc(game.id)
        .set(game.toFirestore());
    // ...
  }
}
```

---

## Nuevos Widgets Necesarios

### lib/widgets/event_selector_widget.dart (NUEVO)

Widget para seleccionar el evento activo:

```dart
class EventSelectorWidget extends StatelessWidget {
  final String? selectedEventId;
  final ValueChanged<String?> onEventChanged;
  final bool showCreateButton;
  
  // ... implementación
}
```

---

## Actualizar Screens

### lib/screens/crm_screen.dart

Agregar selector de evento en la parte superior y filtrar cartillas por `eventId`.

```dart
// En el build:
Column(
  children: [
    EventSelectorWidget(
      selectedEventId: _selectedEventId,
      onEventChanged: (eventId) {
        setState(() {
          _selectedEventId = eventId;
        });
        _loadCartillas();
      },
    ),
    // ... resto de la UI
  ],
)
```

---

## Resumen de Cambios

1. ✅ Modelo `BingoEvent` creado
2. ✅ `EventsService` creado
3. ⚠️ `FirebaseCartilla` - agregar campo `eventId`
4. ⚠️ `FirebaseBingoGame` - agregar campo `eventId`
5. ⚠️ `CartillasService` - actualizar para usar `eventId`
6. ⚠️ `BingoGamesService` - actualizar para usar subcollections
7. ⚠️ Crear `EventSelectorWidget`
8. ⚠️ Actualizar `CrmScreen` y otras pantallas
