import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class FileSaver {
  static Future<void> saveFile(Uint8List bytes, String fileName) async {
    Directory? directory;
    if (Platform.isWindows) {
      directory = await getDownloadsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    // Fallback if downloads directory is null (e.g. some android versions or errors)
    directory ??= await getApplicationDocumentsDirectory();

    final String path = '${directory.path}/$fileName';
    final File file = File(path);
    await file.writeAsBytes(bytes);
    
    // Open the file
    await OpenFile.open(path);
  }
}
