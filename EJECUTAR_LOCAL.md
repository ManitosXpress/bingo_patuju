# 🏠 Ejecución Local - Guía Rápida

## ✅ Todo listo para correr en local

### Paso 1: Iniciar el Backend

```bash
# Abrir terminal en la carpeta backend
cd backend

# Compilar TypeScript (solo la primera vez o cuando cambies código)
npm run build

# Iniciar servidor
npm start
```

El backend estará corriendo en: **http://localhost:4001**

Deberías ver:
```
🚀 Server running at http://localhost:4001
```

---

### Paso 2: Iniciar Flutter

```bash
# Abrir OTRA terminal en la raíz del proyecto
cd e:\bingo_patuju

# Correr Flutter Web
flutter run -d chrome
```

---

### Paso 3: ¡Probar!

1. **Crear un evento:**
   - Abre la app en Chrome
   - Ve a CRM Screen
   - Click en "+" del selector de eventos
   - Crea un evento: "Bingo Test", "2025-12-10"

2. **Generar cartillas:**
   - Con el evento seleccionado
   - Genera 10-20 cartillas

3. **Asignar a vendedores:**
   - Asigna cartillas a vendedores
   - Verifica que se filtran por evento

---

## 🔧 Verificar Configuración

Tu `backend_config.dart` debe tener:

```dart
static const String baseUrl = 'http://localhost:4001';
static const String apiBase = 'http://localhost:4001/api';
```

**✅ Ya está configurado así en tu proyecto**

---

## 🐛 Troubleshooting

### Backend no inicia
```bash
# Verificar que el puerto 4001 no esté ocupado
netstat -ano | findstr :4001

# Si está ocupado, matar el proceso
taskkill /PID <número_del_pid> /F
```

### Flutter no conecta al backend
- Verifica que el backend esté corriendo (http://localhost:4001)
- Abre DevTools → Network tab
- Verifica que las requests vayan a localhost:4001

### Error de CORS
Ya está configurado en tu backend con:
```typescript
app.use(cors());
```

---

## 📝 Comandos Útiles

```bash
# Ver logs del backend
# Los logs aparecen en la terminal donde corre npm start

# Reiniciar backend (Ctrl+C y luego)
npm start

# Hot reload Flutter (mientras corre)
# Presiona 'r' en la terminal de Flutter

# Limpiar y rebuild Flutter
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 🎯 Workflow de Desarrollo

1. **Cambiar código backend:**
   - Editar archivos en `backend/src/`
   - Ctrl+C para detener
   - `npm run build`
   - `npm start`

2. **Cambiar código Flutter:**
   - Editar archivos .dart
   - Presionar `r` para hot reload
   - O `R` para full restart

---

## ✨ Ya estás listo!

Backend: http://localhost:4001
Frontend: Se abre automáticamente en Chrome

**Endpoints disponibles:**
- GET http://localhost:4001/api/events
- POST http://localhost:4001/api/events
- GET http://localhost:4001/api/cards?eventId=xxx
- POST http://localhost:4001/api/cards/generate
- Y todos los demás...
