# Bingo Patuju

Sistema integral para la gestión y juego de bingo, compuesto por una aplicación móvil desarrollada en Flutter y un backend robusto basado en Firebase Cloud Functions.

## 🏗 Arquitectura del Proyecto

El proyecto sigue una arquitectura cliente-servidor moderna:

*   **Frontend (Cliente):** Aplicación desarrollada en **Flutter** que gestiona la interfaz de usuario, la lógica del juego en el dispositivo y la comunicación con el backend.
*   **Backend (Servidor):** API RESTful construida con **Node.js** y **Express**, alojada en **Firebase Cloud Functions**.
*   **Base de Datos:** **Cloud Firestore** (NoSQL) para el almacenamiento de datos en tiempo real.

## 🛠 Tecnologías Utilizadas

### Frontend (Flutter)
Ubicado en el directorio `lib/`.
*   **Lenguaje:** Dart
*   **Gestión de Estado:** `provider`
*   **Conectividad:** `http` para peticiones REST, `cloud_firestore` para sincronización en tiempo real.
*   **Utilidades:** `shared_preferences` (persistencia local), `intl` (formato de fechas/monedas), `excel` (exportación de reportes).

### Backend (Firebase Functions)
Ubicado en el directorio `functions/`.
*   **Lenguaje:** TypeScript (compilado a Node.js)
*   **Framework Web:** Express.js
*   **Validación:** `zod`
*   **Core:** `firebase-admin`, `firebase-functions`

## 📂 Estructura del Proyecto

```
bingo_patuju/
├── lib/                 # Código fuente de la aplicación Flutter
│   ├── models/          # Modelos de datos (Dart)
│   ├── providers/       # Lógica de estado (Provider)
│   ├── screens/         # Pantallas de la aplicación
│   ├── services/        # Servicios de comunicación con APIs
│   ├── utils/           # Utilidades y constantes
│   └── widgets/         # Componentes UI reutilizables
├── functions/           # Código del backend (Cloud Functions)
│   ├── src/
│   │   ├── index.ts     # Punto de entrada de la API
│   │   ├── routes/      # Definición de rutas (endpoints)
│   │   └── types/       # Definiciones de tipos TypeScript
│   └── package.json     # Dependencias del backend
├── pubspec.yaml         # Dependencias del frontend
└── README.md            # Documentación del proyecto
```

## 🚀 Configuración e Instalación

### Prerrequisitos
*   Flutter SDK (v3.6.0 o superior)
*   Node.js (v20)
*   Firebase CLI

### 1. Configuración del Frontend
```bash
# Obtener dependencias de Flutter
flutter pub get

# Ejecutar la aplicación
flutter run
```

### 2. Configuración del Backend
```bash
cd functions

# Instalar dependencias de Node.js
npm install

# Compilar el código TypeScript
npm run build

# Emular funciones localmente
npm run serve
```

## 🔌 API Backend

El backend expone una API REST bajo el prefijo `/api`. Las principales rutas son:

*   `/api/vendors`: Gestión de vendedores.
*   `/api/cards`: Gestión de cartillas de bingo.
*   `/api/sales`: Registro y consulta de ventas.
*   `/api/reports`: Generación de reportes.
*   `/api/bingo`: Lógica del juego de bingo.
*   `/api/events`: Gestión de eventos.

## 📄 Scripts de Utilidad
El proyecto incluye varios scripts en Python (`.py`) en la raíz para tareas de mantenimiento, refactorización y corrección de errores automatizada.
