import { Router } from 'express';
import { z } from 'zod';
import { db, bucket } from '../index';
import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';
import * as os from 'os';
import * as path from 'path';
import * as fs from 'fs';

// Force redeploy for bucket fix
export const router = Router();

const shareSchema = z.object({
  assignmentId: z.string(), // This is the vendorId (assignedTo)
  vendorName: z.string(),
  date: z.string(), // Event date is required to find the collection
});

// Helper to expand grid (copied from cards.ts to avoid dependency issues if not exported)
function expandGrid(flat: number[], size = 5): number[][] {
  const grid: number[][] = [];
  for (let r = 0; r < size; r++) {
    grid.push(flat.slice(r * size, (r + 1) * size));
  }
  return grid;
}

router.post('/share-assigned-cards', async (req: any, res: any) => {
  try {
    const { assignmentId, vendorName, date } = shareSchema.parse(req.body);

    // 1. Fetch cards assigned to this vendor for the specific date
    const cardsRef = db.collection('events').doc(date).collection('cards');
    const snapshot = await cardsRef.where('assignedTo', '==', assignmentId).get();

    if (snapshot.empty) {
      return res.status(404).json({ error: 'No cards found for this assignment.' });
    }

    const cards = snapshot.docs.map(doc => {
      const data = doc.data();
      const size = (data.gridSize as number) ?? 5;
      const numbers = data.numbers ? (data.numbers as number[][]) : expandGrid((data.numbersFlat as number[]) ?? [], size);
      return {
        id: doc.id,
        cardNo: data.cardNo,
        numbers,
        // ... other fields if needed
      };
    });

    // Sort by card number
    cards.sort((a, b) => (a.cardNo || 0) - (b.cardNo || 0));

    // 2. Generate PDF
    const pdfDoc = await PDFDocument.create();
    const font = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

    // Configuration for grid layout (2x2 = 4 cards per page)
    const cardsPerPage = 4;
    const pageWidth = 595.28; // A4 width in points
    const pageHeight = 841.89; // A4 height in points
    const margin = 20;
    const cardWidth = (pageWidth - (margin * 3)) / 2;
    const cardHeight = (pageHeight - (margin * 3)) / 2.5; // Adjusted for header/footer

    for (let i = 0; i < cards.length; i += cardsPerPage) {
      const page = pdfDoc.addPage([pageWidth, pageHeight]);
      const pageCards = cards.slice(i, i + cardsPerPage);

      // Add Header
      page.drawText(`Cartillas Asignadas - ${vendorName}`, {
        x: margin,
        y: pageHeight - margin - 20,
        size: 18,
        font: font,
        color: rgb(0, 0, 0),
      });

      page.drawText(`Fecha: ${date} - Total: ${cards.length} cartillas`, {
        x: margin,
        y: pageHeight - margin - 40,
        size: 12,
        font: font,
        color: rgb(0.3, 0.3, 0.3),
      });

      for (let j = 0; j < pageCards.length; j++) {
        const card = pageCards[j];
        const col = j % 2;
        const row = Math.floor(j / 2);

        const x = margin + (col * (cardWidth + margin));
        const y = pageHeight - 100 - (row * (cardHeight + margin)) - cardHeight;

        // Draw Card Container
        page.drawRectangle({
          x,
          y,
          width: cardWidth,
          height: cardHeight,
          borderColor: rgb(0, 0, 0),
          borderWidth: 1,
        });

        // Draw Card Title
        page.drawText(`Cartilla #${card.cardNo || card.id}`, {
          x: x + 10,
          y: y + cardHeight - 20,
          size: 14,
          font: font,
          color: rgb(0, 0, 0),
        });

        // Draw Grid
        const gridSize = 5;
        const cellSize = Math.min((cardWidth - 20) / gridSize, (cardHeight - 40) / gridSize);
        const gridStartX = x + (cardWidth - (cellSize * gridSize)) / 2;
        const gridStartY = y + (cardHeight - 40) - cellSize; // Start from top row

        for (let r = 0; r < gridSize; r++) {
          for (let c = 0; c < gridSize; c++) {
            const cellX = gridStartX + (c * cellSize);
            const cellY = gridStartY - (r * cellSize);

            // Draw cell border
            page.drawRectangle({
              x: cellX,
              y: cellY,
              width: cellSize,
              height: cellSize,
              borderColor: rgb(0, 0, 0),
              borderWidth: 0.5,
            });

            // Draw number
            let text = '';
            if (r === 2 && c === 2) {
              text = 'FREE';
            } else {
              text = card.numbers[r][c].toString();
            }

            const textSize = 12;
            const textWidth = font.widthOfTextAtSize(text, textSize);

            page.drawText(text, {
              x: cellX + (cellSize - textWidth) / 2,
              y: cellY + (cellSize - textSize) / 2 + 2, // +2 for visual centering
              size: textSize,
              font: font,
              color: rgb(0, 0, 0),
            });
          }
        }
      }
    }

    // 3. Save and Upload
    const pdfBytes = await pdfDoc.save();
    const tempFilePath = path.join(os.tmpdir(), `report_${assignmentId}_${Date.now()}.pdf`);
    fs.writeFileSync(tempFilePath, pdfBytes);

    const destination = `temp_reports/${assignmentId}_${Date.now()}.pdf`;

    // Upload to Firebase Storage
    await bucket.upload(tempFilePath, {
      destination,
      metadata: {
        contentType: 'application/pdf',
      },
    });

    // Clean up temp file
    fs.unlinkSync(tempFilePath);

    // 4. Get Signed URL
    const file = bucket.file(destination);
    const [url] = await file.getSignedUrl({
      action: 'read',
      expires: Date.now() + 24 * 60 * 60 * 1000, // 24 hours
    });

    return res.json({ url, message: 'PDF Generado correctamente' });

  } catch (e: any) {
    console.error('Error generating report:', e);
    return res.status(500).json({ error: e.message });
  }
});

// Endpoint for CRM summary
router.get('/vendors-summary', async (req: any, res: any) => {
  try {
    const { date, leaderId } = req.query;

    if (!date) {
      return res.status(400).json({ error: 'Date is required' });
    }

    // 1. Fetch Vendors
    let vendorsQuery = db.collection('vendors') as FirebaseFirestore.Query;
    if (leaderId) {
      vendorsQuery = vendorsQuery.where('leaderId', '==', leaderId);
    }
    const vendorsSnap = await vendorsQuery.get();
    const vendors = vendorsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // 2. Fetch Sales for the date
    const salesSnap = await db.collection('sales').where('date', '==', date).get();
    const sales = salesSnap.docs.map(doc => doc.data());

    // 3. Aggregate Sales
    const salesByVendor: Record<string, { count: number, amount: number, commission: number }> = {};

    sales.forEach((sale: any) => {
      const sellerId = sale.sellerId;
      const leaderId = sale.leaderId;
      const amount = sale.amount || 0;
      const commissions = sale.commissions || { seller: 0, leader: 0 };

      // Initialize seller stats if needed
      if (!salesByVendor[sellerId]) {
        salesByVendor[sellerId] = { count: 0, amount: 0, commission: 0 };
      }

      // Update Seller Stats (Direct Sales)
      salesByVendor[sellerId].count++;
      salesByVendor[sellerId].amount += amount;
      salesByVendor[sellerId].commission += (commissions.seller || 0);

      // Update Leader Stats (Override Commission)
      if (leaderId) {
        if (!salesByVendor[leaderId]) {
          salesByVendor[leaderId] = { count: 0, amount: 0, commission: 0 };
        }
        salesByVendor[leaderId].commission += (commissions.leader || 0);
      }
    });

    // 4. Map to response format
    const vendorsSummary = vendors.map((v: any) => {
      const stats = salesByVendor[v.id] || { count: 0, amount: 0, commission: 0 };
      return {
        ...v,
        vendorId: v.id,
        soldCount: stats.count,
        totalAmount: stats.amount,
        revenueBs: stats.amount, // Explicitly for frontend
        commissionsBs: stats.commission, // Explicitly for frontend
        assignedCount: 0 // Frontend enriches this
      };
    });

    return res.json({
      vendors: vendorsSummary,
      totalCards: 0 // Frontend will fetch real total
    });

  } catch (e: any) {
    console.error('Error in vendors-summary:', e);
    return res.status(500).json({ error: e.message });
  }
});