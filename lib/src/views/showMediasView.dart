import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:photosorganize/src/model/Album.dart';
import 'package:photosorganize/src/model/MediaItem.dart';
import 'package:transparent_image/transparent_image.dart';
import "package:http/http.dart" as http;

class ShowMediasView extends StatefulWidget {
  final List<MediaItem> medias;
  final List<Album> albums;
  final GoogleSignInAccount _currentUser;

  @override
  _ShowMediasViewState createState() => _ShowMediasViewState();

  ShowMediasView(this.medias, this.albums, this._currentUser);
}

class _ShowMediasViewState extends State<ShowMediasView> {
  int marcados = 0;

  @override
  Widget build(BuildContext context) {
    return _grid(context, widget.medias);
  }

  Widget _grid(context, List<MediaItem> medias) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Selecionados: $marcados"),
        backgroundColor: Colors.amber[500],
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.photo_album),
            onPressed: marcados == 0
                ? null
                : () {
                    _settingModalBottomSheet(context);
                  },
          )
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: medias.length,
        itemBuilder: (context, index) {
          return GestureDetector(
              onTap: () => marcarDesmarcar(medias[index], false),
              onLongPress: () => marcarDesmarcar(medias[index], true),
              child: mediaContainer(medias[index]));
        },
      ),
    );
  }

  Widget mediaContainer(MediaItem media) {
    if (!media.marcado) {
      return FadeInImage.memoryNetwork(
          fadeInDuration: Duration(milliseconds: 75),
          fadeOutDuration: Duration(milliseconds: 175),
          placeholder: kTransparentImage,
          image: media.baseUrl,
          height: 300.0,
          width: double.infinity,
          fit: BoxFit.cover);
    } else {
      return Stack(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(10.0),
            color: Colors.grey[300],
            child: Image.network(media.baseUrl,
                height: 280.0, width: double.infinity, fit: BoxFit.cover),
          )
        ],
      );
    }
  }

  marcarDesmarcar(MediaItem media, bool lngPress) {
    print(media.marcado);
    if (lngPress || (!lngPress && marcados > 0)) {
      marcados = marcados + (media.marcado ? -1 : 1);
      setState(() {
        media.marcaDesmarca(); // se true, vira false,   se false, vira true
      });
    }
  }

  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: widget.albums.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  height: 50,
                  child: ListTile(
                      title: Text(widget.albums[index].title),
                      onTap: () {
                        print(widget.albums[index].id);
                        _moveMediaToAlbum(widget.albums[index].id);
                      }),
                );
              });
        });
  }

  Future _moveMediaToAlbum(albumId) async {
    List<String> selecionados = widget.medias.where((media) => media.marcado).map((media) => media.id).toList();
    var body = json.encode({'mediaItemIds': selecionados});
    var url =
        'https://photoslibrary.googleapis.com/v1/albums/$albumId:batchAddMediaItems';
      print(albumId);
    try {
      final http.Response response = await http.post(url,
          headers: await widget._currentUser.authHeaders, body: body);
          print(body);
      if (response.statusCode != 200) {
//      setState(() {
        print(response.statusCode);
        print("response. Check logs for details. ${response.body}");
//      });
      } else {
        print("OK!");
      }
    } catch (e) {
      print(e);
    }
  }
}
