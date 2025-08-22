# Endpoint: Obtener Bloques Ya Asignados

## Descripción
Este endpoint permite obtener la lista de cartillas ya asignadas para calcular qué bloques están ocupados y no pueden ser reasignados.

## Endpoint
```
GET /cards/assigned-blocks
```

## Parámetros
Ninguno (se obtienen todas las cartillas asignadas)

## Respuesta Exitosa (200)
```json
{
  "success": true,
  "assignedCards": [
    {
      "id": "card_id_1",
      "cardNo": 5,
      "vendorId": "vendor_id_1",
      "vendorName": "Eduardo Líder",
      "assignedAt": "2024-01-15T10:30:00Z"
    },
    {
      "id": "card_id_2", 
      "cardNo": 6,
      "vendorId": "vendor_id_1",
      "vendorName": "Eduardo Líder",
      "assignedAt": "2024-01-15T10:30:00Z"
    }
  ],
  "totalAssigned": 2
}
```

## Respuesta de Error (400/500)
```json
{
  "success": false,
  "error": "Mensaje de error"
}
```

## Implementación en Backend

### Firebase Functions
```typescript
// En lib/routes/cards.ts
export const getAssignedBlocks = functions.https.onRequest(async (req, res) => {
  try {
    const cardsRef = db.collection('cards');
    const snapshot = await cardsRef
      .where('assignedTo', '!=', null)
      .get();

    const assignedCards = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({
      success: true,
      assignedCards,
      totalAssigned: assignedCards.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
```

### Express/Node.js
```javascript
// En routes/cards.js
app.get('/cards/assigned-blocks', async (req, res) => {
  try {
    const assignedCards = await Card.find({ assignedTo: { $exists: true } });
    
    res.json({
      success: true,
      assignedCards,
      totalAssigned: assignedCards.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
```

## Uso en el Sistema de Bloques

### 1. Consulta de Bloques Disponibles
- El sistema consulta este endpoint antes de hacer una asignación
- Calcula qué bloques están ocupados basándose en las cartillas asignadas
- Excluye esos bloques del conteo de bloques disponibles

### 2. Validación de Disponibilidad
- Verifica que haya suficientes bloques libres para la asignación solicitada
- Muestra error si no hay suficientes bloques disponibles

### 3. Selección de Bloques
- Solo selecciona bloques que no estén ocupados
- Mantiene la funcionalidad de selección aleatoria
- Garantiza que no se asignen bloques duplicados

## Beneficios

1. **Prevención de Duplicados**: Evita asignar cartillas que ya están asignadas
2. **Conteo Real**: Muestra la cantidad real de bloques disponibles
3. **Transparencia**: El usuario ve exactamente cuántos bloques puede asignar
4. **Eficiencia**: No se desperdician intentos de asignación fallidos

## Notas de Implementación

- **Performance**: Considerar índices en la base de datos para consultas eficientes
- **Cache**: Implementar cache para consultas frecuentes
- **Paginación**: Para sistemas con muchas cartillas, considerar paginación
- **Filtros**: Permitir filtros por fecha, vendedor, etc. si es necesario
