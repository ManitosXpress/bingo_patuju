import { Router } from 'express';
import { z } from 'zod';
import { db, bucket } from '../index';
import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';
import * as os from 'os';
import * as path from 'path';
import * as fs from 'fs';

// v4 - Using makePublic instead of getSignedUrl to avoid IAM permission issues
export const router = Router();

const shareSchema = z.object({
  assignmentId: z.string(),
  vendorName: z.string(),
  date: z.string(),
});

const uploadPdfSchema = z.object({
  pdfBase64: z.string(),
  vendorId: z.string(),
  fileName: z.string(),
  metadata: z.record(z.string(), z.string()).optional(),
});

function expandGrid(flat: number[], size = 5): number[][] {
  const grid: number[][] = [];
  for (let r = 0; r < size; r++) {
    grid.push(flat.slice(r * size, (r + 1) * size));
  }
  return grid;
}

// Helper to get public URL after making file public
async function uploadAndMakePublic(tempFilePath: string, destination: string, contentType: string): Promise<string> {
  await bucket.upload(tempFilePath, {
    destination,
    metadata: { contentType },
  });

  fs.unlinkSync(tempFilePath);

  const file = bucket.file(destination);
  await file.makePublic();

  const bucketName = bucket.name;
  return `https://storage.googleapis.com/${bucketName}/${destination}`;
}

// Endpoint to upload PDF from frontend (for Web platform)
router.post('/upload-pdf', async (req: any, res: any) => {
  try {
    const { pdfBase64, vendorId, fileName } = uploadPdfSchema.parse(req.body);
    const pdfBuffer = Buffer.from(pdfBase64, 'base64');

    console.log(`📤 Uploading PDF: ${fileName} (${pdfBuffer.length} bytes)`);

    const destination = `cartillas_enviadas/${vendorId}/${fileName}`;
    const tempFilePath = path.join(os.tmpdir(), `upload_${Date.now()}_${fileName}`);
    fs.writeFileSync(tempFilePath, pdfBuffer);

    const url = await uploadAndMakePublic(tempFilePath, destination, 'application/pdf');

    console.log(`✅ PDF uploaded: ${url}`);
    return res.json({ url, message: 'PDF subido correctamente', path: destination });
  } catch (e: any) {
    console.error('Error uploading PDF:', e);
    return res.status(500).json({ error: e.message });
  }
});

router.post('/share-assigned-cards', async (req: any, res: any) => {
  try {
    const { assignmentId, vendorName, date } = shareSchema.parse(req.body);

    const cardsRef = db.collection('events').doc(date).collection('cards');
    const snapshot = await cardsRef.where('assignedTo', '==', assignmentId).get();

    if (snapshot.empty) {
      return res.status(404).json({ error: 'No cards found for this assignment.' });
    }

    const cards = snapshot.docs.map(doc => {
      const data = doc.data();
      const size = (data.gridSize as number) ?? 5;
      const numbers = data.numbers ? (data.numbers as number[][]) : expandGrid((data.numbersFlat as number[]) ?? [], size);
      return { id: doc.id, cardNo: data.cardNo, numbers };
    });

    cards.sort((a, b) => (a.cardNo || 0) - (b.cardNo || 0));

    const pdfDoc = await PDFDocument.create();
    const font = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

    const cardsPerPage = 4;
    const pageWidth = 595.28;
    const pageHeight = 841.89;
    const margin = 20;
    const cardWidth = (pageWidth - (margin * 3)) / 2;
    const cardHeight = (pageHeight - (margin * 3)) / 2.5;

    for (let i = 0; i < cards.length; i += cardsPerPage) {
      const page = pdfDoc.addPage([pageWidth, pageHeight]);
      const pageCards = cards.slice(i, i + cardsPerPage);

      page.drawText(`Cartillas Asignadas - ${vendorName}`, {
        x: margin, y: pageHeight - margin - 20, size: 18, font, color: rgb(0, 0, 0),
      });

      page.drawText(`Fecha: ${date} - Total: ${cards.length} cartillas`, {
        x: margin, y: pageHeight - margin - 40, size: 12, font, color: rgb(0.3, 0.3, 0.3),
      });

      for (let j = 0; j < pageCards.length; j++) {
        const card = pageCards[j];
        const col = j % 2;
        const row = Math.floor(j / 2);
        const x = margin + (col * (cardWidth + margin));
        const y = pageHeight - 100 - (row * (cardHeight + margin)) - cardHeight;

        page.drawRectangle({ x, y, width: cardWidth, height: cardHeight, borderColor: rgb(0, 0, 0), borderWidth: 1 });
        page.drawText(`Cartilla #${card.cardNo || card.id}`, { x: x + 10, y: y + cardHeight - 20, size: 14, font, color: rgb(0, 0, 0) });

        const gridSize = 5;
        const cellSize = Math.min((cardWidth - 20) / gridSize, (cardHeight - 40) / gridSize);
        const gridStartX = x + (cardWidth - (cellSize * gridSize)) / 2;
        const gridStartY = y + (cardHeight - 40) - cellSize;

        for (let r = 0; r < gridSize; r++) {
          for (let c = 0; c < gridSize; c++) {
            const cellX = gridStartX + (c * cellSize);
            const cellY = gridStartY - (r * cellSize);
            page.drawRectangle({ x: cellX, y: cellY, width: cellSize, height: cellSize, borderColor: rgb(0, 0, 0), borderWidth: 0.5 });

            const text = (r === 2 && c === 2) ? 'FREE' : card.numbers[r][c].toString();
            const textSize = 12;
            const textWidth = font.widthOfTextAtSize(text, textSize);
            page.drawText(text, { x: cellX + (cellSize - textWidth) / 2, y: cellY + (cellSize - textSize) / 2 + 2, size: textSize, font, color: rgb(0, 0, 0) });
          }
        }
      }
    }

    const pdfBytes = await pdfDoc.save();
    const tempFilePath = path.join(os.tmpdir(), `report_${assignmentId}_${Date.now()}.pdf`);
    fs.writeFileSync(tempFilePath, pdfBytes);

    const destination = `temp_reports/${assignmentId}_${Date.now()}.pdf`;
    const url = await uploadAndMakePublic(tempFilePath, destination, 'application/pdf');

    return res.json({ url, message: 'PDF Generado correctamente' });
  } catch (e: any) {
    console.error('Error generating report:', e);
    return res.status(500).json({ error: e.message });
  }
});

router.get('/vendors-summary', async (req: any, res: any) => {
  try {
    const { date, leaderId } = req.query;

    if (!date) {
      return res.status(400).json({ error: 'Date is required' });
    }

    let vendorsQuery = db.collection('vendors') as FirebaseFirestore.Query;
    if (leaderId) {
      vendorsQuery = vendorsQuery.where('leaderId', '==', leaderId);
    }
    const vendorsSnap = await vendorsQuery.get();
    const vendors = vendorsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const salesSnap = await db.collection('sales').where('date', '==', date).get();
    const sales = salesSnap.docs.map(doc => doc.data());

    const salesByVendor: Record<string, { count: number, amount: number, commission: number }> = {};

    sales.forEach((sale: any) => {
      const sellerId = sale.sellerId;
      const saleLeaderId = sale.leaderId;
      const amount = sale.amount || 0;
      const commissions = sale.commissions || { seller: 0, leader: 0 };

      if (!salesByVendor[sellerId]) {
        salesByVendor[sellerId] = { count: 0, amount: 0, commission: 0 };
      }
      salesByVendor[sellerId].count++;
      salesByVendor[sellerId].amount += amount;
      salesByVendor[sellerId].commission += (commissions.seller || 0);

      if (saleLeaderId) {
        if (!salesByVendor[saleLeaderId]) {
          salesByVendor[saleLeaderId] = { count: 0, amount: 0, commission: 0 };
        }
        salesByVendor[saleLeaderId].commission += (commissions.leader || 0);
      }
    });

    const vendorsSummary = vendors.map((v: any) => {
      const stats = salesByVendor[v.id] || { count: 0, amount: 0, commission: 0 };
      return {
        ...v,
        vendorId: v.id,
        soldCount: stats.count,
        totalAmount: stats.amount,
        revenueBs: stats.amount,
        commissionsBs: stats.commission,
        assignedCount: 0
      };
    });

    return res.json({ vendors: vendorsSummary, totalCards: 0 });
  } catch (e: any) {
    console.error('Error in vendors-summary:', e);
    return res.status(500).json({ error: e.message });
  }
});

// Endpoint to clear all sales and balances data
router.post('/clear-commissions', async (req: any, res: any) => {
  try {
    const { confirm, vendorId } = req.body;

    if (confirm !== 'ELIMINAR_DATOS_2024') {
      return res.status(400).json({ error: 'Invalid confirmation code' });
    }

    console.log(`🚨 STARTING DATA DELETION: Sales and Balances ${vendorId ? `for vendor ${vendorId}` : '(ALL DATA)'}`);

    const deleteCollection = async (collectionPath: string) => {
      let totalDeleted = 0;
      let query: FirebaseFirestore.Query = db.collection(collectionPath);

      if (vendorId) {
        // If filtering by vendor, we need to check the field names
        if (collectionPath === 'sales') {
          query = query.where('sellerId', '==', vendorId);
        } else if (collectionPath === 'balances') {
          query = query.where('vendorId', '==', vendorId);
        }
      }

      while (true) {
        const snapshot = await query.limit(500).get();
        if (snapshot.empty) break;

        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();

        totalDeleted += snapshot.size;
        console.log(`Deleted ${snapshot.size} docs from ${collectionPath}`);
      }
      return totalDeleted;
    };

    const salesDeleted = await deleteCollection('sales');
    const balancesDeleted = await deleteCollection('balances');

    console.log(`✅ DATA DELETION COMPLETE. Sales: ${salesDeleted}, Balances: ${balancesDeleted}`);

    return res.json({
      success: true,
      summary: {
        salesDeleted,
        balancesDeleted,
        totalRecordsDeleted: salesDeleted + balancesDeleted,
        timestamp: Date.now()
      }
    });

  } catch (e: any) {
    console.error('Error clearing data:', e);
    return res.status(500).json({ error: e.message });
  }
});