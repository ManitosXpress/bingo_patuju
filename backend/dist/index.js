import express from 'express';
import cors from 'cors';
import admin from 'firebase-admin';
import { router as vendorsRouter } from './routes/vendors';
import { router as cardsRouter } from './routes/cards';
import { router as salesRouter } from './routes/sales';
import { router as reportsRouter } from './routes/reports';
const app = express();
app.use(cors());
app.use(express.json());
// Firebase Admin init
const serviceAccountJson = process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON;
if (!admin.apps.length) {
    if (serviceAccountJson) {
        admin.initializeApp({
            credential: admin.credential.cert(JSON.parse(serviceAccountJson)),
        });
    }
    else {
        // Fallback to ADC or emulator
        admin.initializeApp();
    }
}
export const db = admin.firestore();
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
const PORT = process.env.PORT || 4001;
app.listen(PORT, () => {
    console.log(`API running on http://localhost:${PORT}`);
});
