//import 'package:photosorganize/src/model/Album.dart';

class MediaItem {

final String id;
final String description;
final String baseUrl;
final String mimeType;
List<String> albums;
bool marcado = false;

MediaItem({this.id, this.description, this.baseUrl, this.mimeType, this.albums});

MediaItem.fromJson(Map<String, dynamic> json) 
    : id= json['id'],
      description= json['description'],
      baseUrl= json['baseUrl'],
      mimeType= json['mimeType'],
      albums= [];

Map<String, dynamic> toJson() =>
{
  'id' : id,
  'description' : description,
  'baseUrl' : baseUrl,
  'mimeType' : mimeType,
  'albums' : albums
};

marcaDesmarca(){
  marcado = !marcado;
}

}