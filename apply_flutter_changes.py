#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para aplicar cambios en archivos Flutter con problemas de line endings
"""
import re

def apply_cartillas_service_changes():
    """Aplicar cambios a lib/services/cartillas_service.dart"""
    file_path = 'e:/bingo_patuju/lib/services/cartillas_service.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    changes_made = []
    
    # 1. Actualizar getCartillas para aceptar eventId
    if 'eventId?' not in content or 'Future<List<Map<String, dynamic>>> getCartillas({' not in content:
        # Buscar y reemplazar la firma del método
        pattern = r'static Future<List<Map<String, dynamic>>> getCartillas\(\{\s+String\? assignedTo,\s+bool\? sold,\s+int page = 0,\s+int limit = 10,\s+\}\)'
        if re.search(pattern, content):
            replacement = '''static Future<List<Map<String, dynamic>>> getCartillas({
    String? eventId,
    String? assignedTo,
    bool? sold,
    int page = 0,
    int limit = 10,
  })'''
            content = re.sub(pattern, replacement, content)
            changes_made.append('✓ Firma de getCartillas actualizada')
    
    # 2. Agregar eventId a queryParams en getCartillas
    if "queryParams['eventId']" not in content:
        pattern = r"(final queryParams = <String, String>\{\s+'page': page\.toString\(\),\s+'limit': limit\.toString\(\),\s+\};)\s+(if \(assignedTo != null\))"
        if re.search(pattern, content):
            replacement = r"\1\n      if (eventId != null) queryParams['eventId'] = eventId;\n      \2"
            content = re.sub(pattern, replacement, content)
            changes_made.append('✓ eventId agregado a queryParams en getCartillas')
    
    # 3. Actualizar generateCartillas para requerir eventId
    if 'static Future<Map<String, dynamic>?> generateCartillas(int count, String eventId)' not in content:
        # Cambiar la firma
        content = content.replace(
            'static Future<Map<String, dynamic>?> generateCartillas(int count) async {',
            'static Future<Map<String, dynamic>?> generateCartillas(int count, String eventId) async {'
        )
        changes_made.append('✓ Firma de generateCartillas actualizada')
    
    # 4. Agregar validación de eventId en generateCartillas
    if 'if (eventId.isEmpty)' not in content:
        pattern = r"(static Future<Map<String, dynamic>\?> generateCartillas\(int count, String eventId\) async \{\s+try \{)"
        if re.search(pattern, content):
            replacement = r'''\1
      if (eventId.isEmpty) {
        throw Exception('eventId es requerido para generar cartillas');
      }
      '''
            content = re.sub(pattern, replacement, content)
            changes_made.append('✓ Validación de eventId agregada en generateCartillas')
    
    # 5. Incluir eventId en el body de generateCartillas
    if "'eventId': eventId" not in content:
        pattern = r"body: json\.encode\(\{'count': count\}\),"
        if pattern.replace('\\', '') in content:
            content = content.replace(
                "body: json.encode({'count': count}),",
                "body: json.encode({'count': count, 'eventId': eventId}),"
            )
            changes_made.append('✓ eventId incluido en body de generateCartillas')
    
    # Escribir cambios
    if changes_made:
        with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(content)
        print("\n=== Cambios aplicados a cartillas_service.dart ===")
        for change in changes_made:
            print(change)
    else:
        print("\n=== cartillas_service.dart ya tiene todos los cambios ===")

def verify_all_changes():
    """Verificar que todos los archivos tengan los cambios necesarios"""
    print("\n" + "="*60)
    print("VERIFICACIÓN FINAL")
    print("="*60)
    
    files_to_check = {
        'e:/bingo_patuju/lib/models/firebase_cartilla.dart': [
            ('eventId field', 'final String eventId'),
            ('eventId in constructor', 'required this.eventId'),
            ('eventId in fromJson', "json['eventId']"),
            ('eventId in toJson', "'eventId': eventId"),
        ],
        'e:/bingo_patuju/lib/models/firebase_bingo_game.dart': [
            ('eventId field', 'final String eventId'),
            ('eventId in constructor', 'required this.eventId'),
            ('eventId in fromFirestore', "data['eventId']"),
            ('eventId in copyWith param', 'String? eventId,'),
            ('eventId in copyWith return', 'eventId: eventId ?? this.eventId'),
        ],
        'e:/bingo_patuju/lib/services/cartillas_service.dart': [
            ('eventId parameter in getCartillas', 'String? eventId'),
            ('eventId in queryParams', "queryParams['eventId']"),
            ('eventId parameter in generateCartillas', 'generateCartillas(int count, String eventId)'),
            ('eventId in generate body', "'eventId': eventId"),
        ],
        'e:/bingo_patuju/backend/src/routes/cards.ts': [
            ('eventId in CardDoc', 'eventId: string'),
            ('eventId in schema', 'eventId: z.string()'),
            ('eventId in dataToSave', 'eventId: parsed.eventId'),
            ('eventId query param', 'eventId?:'),
        ],
    }
    
    all_good = True
    for file_path, checks in files_to_check.items():
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            print(f"\n📄 {file_path.split('/')[-1]}:")
            for check_name, check_string in checks:
                if check_string in content:
                    print(f"  ✅ {check_name}")
                else:
                    print(f"  ❌ {check_name} - FALTA")
                    all_good = False
        except Exception as e:
            print(f"  ⚠️  Error leyendo archivo: {e}")
            all_good = False
    
    print("\n" + "="*60)
    if all_good:
        print("✅ TODOS LOS ARCHIVOS ESTÁN CORRECTOS")
    else:
        print("⚠️  ALGUNOS ARCHIVOS NECESITAN REVISIÓN")
    print("="*60)
    
    return all_good

if __name__ == '__main__':
    print("🔧 Aplicando cambios Flutter con CRLF fix...")
    print("=" * 60)
    
    try:
        apply_cartillas_service_changes()
        print("\n✅ Cambios aplicados!")
        
        # Verificar todo
        verify_all_changes()
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
