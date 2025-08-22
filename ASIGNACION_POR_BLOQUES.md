# 🧱 Asignación de Cartillas por Bloques

## ✨ **Nueva Funcionalidad Implementada**

### **Objetivo**
Implementar un sistema de asignación de cartillas por bloques que permita:
- **Dividir cartillas en bloques** de tamaño configurable
- **Saltar bloques específicos** (ej: primeros 10 bloques)
- **Distribuir bloques completos** a vendedores/líderes
- **Control de rangos** desde cartillas específicas

## 🎯 **Casos de Uso**

### **Ejemplo 1: Distribución por Bloques de 5**
- **Total de cartillas**: 1000
- **Tamaño del bloque**: 5 cartillas
- **Bloques a saltar**: 10 (primeros 50 números)
- **Resultado**: 
  - Total de bloques: 200
  - Bloques disponibles: 190
  - Cartillas asignables: 51-1000
  - Cartillas por asignar: 950

### **Ejemplo 2: Distribución por Bloques de 10**
- **Total de cartillas**: 1000
- **Tamaño del bloque**: 10 cartillas
- **Bloques a saltar**: 5 (primeros 50 números)
- **Resultado**:
  - Total de bloques: 100
  - Bloques disponibles: 95
  - Cartillas asignables: 51-1000
  - Cartillas por asignar: 950

## 🔧 **Implementación Técnica**

### **1. Nuevo Modal de Asignación**
```dart
// Opción agregada al modal existente
RadioListTile<String>(
  title: const Text('Por bloques'),
  value: 'blocks',
  groupValue: assignmentType,
  onChanged: (value) => setDialogState(() => assignmentType = value!),
),
```

### **2. Campos de Configuración**
```dart
// Tamaño del bloque
TextField(
  controller: blockSizeCtrl,
  decoration: InputDecoration(
    labelText: 'Tamaño del bloque',
    helperText: 'Cartillas por bloque',
  ),
),

// Bloques a saltar
TextField(
  controller: skipBlocksCtrl,
  decoration: InputDecoration(
    labelText: 'Bloques a saltar',
    helperText: 'Ej: 10 para saltar primeros 10 bloques',
  ),
),

// Cartilla de inicio
TextField(
  controller: startCardCtrl,
  decoration: InputDecoration(
    labelText: 'Cartilla de inicio',
    helperText: 'Número de cartilla para comenzar',
  ),
),

// Total de cartillas
TextField(
  controller: totalCardsCtrl,
  decoration: InputDecoration(
    labelText: 'Total de cartillas',
    helperText: 'Total disponible para asignar',
  ),
),
```

### **3. Lógica de Cálculo de Bloques**
```dart
// Calcular información de bloques
final totalBlocks = (totalCards / blockSize).ceil();
final availableBlocks = totalBlocks - skipBlocks;
final startBlock = skipBlocks + 1;
final startCardNumber = startCard + (skipBlocks * blockSize);
final endCardNumber = startCardNumber + (availableBlocks * blockSize) - 1;

// Generar números de cartillas por bloques
final cardNumbers = <int>[];
for (int block = startBlock; block <= totalBlocks; block++) {
  final blockStartCard = startCard + ((block - 1) * blockSize);
  for (int i = 0; i < blockSize; i++) {
    final cardNumber = blockStartCard + i;
    if (cardNumber <= totalCards) {
      cardNumbers.add(cardNumber);
    }
  }
}
```

### **4. Validaciones Implementadas**
```dart
// Validar parámetros
if (blockSize <= 0) {
  // Error: Tamaño del bloque debe ser mayor a 0
}

if (skipBlocks < 0) {
  // Error: Bloques a saltar no pueden ser negativos
}

if (startCard < 1 || startCard > totalCards) {
  // Error: Cartilla de inicio debe estar en rango válido
}
```

## 🎮 **Flujo de Usuario**

### **Paso 1: Seleccionar Tipo de Asignación**
1. **Abrir modal** "Asignar Cartillas"
2. **Seleccionar** "Por bloques" (tercera opción)
3. **Ver campos** específicos para bloques

### **Paso 2: Configurar Parámetros**
1. **Tamaño del bloque**: Número de cartillas por bloque (ej: 5)
2. **Bloques a saltar**: Cuántos bloques iniciales omitir (ej: 10)
3. **Cartilla de inicio**: Número de cartilla para comenzar (ej: 1)
4. **Total de cartillas**: Total disponible en el sistema (ej: 1000)

### **Paso 3: Confirmar Asignación**
1. **Sistema calcula** información de bloques
2. **Muestra resumen** con detalles de la operación
3. **Usuario confirma** la asignación

### **Paso 4: Procesamiento**
1. **Genera números** de cartillas por bloques
2. **Realiza asignación** masiva al backend
3. **Muestra progreso** en tiempo real

### **Paso 5: Resumen Final**
1. **Confirma éxito** de la operación
2. **Muestra estadísticas** de cartillas asignadas
3. **Lista cartillas** asignadas (primeras 10)
4. **Reporta errores** si los hay

## 📊 **Información de Bloques Mostrada**

### **Resumen Visual**
```
Información de Bloques
• Total de bloques: 200
• Bloques a saltar: 10 (cartillas 1-50)
• Cartillas asignables: 51-1000
• Bloques disponibles: 190
```

### **Confirmación de Asignación**
```
Resumen de la Asignación:
• Tamaño del bloque: 5 cartillas
• Total de bloques: 200
• Bloques a saltar: 10
• Bloques disponibles: 190
• Rango de cartillas: 51-1000
• Total a asignar: 950 cartillas
```

## 🔄 **Integración con Backend**

### **Endpoint Utilizado**
```
POST /cards/bulk-assign
```

### **Payload de Asignación por Bloques**
```json
{
  "vendorId": "vendor123",
  "cardNumbers": [51, 52, 53, 54, 55, 56, 57, 58, 59, 60, ...],
  "assignmentType": "blocks",
  "blockSize": 5,
  "skipBlocks": 10,
  "startCard": 1,
  "totalCards": 1000
}
```

### **Respuesta del Backend**
```json
{
  "message": "Asignación completada",
  "assignedCount": 950,
  "assignedCards": [...],
  "notFoundCards": [...],
  "summary": "950 cartillas asignadas exitosamente"
}
```

## 🎯 **Ventajas de la Solución**

### **1. Eficiencia Operativa**
- **Asignación masiva**: Procesa cientos de cartillas en una operación
- **Organización por bloques**: Facilita la gestión y distribución
- **Control de rangos**: Permite saltar números específicos

### **2. Flexibilidad del Usuario**
- **Tamaño configurable**: Bloques de cualquier tamaño
- **Saltos personalizables**: Omitir cualquier número de bloques
- **Rangos específicos**: Empezar desde cualquier cartilla

### **3. Transparencia del Proceso**
- **Cálculos automáticos**: Sistema calcula totales y rangos
- **Confirmación visual**: Usuario ve exactamente qué se asignará
- **Resumen detallado**: Reporte completo de la operación

### **4. Integración Perfecta**
- **Modal existente**: Se integra con el sistema actual
- **Backend compatible**: Utiliza endpoints existentes
- **Estado consistente**: Mantiene sincronización con la UI

## 🚀 **Casos de Uso Avanzados**

### **Distribución por Equipos**
- **Equipo A**: Bloques 1-20 (cartillas 1-100)
- **Equipo B**: Bloques 21-40 (cartillas 101-200)
- **Equipo C**: Bloques 41-60 (cartillas 201-300)

### **Exclusión de Números Especiales**
- **Saltar primeros 5 bloques**: Cartillas 1-25 reservadas
- **Saltar bloques 50-60**: Cartillas 251-300 para eventos especiales
- **Asignar solo bloques pares**: 2, 4, 6, 8, 10...

### **Distribución por Regiones**
- **Región Norte**: Bloques 1-50
- **Región Sur**: Bloques 51-100
- **Región Este**: Bloques 101-150
- **Región Oeste**: Bloques 151-200

## 🔧 **Mantenimiento y Debugging**

### **Logs de Debug**
```dart
print('DEBUG: Asignación por bloques iniciada');
print('DEBUG: Tamaño del bloque: $blockSize');
print('DEBUG: Bloques a saltar: $skipBlocks');
print('DEBUG: Total de bloques: $totalBlocks');
print('DEBUG: Bloques disponibles: $availableBlocks');
print('DEBUG: Cartillas generadas: ${cardNumbers.length}');
```

### **Manejo de Errores**
- **Validación de parámetros**: Verificación antes de procesar
- **Try-catch**: Captura de errores en operaciones críticas
- **Feedback visual**: Notificaciones claras de éxito/error

### **Estado del Widget**
- **setState()**: Actualización apropiada de la UI
- **mounted check**: Verificación antes de actualizar estado
- **Diálogos de progreso**: Feedback visual durante operaciones largas

## 🎉 **Resultado Final**

Con esta implementación, el sistema de CRM ahora ofrece:

✅ **Asignación por bloques**: División inteligente de cartillas en grupos manejables
✅ **Control de rangos**: Saltar bloques específicos según necesidades
✅ **Distribución masiva**: Procesar cientos de cartillas en una operación
✅ **Transparencia total**: Usuario ve exactamente qué se asignará
✅ **Integración perfecta**: Funciona con el sistema existente
✅ **Flexibilidad máxima**: Configuración completa de parámetros

La funcionalidad está lista para uso inmediato y proporciona una solución robusta para la gestión masiva de cartillas por bloques en el sistema de Bingo.
