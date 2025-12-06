# Cambios Necesarios en cards.ts

Debido a problemas con los line endings del archivo `backend/src/routes/cards.ts`, aquí están los cambios manuales que debes hacer:

## 1. Actualizar la interfaz CardDoc (línea 5-14)

```typescript
interface CardDoc {
  id: string;
  numbers?: number[][]; // 5x5 (returned by API)
  numbersFlat?: number[]; // stored in Firestore
  gridSize?: number; // default 5
  eventId: string; // FK to event - AGREGAR ESTA LÍNEA
  assignedTo?: string; // vendorId
  sold: boolean;
  createdAt: number;
  cardNo?: number; // Número secuencial de cartilla
}
```

## 2. Actualizar createCardSchema (línea 16-19)

```typescript
const createCardSchema = z.object({
  numbers: z.array(z.array(z.number())),
  eventId: z.string().min(1, 'eventId es requerido'), // AGREGAR ESTA LÍNEA
  cardNo: z.number().int().positive().optional(),
});
```

## 3. Actualizar POST / (línea 82-88)

En la línea 84, después de `gridSize: parsed.numbers.length,` agregar:

```typescript
eventId: parsed.eventId,
```

## 4. Actualizar GET / (línea 118)

Cambiar:
```typescript
const { assignedTo, sold, limit } = _req.query as { assignedTo?: string; sold?: string; limit?: string };
```

Por:
```typescript
const { assignedTo, sold, limit, eventId } = _req.query as { assignedTo?: string; sold?: string; limit?: string; eventId?: string };
```

## 5. Agregar filtro por eventId (después de línea 119)

Después de `let q = db.collection('cards') as any;` agregar:

```typescript
if (eventId) q = q.where('eventId', '==', eventId);
```

## 6. Incluir eventId en la respuesta GET (línea 133-140)

En el return object, después de `numbers,` agregar:

```typescript
eventId: data.eventId ?? null,
```

## 7. Actualizar el endpoint /generate (línea 387-394)

En el objeto dataToSave, después de `gridSize: 5,` agregar:

```typescript
eventId: eventId,
```

Y al inicio de la función (después de línea 314), extraer eventId del body:

```typescript
const { count = 1, eventId } = req.body as { count?: number; eventId: string };

// Validar que eventId exista
if (!eventId) {
  return res.status(400).json({ 
    error: 'eventId es requerido' 
  });
}
```

## 8. Actualizar DELETE /clear (línea 431)

Agregar soporte para eliminar solo cartillas de un evento:

Después de línea 432, agregar:

```typescript
const { eventId } = _req.query as { eventId?: string };
```

Y cambiar la query (línea 436):

```typescript
let cardsQuery = db.collection('cards');
if (eventId) {
  cardsQuery = cardsQuery.where('eventId', '==', eventId) as any;
}
const allCards = await cardsQuery.get();
```

---

**Nota**: Una vez realizados estos cambios, el backend estará listo para manejar la asociación de cartillas con eventos.
