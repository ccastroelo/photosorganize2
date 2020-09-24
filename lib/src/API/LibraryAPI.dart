import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:photosorganize/src/model/Album.dart';
import 'package:photosorganize/src/model/MediaItem.dart';
import 'HTTPClient.dart';
import 'package:http/http.dart' as http;

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/photoslibrary'
//    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);

class LibraryAPI {
  final httpClient = HTTPClient();
  final servidor = "https://photoslibrary.googleapis.com/v1/";
  GoogleSignInAccount _currentUser;


  static final LibraryAPI _libraryAPI = new LibraryAPI._internal();

  factory LibraryAPI() {
    return _libraryAPI;
  }

  LibraryAPI._internal();

    signInSilently() {
      _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
        _currentUser = account;
        return _currentUser;
    });
    _googleSignIn.signInSilently();
    }

  Future<List<Album>> _retrieveAlbums({String nextPageTokenPre}) async {
    var url = servidor + 'albums?pageSize=50' + (nextPageTokenPre != null ? '&pageToken=$nextPageTokenPre' : "");
    var header = await _currentUser.authHeaders;
    final http.Response response = await httpClient.getRequest(url, header: header);

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

  Future<List<String>> _retrieveMediasIdFromAlbum({Album album, String nextPageTokenPre}) async {
    var body = {'albumId': album.id, 'pageSize': 100, 'pageToken': nextPageTokenPre};

    var url = servidor+'mediaItems:search';
    final http.Response response = await httpClient.post(url, postData: body, header: await _currentUser.authHeaders);
    final Map<String, dynamic> data = json.decode(response.body);
    final String nextPageToken = data['nextPageToken'];

    List<String> localIdMedias = _pickIdMediasWithAlbum(data);
    if (nextPageToken != null) {
      sleep(const Duration(seconds: 2));
      localIdMedias += await _retrieveMediasIdFromAlbum(album: album, nextPageTokenPre: nextPageToken);
    }
    return localIdMedias;
  }

  List<String> _pickIdMediasWithAlbum(Map<String, dynamic> data) {
    final List<dynamic> connections = data['mediaItems'];
    final List<String> listMediasId = connections.map((mediaJson) => mediaJson['id'].toString()).toList();
    return listMediasId;
  }

  Future<List<MediaItem>> getMediasItens({String nextPageTokenPre}) async {
    var url = servidor+'mediaItems?pageSize=100'+(nextPageTokenPre != null ? '&pageToken=$nextPageTokenPre' : "");
    final http.Response response = await httpClient.getRequest(url, header: await _currentUser.authHeaders);
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
    final List<MediaItem> listMediaItems = connections.map((mediaJson) => MediaItem.fromJson(mediaJson)).toList();
    return listMediaItems;
  }

  Future<List<String>> getMediasIdFromAlbums(albums, indice) async {
    final album = albums[indice];
    List<String> idMedias = [];
    if (indice < albums.length - 1) {
      idMedias = await getMediasIdFromAlbums(albums, indice + 1);
    }
    sleep(const Duration(seconds: 2));
    idMedias += await _retrieveMediasIdFromAlbum(album: album);
    return idMedias;
  }



/*  Future<List<Resultado>> getListaResultados() async {
    List<Resultado> resultados = [];
    var response =
        await httpClient.getRequest(servidorToken, servidor + "/resultados");
    var json = jsonDecode(response.body);
    var jsonArray = json["resultados"];
    for (var item in jsonArray) {
      resultados.add(Resultado.fromJsonResultados(item));
    }
    return resultados;
  }

  Future<Resultado> getResultado(String idEleicao) async {
    var response = await httpClient.getRequest(
        servidorToken, servidor + "/eleicao/" + idEleicao + "/resultado",
        tokenUsuario: usuario.token);
    print("response.Body");

    print(response.body);
    var json = jsonDecode(response.body);
    final resultado = Resultado.fromJson(json["resultado"]);
    return resultado;
  }

  Future<List<Eleicao>> getListaEleicoes() async {
    List<Eleicao> eleicoes = [];
    var response = await httpClient.getRequest(
        servidorToken, servidor + "/eleitor/" + usuario.ident.toString(),
        tokenUsuario: usuario.token);
    var json = jsonDecode(response.body);
    var jsonArray = json["eleicoes"];
    for (var item in jsonArray) {
      eleicoes.add(Eleicao.fromJsonEleicoes(item));
    }
    return eleicoes;
  }

    Future<List<Candidato>> getCandidatos(String idEleicao) async {
    List<Candidato> candidatos = [];
    var response = await httpClient.getRequest(
        servidorToken, servidor + "/eleicao/" + idEleicao + "/candidatos",
        tokenUsuario: usuario.token);
    var json = jsonDecode(response.body);
    var jsonArray = json["eleicao"];
    for (var item in jsonArray) {
      candidatos.add(Candidato.fromJson(item));
    }
    return candidatos;
  }  */

}
