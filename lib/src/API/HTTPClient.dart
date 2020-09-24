import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class HTTPClient {
  Future<bool> testaConexao() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return (result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<http.Response> request(String tipo, String url,
      {Map<String, String> header, Map postData}) async {
    var conexao = await testaConexao();
    if (!conexao) {
      throw new Exception(
          "Não foi possível acessar o servidor, verifique sua conexão com a internet.");
    }

    var body;
    if (postData != null) {
      body = jsonEncode(postData);
    }
    var response;
    if (tipo == 'POST') {
      response = await http.post(url, body: body, headers: header);
    } else {
      response = await http.get(url, headers: header);
    }
    final int statusCode = response.statusCode;
    if (statusCode < 200 || statusCode > 400 || json == null) {
      var body = jsonDecode(utf8.decode(response.bodyBytes));
      print("Body");
      print(body);
      var mensagem = "Ocorreu um erro, tente novamente mais tarde.";
      if (body["mensagem"] != null) {
        mensagem = body["mensagem"];
      }
      throw new Exception(mensagem);
    }
    print("response.body");
    print(response.body);

    return response;
  }

  Future<http.Response> post(String url,
      {Map postData, Map header}) async {
    var response = await this.request('POST', url,
        postData: postData, header: header);
    return response;
  }

  Future<http.Response> getRequest(String url, {Map header}) async {
    var response = await this
        .request('GET', url, header: header);
    return response;
  }
}

/*
  func request(tipo: String, tokenGravitee: String, url: String, body: [String : Any]?, usuario: Usuario?, completionHandler: @escaping (HTTPURLResponse?, [String : Any]) -> ()) {
        let url = URL(string: url)
//        print("url: \(String(describing: url))")
        var request = URLRequest(url: url!)
        request.httpMethod = tipo
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if usuario != nil {
            let token = "JWT \(usuario!.token!)"
            request.addValue(token, forHTTPHeaderField: "Authorization")
        }
        request.addValue(tokenGravitee, forHTTPHeaderField: "X-Gravitee-Api-Key")
        if body != nil {
//            print(body!)
            let postData = try? JSONSerialization.data(withJSONObject: body!, options: [])
            request.httpBody = postData
        }
        
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
     //       print("** \(url)")
     //       print("** \(data)")
     //       print("** \(response)")
     //       print("** \(error)")  
            let httpResponse = response as? HTTPURLResponse
            
            if (error != nil) {
                completionHandler(httpResponse, [:])
            }else{
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String : Any]
                    completionHandler(httpResponse, json)
                }catch let error as NSError{
                    completionHandler(httpResponse, [:])
                    print(error)
                }
            }
        }).resume()
    }

*/
