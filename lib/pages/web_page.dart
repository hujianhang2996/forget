import 'package:flutter/material.dart';

import 'task_detail_page.dart';
import '../widgets/cells.dart';
import '../widgets/customize_button.dart';
import '../model/model.dart';
import '../model/macro.dart';
import 'package:provider/provider.dart';
import '../notifier/notifier.dart';
import 'dart:convert';
import 'dart:io';
import 'package:oauth2/oauth2.dart' as oauth2;

class WebPage extends StatelessWidget {
  Widget build(BuildContext context) {
    getClient().then((client) {
      var result = client.read("http://example.com/protected-resources.txt");
      print(result);
    });
//    await credentialsFile.writeAsString(client.credentials.toJson());

    return Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            centerTitle: false,
            title: ActionChip(
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.purple,
                elevation: 6,
                avatar: Icon(Icons.arrow_back),
                label: Text(
                  'OneDrive',
                  style: Theme.of(context)
                      .textTheme
                      .title
                      .copyWith(color: Colors.white),
                ))),
        body: Container());
  }
}

Future<oauth2.Client> getClient() async {
  final authorizationEndpoint = Uri.parse(
      "https://login.microsoftonline.com/common/oauth2/v2.0/authorize");
  final tokenEndpoint =
      Uri.parse("https://login.microsoftonline.com/common/oauth2/v2.0/token");
  final identifier = "dbaa2965-9553-4e56-bfe8-c31e3b522519";
  final secret = "mgdusWFE2xAZ@[x:saVV-c2Hd7y7[p2-";
  final redirectUrl =
      Uri.parse("msauth://com.odyssey.forget/R2V6kZ6IllvaZdRwOCQTSmdkZXE%3D");
  final credentialsFile = new File("./credentials.json");
  var exists = await credentialsFile.exists();
  if (exists) {
    var credentials =
        new oauth2.Credentials.fromJson(await credentialsFile.readAsString());
    return new oauth2.Client(credentials,
        identifier: identifier, secret: secret);
  }
  var grant = new oauth2.AuthorizationCodeGrant(
      identifier, authorizationEndpoint, tokenEndpoint,
      secret: secret);
  print(grant.getAuthorizationUrl(redirectUrl));
}
