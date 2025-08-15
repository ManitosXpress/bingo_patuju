# Integración de Firebase para Cartillas de Bingo

## Descripción

Esta implementación permite que la aplicación Flutter se conecte a Firebase a través de un backend Node.js para gestionar las cartillas de Bingo. Las cartillas se almacenan en Firebase Firestore y se sincronizan con la aplicación local.

## Estructura del Proyecto

```
lib/
├── config/
│   └── backend_config.dart          # Configuración del backend
├── models/
│   └── firebase_cartilla.dart       # Modelo de cartilla de Firebase
├── providers/
│   └── app_provider.dart            # Provider principal con funcionalidad Firebase
├── services/
│   └── cartillas_service.dart       # Servicio para comunicación con Firebase
└── widgets/
    └── cartillas_list_panel.dart    # Panel de lista de cartillas actualizado
```

## Configuración

### 1. Backend (Node.js + Firebase)

El backend ya está configurado en el directorio `backend/` con:
- Express.js server
- Firebase Admin SDK
- Endpoints para CRUD de cartillas
- Puerto 4000 por defecto

### 2. Flutter App

La aplicación Flutter se conecta al backend a través de HTTP requests.

## Funcionalidades Implementadas

### ✅ **Gestión de Cartillas desde Firebase**

- **Cargar cartillas**: Obtiene todas las cartillas desde Firebase
- **Crear cartillas**: Genera nuevas cartillas con números válidos de Bingo
- **Asignar cartillas**: Asigna cartillas a vendedores específicos
- **Filtrar cartillas**: Por vendedor, estado de asignación, etc.
- **Sincronización**: Mantiene sincronizados los datos locales con Firebase

### ✅ **Interfaz de Usuario**

- **Lista de cartillas**: Muestra todas las cartillas de Firebase
- **Estados visuales**: Badges para cartillas asignadas, vendidas, etc.
- **Acciones**: Ver, descargar, asignar, eliminar cartillas
- **Manejo de errores**: Estados de carga, error y reintentos

### ✅ **Características Técnicas**

- **Reintentos automáticos**: Sistema de reintentos para requests fallidos
- **Timeouts configurables**: Manejo de timeouts de conexión
- **Validación de datos**: Verificación de integridad de datos
- **Logging**: Registro de operaciones y errores

## Uso

### 1. **Iniciar el Backend**

```bash
cd backend
npm install
npm start
```

El backend estará disponible en `http://localhost:4000`

### 2. **Usar la Aplicación Flutter**

La aplicación automáticamente:
- Se conecta al backend al iniciar
- Carga las cartillas existentes
- Permite crear nuevas cartillas
- Gestiona asignaciones a vendedores

### 3. **Operaciones Principales**

#### **Cargar Cartillas**
```dart
final appProvider = context.read<AppProvider>();
await appProvider.loadFirebaseCartillas();
```

#### **Crear Nueva Cartilla**
```dart
final newCartilla = await appProvider.createFirebaseCartilla();
```

#### **Asignar Cartilla**
```dart
final success = await appProvider.assignFirebaseCartilla(
  cartillaId, 
  vendorId
);
```

#### **Filtrar Cartillas**
```dart
final filteredCartillas = appProvider.getFilteredFirebaseCartillas();
```

## Endpoints del Backend

### **Cartillas**
- `GET /cards` - Obtener todas las cartillas
- `POST /cards` - Crear nueva cartilla
- `POST /cards/:id/assign` - Asignar cartilla a vendedor
- `POST /cards/:id/unassign` - Desasignar cartilla
- `DELETE /cards/:id` - Eliminar cartilla
- `POST /cards/:id/sold` - Marcar como vendida

### **Vendedores**
- `GET /vendors` - Obtener todos los vendedores
- `POST /vendors` - Crear nuevo vendedor

## Configuración del Entorno

### **Desarrollo Local**
```dart
// backend_config.dart
static const String baseUrl = 'http://localhost:4000';
```

### **Producción**
```dart
// backend_config.dart
static const String baseUrl = 'https://tu-backend.com';
```

## Manejo de Errores

La aplicación maneja automáticamente:
- **Errores de conexión**: Reintentos automáticos
- **Timeouts**: Configurables por endpoint
- **Errores del servidor**: Mensajes descriptivos
- **Estados de carga**: Indicadores visuales

## Sincronización

### **Flujo de Sincronización**
1. La app carga cartillas desde Firebase
2. Se sincronizan con el juego local
3. Los cambios se reflejan en tiempo real
4. Se mantiene la consistencia de datos

### **Conflictos**
- Las cartillas de Firebase tienen prioridad
- Se evitan duplicados por ID único
- Los cambios locales se sincronizan automáticamente

## Personalización

### **Generación de Cartillas**
```dart
// Generar cartilla personalizada
final numbers = CartillaService.generateBingoCard();

// Generar múltiples cartillas
final cards = CartillaService.generateMultipleBingoCards(10);
```

### **Filtros Personalizados**
```dart
// Filtrar por vendedor específico
await appProvider.loadFirebaseCartillas(assignedTo: 'vendor_id');

// Filtrar por estado de venta
await appProvider.loadFirebaseCartillas(sold: true);
```

## Troubleshooting

### **Problemas Comunes**

1. **Error de conexión al backend**
   - Verificar que el backend esté ejecutándose
   - Verificar el puerto en `backend_config.dart`
   - Verificar firewall/antivirus

2. **Cartillas no se cargan**
   - Verificar conexión a internet
   - Verificar credenciales de Firebase
   - Revisar logs del backend

3. **Errores de timeout**
   - Ajustar `connectionTimeout` en `backend_config.dart`
   - Verificar velocidad de conexión
   - Considerar usar `BackendConfig.maxRetries`

### **Logs y Debugging**

```dart
// Habilitar logs detallados
print('Error en Firebase: $e');

// Verificar salud del backend
final isHealthy = await CartillaService.checkBackendHealth();
print('Backend saludable: $isHealthy');
```

## Próximas Mejoras

- [ ] **Cache local**: Almacenar cartillas offline
- [ ] **Sincronización en tiempo real**: WebSockets para cambios instantáneos
- [ ] **Compresión**: Optimizar transferencia de datos
- [ ] **Métricas**: Estadísticas de uso y rendimiento
- [ ] **Backup automático**: Respaldo de datos críticos

## Soporte

Para problemas o preguntas:
1. Revisar logs de la aplicación
2. Verificar configuración del backend
3. Consultar documentación de Firebase
4. Revisar estado de conectividad

---

**Nota**: Esta implementación requiere que el backend esté ejecutándose para funcionar correctamente. En modo offline, la aplicación mostrará errores de conexión. 