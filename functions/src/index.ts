import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import express from 'express';
import cors from 'cors';
import { router as vendorsRouter } from './routes/vendors';
import { router as cardsRouter } from './routes/cards';
import { router as salesRouter } from './routes/sales';
import { router as reportsRouter } from './routes/reports';

// Inicializar Firebase Admin (solo si no está ya inicializado)
if (!admin.apps.length) {
  admin.initializeApp();
}

// Exportar la base de datos Firestore
export const db = admin.firestore();

// Crear la aplicación Express
const app = express();

// Middleware
app.use(cors({ origin: true }));
app.use(express.json());

// Ruta de salud
app.get('/health', (_req, res) => res.json({ ok: true }));

// Agregar prefijo /api a todas las rutas
app.use('/api/vendors', vendorsRouter);
app.use('/api/cards', cardsRouter);
app.use('/api/sales', salesRouter);
app.use('/api/reports', reportsRouter);

// Mantener rutas sin prefijo para compatibilidad
app.use('/vendors', vendorsRouter);
app.use('/cards', cardsRouter);
app.use('/sales', salesRouter);
app.use('/reports', reportsRouter);

// Exportar la función HTTP de Firebase usando la sintaxis v2
export const api = onRequest(app);
