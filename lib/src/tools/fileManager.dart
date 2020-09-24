import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:photosorganize/src/model/MediaItem.dart';

class FileManager {

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/medias.txt');
  }

  Future<bool> get fileExist async {
    final file = await _localFile;
    return file.exists();
  }

  Future<List<MediaItem>> readMedias() async {
    try {
      final file = await _localFile;
      // Read the file
      String contents = file.readAsStringSync();
      print(contents);
      List medias = jsonDecode(contents);
      print(medias.length);

      // MediaItem.fromJson(media)
      return medias.map((media) => MediaItem.fromJson(media)).toList();
    } catch (e) {
      print(e);
      // If encountering an error, return 0
      return [];
    }
  }

  Future<void> writeMedias(List<MediaItem> medias) async {
    final file = await _localFile;
    String mediasStr = jsonEncode(medias);
    print(mediasStr);

    // Write the file
    file.writeAsStringSync(mediasStr);
  }

}