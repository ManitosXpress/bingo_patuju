import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { db } from '../index';

// Asegurar que Firebase Admin esté inicializado
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Cloud Function que actualiza contadores denormalizados en documentos de usuario
 * cuando se asigna, desasigna o vende una cartilla.
 * 
 * Esto reduce drásticamente las lecturas en el CRM:
 * - Antes: 100 usuarios × 2 queries cada uno = 200+ lecturas
 * - Ahora: 100 lecturas (solo leer documentos de usuario con contadores ya calculados)
 */
export const updateUserCardCounters = onDocumentWritten(
  {
    document: 'events/{eventDate}/cards/{cardId}',
    region: 'us-central1',
  },
  async (event) => {
    const cardData = event.data?.after?.data();
    const previousData = event.data?.before?.data();

    // Si es una eliminación, no hay datos después
    if (!event.data?.after?.exists) {
      // Si se eliminó una cartilla asignada, decrementar contadores
      if (previousData?.assignedTo) {
        await decrementCounters(previousData.assignedTo, previousData.sold === true);
      }
      return;
    }

    // Si es una creación o actualización
    const currentAssignedTo = cardData?.assignedTo;
    const currentSold = cardData?.sold === true;
    const previousAssignedTo = previousData?.assignedTo;
    const previousSold = previousData?.sold === true;

    // Caso 1: Cartilla asignada a un nuevo vendor
    if (currentAssignedTo && currentAssignedTo !== previousAssignedTo) {
      // Incrementar contador de asignadas para el nuevo vendor
      await incrementAssigned(currentAssignedTo);
      
      // Si también está vendida, incrementar contador de vendidas
      if (currentSold) {
        await incrementSold(currentAssignedTo);
      }

      // Si había un vendor anterior, decrementar sus contadores
      if (previousAssignedTo) {
        await decrementAssigned(previousAssignedTo);
        if (previousSold) {
          await decrementSold(previousAssignedTo);
        }
      }
    }
    // Caso 2: Cartilla desasignada
    else if (!currentAssignedTo && previousAssignedTo) {
      await decrementAssigned(previousAssignedTo);
      if (previousSold) {
        await decrementSold(previousAssignedTo);
      }
    }
    // Caso 3: Cambio de estado de venta (sin cambio de asignación)
    else if (currentAssignedTo && currentAssignedTo === previousAssignedTo) {
      if (currentSold && !previousSold) {
        // Cartilla vendida
        await incrementSold(currentAssignedTo);
      } else if (!currentSold && previousSold) {
        // Cartilla desmarcada como vendida
        await decrementSold(currentAssignedTo);
      }
    }
  }
);

/**
 * Incrementa el contador de cartillas asignadas para un usuario
 */
async function incrementAssigned(userId: string) {
  const userRef = db.collection('users').doc(userId);
  await userRef.update({
    'stats.assigned_count': admin.firestore.FieldValue.increment(1),
  });
}

/**
 * Incrementa el contador de cartillas vendidas para un usuario
 */
async function incrementSold(userId: string) {
  const userRef = db.collection('users').doc(userId);
  await userRef.update({
    'stats.sold_count': admin.firestore.FieldValue.increment(1),
  });
}

/**
 * Decrementa el contador de cartillas asignadas para un usuario
 */
async function decrementAssigned(userId: string) {
  const userRef = db.collection('users').doc(userId);
  await userRef.update({
    'stats.assigned_count': admin.firestore.FieldValue.increment(-1),
  });
}

/**
 * Decrementa el contador de cartillas vendidas para un usuario
 */
async function decrementSold(userId: string) {
  const userRef = db.collection('users').doc(userId);
  await userRef.update({
    'stats.sold_count': admin.firestore.FieldValue.increment(-1),
  });
}

/**
 * Decrementa ambos contadores (usado cuando se elimina una cartilla)
 */
async function decrementCounters(userId: string, wasSold: boolean) {
  const userRef = db.collection('users').doc(userId);
  const updates: any = {
    'stats.assigned_count': admin.firestore.FieldValue.increment(-1),
  };
  
  if (wasSold) {
    updates['stats.sold_count'] = admin.firestore.FieldValue.increment(-1);
  }
  
  await userRef.update(updates);
}

