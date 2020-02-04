import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class OneDrive {
  static final String authorizeEndPoint = 'https://login.microsoftonline.com'
      '/common/oauth2/v2.0/authorize';
  static final String logOutEndPoint = 'https://login.microsoftonline.com'
      '/common/oauth2/v2.0/logout';
  static final String tokenEndPoint = 'https://login.microsoftonline.com'
      '/common/oauth2/v2.0/token';
  static final String clientID = 'dbaa2965-9553-4e56-bfe8-c31e3b522519';
  static final String redirectUri = 'msauth%3A%2F%2Fcom.odyssey.forget'
      '%2FR2V6kZ6IllvaZdRwOCQTSmdkZXE%253D';
  static final String matchRedirectUri = 'msauth://com.odyssey.forget'
      '/R2V6kZ6IllvaZdRwOCQTSmdkZXE%3D?code=';

  static void logIn(VoidCallback callback) async {
    final flutterWebviewPlugin = FlutterWebviewPlugin();
    String codeUrl = '$authorizeEndPoint'
        '?response_type=code'
        '&client_id=$clientID'
        '&redirect_uri=$redirectUri'
        '&scope=offline_access+files.readwrite.all+user.readwrite+openid';

    await flutterWebviewPlugin.launch(codeUrl);
    flutterWebviewPlugin.onUrlChanged.listen((String url) async {
      if (url.contains(matchRedirectUri)) {
        await flutterWebviewPlugin.close();
        Directory appDocDir = await getApplicationDocumentsDirectory();
        String appDocPath = appDocDir.path;
        var tokenResponse = await http.post(tokenEndPoint,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: 'client_id=$clientID'
                '&code=${url.split('=')[1]}'
                '&redirect_uri=$redirectUri'
                '&grant_type=authorization_code');
        File file = File(appDocPath + '/token.json');
        file.writeAsString(tokenResponse.body);
        callback();
      }
    });
  }

  static Future<Map<String, dynamic>> logInState() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    File tokenFile = File(appDocPath + '/token.json');
    bool fileExists = await tokenFile.exists();
    print('fileExists: $fileExists');
    if (fileExists) {
      String token = await refreshToken(tokenFile);
      var getResponse = await http.get(
          'https://graph.microsoft.com/v1.0/me',
          headers: {
            'Authorization': 'Bearer $token',
            'Host': 'graph.microsoft.com'
          });
      Map<String, dynamic> getResponseJson = json.decode(getResponse.body);
//      print(getResponse.body);
      return {'name': getResponseJson['displayName'], 'login': true};
//      return getResponse.body[0];
    } else {
      return {'name': '未登录', 'login': false};
    }
  }

  static void logOut() async{
    String codeUrl = '$logOutEndPoint'
        '?post_logout_redirect_uri=$redirectUri';

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    File tokenFile = File(appDocPath + '/token.json');
    bool fileExists = await tokenFile.exists();
    if(fileExists){
      await tokenFile.delete();
    }

    final flutterWebviewPlugin = FlutterWebviewPlugin();
    await flutterWebviewPlugin.launch(codeUrl);
    await flutterWebviewPlugin.close();
  }

  static Future<String> refreshToken(File tokenFile) async {
    String token = await tokenFile.readAsString();
    Map<String, dynamic> tokenJson = json.decode(token);
    var refreshRespone = await http.post(tokenEndPoint,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'client_id=$clientID'
            '&redirect_uri=$redirectUri'
            '&refresh_token=${tokenJson['refresh_token']}'
            '&grant_type=refresh_token');
    tokenFile.writeAsString(refreshRespone.body);
    Map<String, dynamic> newTokenJson = json.decode(refreshRespone.body);
    return newTokenJson['access_token'];
  }

  static void downLoad() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    File tokenFile = File(appDocPath + '/token.json');
    bool fileExists = await tokenFile.exists();
    if (fileExists) {
      String token = await refreshToken(tokenFile);

      var getResponse = await http.get(
          'https://graph.microsoft.com/v1.0/me/drive/root/children',
          headers: {
            'Authorization': 'Bearer $token',
            'Host': 'graph.microsoft.com'
          });
      Map<String, dynamic> filesJson = json.decode(getResponse.body);
      for (var file in filesJson['value']) {
        print(file['name']);
      }
    } else {
      print('登录失效，请重新登录');
    }
  }

  static void upLoad() {}
}
