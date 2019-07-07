import 'package:flutter/material.dart';

import 'task_detail_page.dart';
import '../widgets/cells.dart';
import '../widgets/customize_button.dart';
import '../model/model.dart';
import '../model/macro.dart';
import 'package:provider/provider.dart';
import '../notifier/notifier.dart';
//import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

//class WebPage extends StatelessWidget {
//  Widget build(BuildContext context) {
//    return Scaffold(
//        appBar: AppBar(
//            automaticallyImplyLeading: false,
//            elevation: 0,
//            centerTitle: false,
//            title: ActionChip(
//                onPressed: () => Navigator.pop(context),
//                backgroundColor: Colors.purple,
//                elevation: 6,
//                avatar: Icon(Icons.arrow_back),
//                label: Text(
//                  'OneDrive',
//                  style: Theme.of(context)
//                      .textTheme
//                      .title
//                      .copyWith(color: Colors.white),
//                ))),
//        body: WebView(
//          initialUrl: oneDriveURL,
//          javascriptMode: JavascriptMode.unrestricted,
//        ));
//  }
//}
