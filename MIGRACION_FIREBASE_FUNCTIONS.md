# Migración de Localhost a Firebase Functions

## Resumen de la Migración

Tu proyecto ha sido migrado exitosamente de un servidor local (localhost:4001) a Firebase Functions. Esto te permitirá:

- ✅ Desplegar tu API en la nube de Google
- ✅ Escalar automáticamente según la demanda
- ✅ Mantener el desarrollo local con emuladores
- ✅ Integración nativa con Firebase/Firestore

## Cambios Realizados

### 1. Backend Migrado a Firebase Functions
- ✅ Código migrado de `backend/src/` a `functions/src/`
- ✅ Dependencias instaladas correctamente
- ✅ Build exitoso sin errores
- ✅ Configuración de Firebase Functions completada

### 2. Configuración de Flutter Actualizada
- ✅ `lib/config/backend_config.dart` actualizado
- ✅ Soporte para emulador local y producción
- ✅ URLs configuradas para Firebase Functions

### 3. Scripts de Desarrollo
- ✅ `start-firebase-emulator.ps1` para desarrollo local
- ✅ Configuración de emuladores de Firebase

## Cómo Usar

### Desarrollo Local (Recomendado para desarrollo)

1. **Iniciar el emulador local:**
   ```powershell
   .\start-firebase-emulator.ps1
   ```

2. **Tu app Flutter se conectará automáticamente a:**
   ```
   http://localhost:5001/bingo-baitty/us-central1/api
   ```

3. **Para detener el emulador:** Presiona `Ctrl+C`

### Producción

1. **Cambiar la configuración en `lib/config/backend_config.dart`:**
   ```dart
   static const bool useLocalEmulator = false; // Cambiar a false
   ```

2. **Desplegar las functions:**
   ```bash
   cd functions
   npm run deploy
   ```

3. **Tu app se conectará a:**
   ```
   https://us-central1-bingo-baitty.cloudfunctions.net/api
   ```

## Estructura de URLs

### Antes (Localhost)
- Base: `http://localhost:4001`
- Cards: `http://localhost:4001/cards`
- Vendors: `http://localhost:4001/vendors`

### Después (Firebase Functions)
- Base: `https://us-central1-bingo-baitty.cloudfunctions.net/api`
- Cards: `https://us-central1-bingo-baitty.cloudfunctions.net/api/cards`
- Vendors: `https://us-central1-bingo-baitty.cloudfunctions.net/api/vendors`

## Ventajas de la Migración

1. **Escalabilidad:** Se escala automáticamente según la demanda
2. **Disponibilidad:** 99.9% de uptime garantizado por Google
3. **Seguridad:** Integración nativa con Firebase Auth y reglas de seguridad
4. **Monitoreo:** Logs y métricas integrados en Firebase Console
5. **Desarrollo:** Emuladores locales para desarrollo sin costo

## Comandos Útiles

### Desarrollo
```bash
# Iniciar emulador local
firebase emulators:start --only functions

# Ver logs en tiempo real
firebase functions:log

# Probar localmente
firebase emulators:start --only functions,firestore
```

### Despliegue
```bash
# Desplegar solo functions
firebase deploy --only functions

# Desplegar todo
firebase deploy

# Ver estado del despliegue
firebase functions:list
```

## Solución de Problemas

### Error de Build
```bash
cd functions
npm run build
```

### Error de Dependencias
```bash
cd functions
npm install
```

### Emulador no inicia
```bash
firebase login
firebase use bingo-baitty
```

## Próximos Pasos Recomendados

1. **Probar el emulador local** con tu app Flutter
2. **Verificar que todas las funcionalidades** funcionen correctamente
3. **Configurar reglas de seguridad** en Firestore
4. **Implementar autenticación** con Firebase Auth
5. **Configurar monitoreo** y alertas en Firebase Console

## Soporte

- [Documentación oficial de Firebase Functions](https://firebase.google.com/docs/functions)
- [Guía de emuladores](https://firebase.google.com/docs/emulator-suite)
- [Firebase Console](https://console.firebase.google.com/project/bingo-baitty)

---

**¡Tu migración a Firebase Functions está completa! 🎉**
