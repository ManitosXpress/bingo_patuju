# Backend BINGO BAITTY

Backend para la aplicación de Bingo con gestión de ventas, comisiones y reportes.

## Características

- **Gestión de Vendedores**: CRUD completo para vendedores y líderes
- **Gestión de Cartillas**: Sistema de cartillas de bingo
- **Ventas**: Registro de ventas con cálculo automático de comisiones
- **Reportes**: Generación de reportes de ventas y comisiones
- **Limpieza de Comisiones**: Endpoint para limpiar comisiones históricas

## Instalación

```bash
npm install
```

## Configuración

1. Configurar las credenciales de Firebase Admin SDK
2. Establecer la variable de entorno `GOOGLE_APPLICATION_CREDENTIALS_JSON` con el contenido del archivo JSON de servicio

## Ejecución

### Desarrollo
```bash
npm run dev
```

### Producción
```bash
npm run build
npm start
```

## Endpoints Disponibles

### Vendedores
- `GET /api/vendors` - Listar vendedores
- `POST /api/vendors` - Crear vendedor
- `PUT /api/vendors/:id` - Actualizar vendedor
- `DELETE /api/vendors/:id` - Eliminar vendedor

### Cartillas
- `GET /api/cards` - Listar cartillas
- `POST /api/cards` - Crear cartilla
- `PUT /api/cards/:id` - Actualizar cartilla
- `DELETE /api/cards/:id` - Eliminar cartilla

### Ventas
- `GET /api/sales` - Listar ventas (con filtros opcionales)
- `POST /api/sales` - Crear venta

### Reportes
- `GET /api/reports/vendors-summary` - Resumen de vendedores y comisiones
- `POST /api/reports/clear-commissions` - **NUEVO**: Limpiar comisiones históricas

## Nuevo Endpoint: Limpieza de Comisiones

### Descripción
El endpoint `POST /api/reports/clear-commissions` permite limpiar todas las comisiones históricas en las colecciones `sales` y `balances`.

### Uso
```bash
# Modo dry run (recomendado para pruebas)
curl -X POST http://localhost:4001/api/reports/clear-commissions \
  -H "Content-Type: application/json" \
  -d '{
    "confirm": "LIMPIAR_COMISIONES_2024",
    "dryRun": true
  }'

# Ejecución real
curl -X POST http://localhost:4001/api/reports/clear-commissions \
  -H "Content-Type: application/json" \
  -d '{
    "confirm": "LIMPIAR_COMISIONES_2024",
    "dryRun": false
  }'
```

### Scripts de PowerShell
- `clear-commissions.ps1` - Script para ejecutar la limpieza de comisiones
- `start.ps1` - Iniciar servidor en puerto 4001
- `start-40001.ps1` - Iniciar servidor en puerto 40001

### Documentación Completa
Ver `ENDPOINT_LIMPIAR_COMISIONES.md` para documentación detallada del endpoint.

## Estructura de Datos

### Sales
```typescript
{
  cardId: string;
  sellerId: string;
  leaderId: string | null;
  amount: number;
  commissions: {
    seller: number;
    leader: number;
  };
  createdAt: number;
}
```

### Balances
```typescript
{
  vendorId: string;
  type: 'COMMISSION' | 'SALE' | 'OTHER';
  amount: number;
  source: string;
  createdAt: number;
}
```

## Seguridad

- Todas las operaciones críticas requieren confirmación explícita
- Uso de transacciones de Firestore para garantizar consistencia
- Logging detallado para auditoría

## Consideraciones Importantes

⚠️ **ADVERTENCIA**: El endpoint de limpieza de comisiones es **IRREVERSIBLE**. 
- Siempre usar primero el modo `dryRun: true`
- Hacer backup de la base de datos antes de ejecutar
- Coordinar con el equipo para evitar interrupciones

## Logs

El servidor genera logs detallados para todas las operaciones, especialmente para la limpieza de comisiones.

## Soporte

Para problemas o preguntas sobre el backend, revisar los logs del servidor y la documentación de cada endpoint.
