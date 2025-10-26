"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.db = void 0;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const firebase_admin_1 = __importDefault(require("firebase-admin"));
const vendors_js_1 = require("./routes/vendors.js");
const cards_js_1 = require("./routes/cards.js");
const sales_js_1 = require("./routes/sales.js");
const reports_js_1 = require("./routes/reports.js");
const bingo_js_1 = require("./routes/bingo.js");
const app = (0, express_1.default)();
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Firebase Admin init
const serviceAccountJson = process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON;
if (!firebase_admin_1.default.apps.length) {
    if (serviceAccountJson) {
        firebase_admin_1.default.initializeApp({
            credential: firebase_admin_1.default.credential.cert(JSON.parse(serviceAccountJson)),
        });
    }
    else {
        // Fallback to ADC or emulator
        firebase_admin_1.default.initializeApp();
    }
}
exports.db = firebase_admin_1.default.firestore();
app.get('/health', (_req, res) => res.json({ ok: true }));
// Agregar prefijo /api a todas las rutas
app.use('/api/vendors', vendors_js_1.router);
app.use('/api/cards', cards_js_1.router);
app.use('/api/sales', sales_js_1.router);
app.use('/api/reports', reports_js_1.router);
app.use('/api/bingo', bingo_js_1.bingoRouter);
// Mantener rutas sin prefijo para compatibilidad
app.use('/vendors', vendors_js_1.router);
app.use('/cards', cards_js_1.router);
app.use('/sales', sales_js_1.router);
app.use('/reports', reports_js_1.router);
app.use('/bingo', bingo_js_1.bingoRouter);
const PORT = process.env.PORT || 4001;
app.listen(PORT, () => {
    console.log(`API running on http://localhost:${PORT}`);
});
