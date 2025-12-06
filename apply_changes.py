#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para aplicar cambios en archivos con problemas de line endings
"""
import re

def apply_cards_changes():
    """Aplicar cambios a backend/src/routes/cards.ts"""
    file_path = 'e:/bingo_patuju/backend/src/routes/cards.ts'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    changes_made = []
    
    # 1. Verificar interface CardDoc
    if 'eventId: string; // FK to event' not in content:
        content = content.replace(
            'gridSize?: number; // default 5\n  assignedTo?: string;',
            'gridSize?: number; // default 5\n  eventId: string; // FK to event\n  assignedTo?: string;'
        )
        changes_made.append('✓ Interface CardDoc actualizada')
    
    # 2. Verificar createCardSchema
    if 'eventId: z.string()' not in content:
        content = content.replace(
            'const createCardSchema = z.object({\n  numbers: z.array(z.array(z.number())),\n  cardNo:',
            'const createCardSchema = z.object({\n  numbers: z.array(z.number())),\n  eventId: z.string().min(1, \'eventId es requerido\'),\n  cardNo:'
        )
        changes_made.append('✓ createCardSchema actualizado')
    
    # 3. Verificar dataToSave en POST
    if 'eventId: parsed.eventId,' not in content:
        # Buscar el patrón y agregar eventId
        pattern = r'(const dataToSave = \{\s+numbersFlat: flat,\s+gridSize: parsed\.numbers\.length,)\s+(assignedTo: null,)'
        replacement = r'\1\n      eventId: parsed.eventId,\n      \2'
        content = re.sub(pattern, replacement, content)
        changes_made.append('✓ dataToSave POST actualizado')
    
    # 4. Verificar GET query params
    if 'eventId?: string' not in content and 'router.get(\'/\',' in content:
        content = content.replace(
            'const { assignedTo, sold, limit } = _req.query as { assignedTo?: string; sold?: string; limit?: string };',
            'const { assignedTo, sold, limit, eventId } = _req.query as { assignedTo?: string; sold?: string; limit?: string; eventId?: string };'
        )
        changes_made.append('✓ GET query params actualizado')
    
    # 5. Agregar filtro por eventId en GET
    if 'if (eventId) q = q.where' not in content:
        content = content.replace(
            'let q = db.collection(\'cards\') as any;\n  if (assignedTo)',
            'let q = db.collection(\'cards\') as any;\n  if (eventId) q = q.where(\'eventId\', \'==\', eventId);\n  if (assignedTo)'
        )
        changes_made.append('✓ Filtro eventId en GET agregado')
    
    # 6. Incluir eventId en respuesta GET
    if 'eventId: data.eventId' not in content and 'return {' in content and 'numbers,' in content:
        content = content.replace(
            'id: d.id,\n      numbers,\n      assignedTo:',
            'id: d.id,\n      numbers,\n      eventId: data.eventId ?? null,\n      assignedTo:'
        )
        changes_made.append('✓ eventId en respuesta GET agregado')
    
    # 7. Actualizar /generate
    if 'eventId } = req.body as { count?: number; eventId: string' not in content:
        content = content.replace(
            'const { count = 1 } = req.body as { count?: number };',
            'const { count = 1, eventId } = req.body as { count?: number; eventId: string };\n    \n    if (!eventId) {\n      return res.status(400).json({ \n        error: \'eventId es requerido\' \n      });\n    }'
        )
        changes_made.append('✓ /generate actualizado con eventId')
    
    # 8. Incluir eventId en dataToSave de /generate
    if 'eventId: eventId,' not in content or content.count('eventId: eventId,') < 1:
        pattern = r'(const dataToSave = \{\s+numbersFlat: flat,\s+gridSize: 5,)\s+(assignedTo: null,)'
        if re.search(pattern, content):
            replacement = r'\1\n          eventId: eventId,\n          \2'
            content = re.sub(pattern, replacement, content, count=1)
            changes_made.append('✓ eventId en dataToSave /generate agregado')
    
    # Escribir cambios
    if changes_made:
        with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(content)
        print("\\n=== Cambios aplicados a cards.ts ===")
        for change in changes_made:
            print(change)
    else:
        print("\\n=== cards.ts ya tiene todos los cambios ===")

def apply_cartilla_changes():
    """Aplicar cambios a lib/models/firebase_cartilla.dart"""
    file_path = 'e:/bingo_patuju/lib/models/firebase_cartilla.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    changes_made = []
    
    # 1. Agregar campo eventId
    if 'final String eventId;' not in content:
        content = content.replace(
            'final List<List<int>> numbers;\n  final String? assignedTo;',
            'final List<List<int>> numbers;\n  final String eventId;\n  final String? assignedTo;'
        )
        changes_made.append('✓ Campo eventId agregado')
    
    # 2. Actualizar constructor
    if 'required this.eventId,' not in content:
        content = content.replace(
            'required this.numbers,\n    this.assignedTo,',
            'required this.numbers,\n    required this.eventId,\n    this.assignedTo,'
        )
        changes_made.append('✓ Constructor actualizado')
    
    # 3. Actualizar fromJson
    if "json['eventId']" not in content:
        content = content.replace(
            "numbers: numbers,\n        assignedTo: json['assignedTo']",
            "numbers: numbers,\n        eventId: json['eventId'] as String? ?? '',\n        assignedTo: json['assignedTo']"
        )
        changes_made.append('✓ fromJson actualizado')
    
    # 4. Actualizar toJson
    if "'eventId': eventId," not in content:
        content = content.replace(
            "'numbers': numbers,\n      'assignedTo': assignedTo,",
            "'numbers': numbers,\n      'eventId': eventId,\n      'assignedTo': assignedTo,"
        )
        changes_made.append('✓ toJson actualizado')
    
    # Escribir cambios
    if changes_made:
        with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(content)
        print("\\n=== Cambios aplicados a firebase_cartilla.dart ===")
        for change in changes_made:
            print(change)
    else:
        print("\\n=== firebase_cartilla.dart ya tiene todos los cambios ===")

if __name__ == '__main__':
    print("🔧 Aplicando cambios automáticos...")
    print("=" * 50)
    
    try:
        apply_cards_changes()
        apply_cartilla_changes()
        print("\\n✅ Proceso completado!")
    except Exception as e:
        print(f"\\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
