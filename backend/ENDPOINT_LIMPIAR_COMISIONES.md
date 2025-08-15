# Endpoint para ELIMINAR TODOS LOS DATOS

## Descripción
Este endpoint permite **ELIMINAR COMPLETAMENTE** todos los datos de las colecciones `sales` y `balances` de la base de datos Firestore.

🚨 **ADVERTENCIA CRÍTICA**: Esta operación es **IRREVERSIBLE** y eliminará permanentemente todos los datos.

## URL
```
POST /api/reports/clear-commissions
```

## Parámetros del Body
```json
{
  "confirm": "ELIMINAR_DATOS_2024",
  "dryRun": false
}
```

### Parámetros:
- **confirm** (requerido): Debe ser exactamente "ELIMINAR_DATOS_2024" para confirmar la operación
- **dryRun** (opcional): Si es `true`, solo muestra qué se haría sin realizar cambios reales. Por defecto es `false`

## Funcionalidad

### 1. ELIMINACIÓN COMPLETA en Sales
- **ELIMINA TODAS** las ventas de la colección `sales`
- No se preserva ningún dato de ventas
- Todas las transacciones se pierden permanentemente

### 2. ELIMINACIÓN COMPLETA en Balances
- **ELIMINA TODOS** los registros de la colección `balances`
- No se preserva ningún dato de balance
- Todos los registros financieros se pierden permanentemente

## Ejemplos de Uso

### Modo Dry Run (Recomendado para pruebas)
```bash
curl -X POST http://localhost:4001/api/reports/clear-commissions \
  -H "Content-Type: application/json" \
  -d '{
    "confirm": "ELIMINAR_DATOS_2024",
    "dryRun": true
  }'
```

### Ejecución Real
```bash
curl -X POST http://localhost:4001/api/reports/clear-commissions \
  -H "Content-Type: application/json" \
  -d '{
    "confirm": "ELIMINAR_DATOS_2024",
    "dryRun": false
  }'
```

## Respuestas

### Respuesta Exitosa (Dry Run)
```json
{
  "message": "DRY RUN - Solo simulación de eliminación",
  "warning": "⚠️ ESTA OPERACIÓN ELIMINARÁ PERMANENTEMENTE TODOS LOS DATOS",
  "summary": {
    "salesToDelete": 150,
    "balancesToDelete": 300,
    "totalRecordsToDelete": 450,
    "timestamp": 1754796966111
  }
}
```

### Respuesta Exitosa (Ejecución Real)
```json
{
  "message": "TODOS LOS DATOS ELIMINADOS EXITOSAMENTE",
  "warning": "⚠️ Esta operación es IRREVERSIBLE",
  "summary": {
    "salesDeleted": 150,
    "balancesDeleted": 300,
    "totalRecordsDeleted": 450,
    "timestamp": 1754796966111
  }
}
```

### Error de Confirmación
```json
{
  "error": "Se requiere confirmación. Envía confirm: \"ELIMINAR_DATOS_2024\" para proceder."
}
```

## Seguridad
- Requiere confirmación explícita con el valor exacto "ELIMINAR_DATOS_2024"
- Usa transacciones de Firestore para garantizar consistencia
- Incluye logging detallado para auditoría

## Consideraciones Importantes
🚨 **ADVERTENCIA CRÍTICA**: Esta operación es **IRREVERSIBLE**. Una vez ejecutada, **TODOS LOS DATOS** se perderán permanentemente.

### Antes de ejecutar:
1. **HACER BACKUP COMPLETO** de la base de datos
2. Usar primero el modo `dryRun: true` para verificar qué se va a eliminar
3. Verificar que no haya operaciones en curso
4. Coordinar con el equipo para evitar interrupciones
5. **CONFIRMAR** que realmente se quieren eliminar todos los datos

### Después de ejecutar:
1. Verificar que los datos se hayan eliminado correctamente
2. Revisar los logs del servidor
3. Actualizar cualquier sistema externo que dependa de estos datos
4. **RECORDAR** que los datos no se pueden recuperar

## Logs del Servidor
El endpoint genera logs detallados en la consola del servidor:
```
Iniciando ELIMINACIÓN COMPLETA de datos. Modo dry run: false
Encontrados 150 ventas y 300 balances para ELIMINAR COMPLETAMENTE
🚨 INICIANDO ELIMINACIÓN PERMANENTE DE TODOS LOS DATOS...
✅ ELIMINACIÓN COMPLETA DE DATOS COMPLETADA EXITOSAMENTE
```

## Códigos de Estado HTTP
- **200**: Operación exitosa
- **400**: Error de confirmación o parámetros inválidos
- **500**: Error interno del servidor

## ⚠️ ADVERTENCIAS FINALES

**ESTA OPERACIÓN:**
- Elimina **TODOS** los datos de ventas
- Elimina **TODOS** los datos de balances
- Es **COMPLETAMENTE IRREVERSIBLE**
- No se puede deshacer
- Requiere confirmación explícita
- Debe usarse con extrema precaución

**SOLO EJECUTAR** si estás **100% SEGURO** de que quieres eliminar todos los datos.
