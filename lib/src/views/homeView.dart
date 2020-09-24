import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert' show json;

import "package:http/http.dart" as http;
import 'package:photosorganize/src/model/Album.dart';
import 'package:photosorganize/src/model/MediaItem.dart';
import 'package:photosorganize/src/tools/fileManager.dart';
import 'dart:io';

import 'package:photosorganize/src/views/showMediasView.dart';

class HomeView extends StatefulWidget {
  final GoogleSignInAccount _currentUser;
  final bool useFile;

  HomeView(this._currentUser, this.useFile);

  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String activityText;
  List<Album> albums;
  List<String> idMediaWithAlbum;
  List<MediaItem> mediaItems;
  List<MediaItem> mediaWithOutAlbum;
  bool continuar = false;

  Future<List<Album>> _retrieveAlbums({String nextPageTokenPre}) async {
    var url = 'https://photoslibrary.googleapis.com/v1/albums?pageSize=50' +
        (nextPageTokenPre != null ? '&pageToken=$nextPageTokenPre' : "");
    final http.Response response = await http.get(
      url,
      headers: await widget._currentUser.authHeaders,
    );
    if (response.statusCode != 200) {
      setState(() {
        activityText = "People API gave a ${response.statusCode} "
            "response. Check logs for details.";
      });
      print('People API ${response.statusCode} response: ${response.body}');
      return null;
    }
    final Map<String, dynamic> data = json.decode(response.body);
    final String nextPageToken = data['nextPageToken'];
    List<Album> localAlbums = _pickAlbumsData(data);
    if (nextPageToken != null) {
      localAlbums += await Future.delayed(const Duration(seconds: 2),
          () => _retrieveAlbums(nextPageTokenPre: nextPageToken));
    }
    return localAlbums;
  }

  List<Album> _pickAlbumsData(Map<String, dynamic> data) {
    final List<dynamic> connections = data['albums'];
    final List<Album> listAlbums =
        connections.map((albumJson) => Album.fromJson(albumJson)).toList();

    return listAlbums;
  }

  Future<List<String>> _retrieveMediasIdFromAlbum(
      {Album album, String nextPageTokenPre}) async {
    var body = json.encode(
        {'albumId': album.id, 'pageSize': 100, 'pageToken': nextPageTokenPre});

    var url = 'https://photoslibrary.googleapis.com/v1/mediaItems:search';
    final http.Response response = await http.post(url,
        headers: await widget._currentUser.authHeaders, body: body);
    if (response.statusCode != 200) {
      setState(() {
        activityText = "People API gave a ${response.statusCode} "
            "response. Check logs for details. ${response.body}";
      });
      print('People API ${response.statusCode} response: ${response.body}');
      print(url);
      return null;
    }
    final Map<String, dynamic> data = json.decode(response.body);
    final String nextPageToken = data['nextPageToken'];
    List<String> localIdMedias = _pickIdMediasWithAlbum(data);
    if (nextPageToken != null) {
      sleep(const Duration(seconds: 2));
      localIdMedias += await _retrieveMediasIdFromAlbum(
          album: album, nextPageTokenPre: nextPageToken);
    }
    return localIdMedias;
  }

  List<String> _pickIdMediasWithAlbum(Map<String, dynamic> data) {
    final List<dynamic> connections = data['mediaItems'];
    final List<String> listMediasId =
        connections.map((mediaJson) => mediaJson['id'].toString()).toList();
    return listMediasId;
  }

  Future<void> _handleGetAlbums() async {
    setState(() {
      activityText = "Loading albums info...";
    });

    albums = await _retrieveAlbums();

    setState(() {
      if (albums != null) {
        activityText = "Albums retrieve Totals: " + albums.length.toString();
      } else {
        activityText = "No albums to organize.";
      }
    });

    idMediaWithAlbum = await getMediasIdFromAlbums(0);
    setState(() {
      activityText = "Medias Retrieve From Albums Total: " +
          idMediaWithAlbum.length.toString();
    });

    mediaItems = await getMediasItens();
    setState(() {
      activityText = "Medias Retrieve Total: " + mediaItems.length.toString();
    });

    mediaWithOutAlbum = filterMediaWithOutAlbum();
    setState(() {
      activityText =
          "Total Medias Without Album: " + mediaWithOutAlbum.length.toString();
      continuar = true;
    });
  }

  filterMediaWithOutAlbum() {
    List<MediaItem> localMediaWithOutAlbum = mediaItems.where( (item) => !idMediaWithAlbum.contains(item.id)).toList(); 
    FileManager().writeMedias(localMediaWithOutAlbum);
    return localMediaWithOutAlbum;
  }

  Future<List<MediaItem>> getMediasItens({String nextPageTokenPre}) async {
    var url =
        'https://photoslibrary.googleapis.com/v1/mediaItems?pageSize=100' +
            (nextPageTokenPre != null ? '&pageToken=$nextPageTokenPre' : "");
    final http.Response response = await http.get(
      url,
      headers: await widget._currentUser.authHeaders,
    );
    if (response.statusCode != 200) {
      setState(() {
        activityText = "People API gave a ${response.statusCode} "
            "response. Check logs for details.";
      });
      print('People API ${response.statusCode} response: ${response.body}');
      return null;
    }
    final Map<String, dynamic> data = json.decode(response.body);
    final String nextPageToken = data['nextPageToken'];
    List<MediaItem> localMediaItems = _pickMediasData(data);
    if (nextPageToken != null) {
      localMediaItems += await Future.delayed(const Duration(seconds: 2),
          () => getMediasItens(nextPageTokenPre: nextPageToken));
    }
    return localMediaItems;
  }

  List<MediaItem> _pickMediasData(Map<String, dynamic> data) {
    final List<dynamic> connections = data['mediaItems'];
    final List<MediaItem> listMediaItems =
        connections.map((mediaJson) => MediaItem.fromJson(mediaJson)).toList();

    return listMediaItems;
  }

  Future<List<String>> getMediasIdFromAlbums(indice) async {
    final album = albums[indice];
    List<String> idMedias = [];
    setState(() {
      activityText = "Retrieve Media from album" + album.title;
    });
    if (indice < albums.length - 1) {
      idMedias = await getMediasIdFromAlbums(indice + 1);
    }
    sleep(const Duration(seconds: 2));
    idMedias += await _retrieveMediasIdFromAlbum(album: album);
    setState(() {
      activityText =
          "Medias Retrieve from album subTotal: " + idMedias.length.toString();
    });

    return idMedias;
  }

  Future<void> _loadMediasFile() async {
    setState(() {
      activityText = "Loading albums info...";
    });
    albums = await _retrieveAlbums();
    setState(() {
      if (albums != null) {
        activityText = "Albums retrieve Totals: " + albums.length.toString();
      } else {
        activityText = "No albums to organize.";
      }
    });
    mediaWithOutAlbum =await FileManager().readMedias();
    setState(() {
      activityText =
          "Total Medias Without Album: " + mediaWithOutAlbum.length.toString();
      continuar = true;
    });
  }


  @override
  initState() {
    super.initState();
    if (!widget.useFile) {
      _handleGetAlbums();
    }else{
      _loadMediasFile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(activityText, style: TextStyle(fontSize: 15)),
              Padding(
                padding: EdgeInsets.only(top: 20),
              ),
              FlatButton(
                child: Text("Continue", style: TextStyle(color: Colors.white),),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ShowMediasView(mediaWithOutAlbum, albums, widget._currentUser)),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
