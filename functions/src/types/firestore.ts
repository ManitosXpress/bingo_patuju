import type { Query } from 'firebase-admin/firestore';

export type FirestoreQuery = Query;

export interface CardDoc {
    id: string;
    numbers?: number[][]; // 5x5 (returned by API)
    numbersFlat?: number[]; // stored in Firestore
    gridSize?: number; // default 5
    eventId: string; // FK to event - NUEVO
    assignedTo?: string; // vendorId
    sold: boolean;
    createdAt: number;
    cardNo?: number; // Número secuencial de cartilla
    date?: string; // Fecha del evento (YYYY-MM-DD)
}

export interface EventDoc {
    id: string;
    name: string;
    date: string; // ISO 8601
    description?: string;
    status: 'upcoming' | 'active' | 'completed';
    totalCartillas: number;
    createdAt: number;
    updatedAt: number;
}

export type EventStatus = 'upcoming' | 'active' | 'completed';