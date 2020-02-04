import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'pages/home_page.dart';
import 'model/model.dart';
import 'model/macro.dart';

import './generated/i18n.dart';
import 'forget_theme.dart';
import 'package:provider/provider.dart';
import './notifier/notifier.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intro_slider/slide_object.dart';
import 'package:intro_slider/intro_slider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  notificationsPlugin = FlutterLocalNotificationsPlugin();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  prefs = await SharedPreferences.getInstance();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        DBOperation.retrieveTasks(),
        DBOperation.retrieveProjects(),
        DBOperation.retrieveLabels()
      ]),
      builder: (context, snapshot) {
        final String lanCode = prefs.getString('lanCode') ?? 'zh';
        final bool lightTheme = prefs.getBool('theme') ?? true;
        final bool showIsDone = prefs.getBool('showIsDone') ?? false;
        final bool firstRun = prefs.getBool('firstRun') ?? true;
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<TasksNotifier>.value(
                  value: TasksNotifier(t: snapshot.data[0], s: showIsDone)),
              ChangeNotifierProvider<ProjectsNotifier>.value(
                  value: ProjectsNotifier(p: snapshot.data[1])),
              ChangeNotifierProvider<LabelsNotifier>.value(
                  value: LabelsNotifier(l: snapshot.data[2])),
              ChangeNotifierProvider<Setting>.value(
                  value: Setting(lanCode: lanCode, isLightTheme: lightTheme))
            ],
            child: Consumer<Setting>(
                builder: (context, setting, _) => MaterialApp(
                    locale: setting.locale,
                    debugShowCheckedModeBanner: false,
                    title: 'forget',
                    home: Builder(builder: (context) {
                      if (firstRun) {
                        return IntroPage(context);
                      } else {
                        return HomePage();
                      }
                    }),
                    theme: setting.lightTheme
                        ? forgetLightTheme()
                        : forgetDarkTheme(), //forgetDarkTheme,forgetLightTheme
                    localizationsDelegates: const [
                      S.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      CupertinoLocalizationsDelegate()
                    ],
                    supportedLocales: S.delegate.supportedLocales)),
          );
        } else {
          return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: lightTheme ? forgetLightTheme() : forgetDarkTheme(),
              home: WelcomePage(lanCode: lanCode));
        }
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  final String lanCode;
  const WelcomePage({Key key, @required this.lanCode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(lanCode == 'zh' ? '欢迎使用' : 'Welcome to',
                style: Theme.of(context).textTheme.display2),
            Text('Forget', style: Theme.of(context).textTheme.display1),
            Text('Veni Vidi Vici', style: Theme.of(context).textTheme.display1)
          ],
        ),
      ),
    );
  }
}

class IntroPage extends StatelessWidget {
  List<Slide> slides = [];

  final String intro_title_1 = "脑中的事情太多？\nToo many stuffs in your head?";
  final String intro_title_2 = "分配你的任务\nAssign your tasks";
  final String intro_title_3 = "如果某件事情太复杂\nIf something is too complex";
  final String intro_body_1 = "把它们都记在Forget中吧。\nWrite them down in Forget.";
  final String intro_body_2 = "下一步行动——可以马上完成或者需要尽快完成的任务。\n"
      "Next Move - tasks that can be accomplished immediately or need to be accomplished as soon as possible.\n"
      "计划 ——需要某个特定时间进行的任务。\n"
      "Plan - Tasks that need to be done at a specific time.\n"
      "等待——不是很紧急或者需要待定的任务。\n"
      "Waiting - not very urgent or undetermined.";
  final String intro_body_3 = "创建一个项目来管理它，在项目下面可以添加多条任务。\nCreate a project to manage it.Multiple tasks can be added under the project.";

  Slide _slide(BuildContext context, String img, String title, String description, Color color){
    return Slide(
        title: title,
        maxLineTitle: 5,
        centerWidget: Image.asset(img),
        description: description,
        styleTitle: TextStyle(fontSize: 15, color: Colors.white),
        styleDescription: TextStyle(fontSize: 13, color: Colors.white),
        backgroundColor: color);
  }

  IntroPage(BuildContext parentContext) {
    slides.add(_slide(parentContext, 'placeholder/intro_img_1.png', intro_title_1, intro_body_1, Colors.grey));
    slides.add(_slide(parentContext, 'placeholder/intro_img_2.png', intro_title_2, intro_body_2, Colors.grey));
    slides.add(_slide(parentContext, 'placeholder/intro_img_3.png', intro_title_3, intro_body_3, Colors.grey));
  }

  VoidCallback onDonePress(BuildContext context) {
    return () => Navigator.pushReplacement(
        context,
        PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) {
          return HomePage();
        }, transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
            ) {
          return FadeTransition(
//position: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)).animate(animation),
            opacity: Tween<double>(begin: 0, end: 1).animate(animation),
            child: child,
          );
        }));
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(slides: slides, onDonePress: onDonePress(context));
  }
}
