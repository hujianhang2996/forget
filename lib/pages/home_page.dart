import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'task_detail_page.dart';
import '../widgets/customize_button.dart';
import '../widgets/cells.dart';
import '../model/model.dart';
import '../model/macro.dart';

import '../generated/i18n.dart';
import 'package:provider/provider.dart';
import '../notifier/notifier.dart';
import 'dart:async';
import '../model/onedrive.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  AnimationController _controller;
  PageController _pageController;
  AnimationController _menuController;
  ListPageStateNotifier _listPageStateNotifier =
      ListPageStateNotifier(s: getSortWay(true, TaskType.unassigned));
  final int random = randomWorker.nextInt(8);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: longDuration);
    _menuController = AnimationController(vsync: this, duration: shortDuration);
    _pageController = PageController(initialPage: 0);

    var initializationSettingsAndroid =
        AndroidInitializationSettings("ic_noti_icon");
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    notificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (prefs.getBool('firstRun') ?? true) {
      prefs.setBool('firstRun', false);
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ListPageStateNotifier>.value(
            value: _listPageStateNotifier)
      ],
      child: Consumer4<TasksNotifier, ProjectsNotifier, ListPageStateNotifier,
          Setting>(
        builder: (context, tasksNotifier, projectsNotifier,
                listPageStateNotifier, setting, _) =>
            Scaffold(
                appBar: PreferredSize(
                    child: AppBar(
                      automaticallyImplyLeading: false,
                      elevation: 0,
                      centerTitle: false,
                      title: AnimatedChip(_controller, _pageController),
                      actions: <Widget>[
                        MoreMenu(_menuController, TaskCellShowingIn.tasks),
                        EditButton(_menuController),
                        Builder(
                          builder: (builderContext) => IconButton(
                              icon: Icon(Icons.menu),
                              color: Theme.of(context).iconTheme.color,
                              onPressed: () =>
                                  Scaffold.of(builderContext).openEndDrawer()),
                        ),
                        SizedBox(width: 12)
                      ],
                    ),
                    preferredSize: Size.fromHeight(60)),
                body: Stack(
                  children: [
                    PageView(
                      physics: NeverScrollableScrollPhysics(),
                      controller: _pageController,
                      children: <Widget>[
                        _task_table(
                            tasksNotifier.tasks(listPageStateNotifier.sortWay)),
                        _project_table(projectsNotifier.projects,
                            tasksNotifier.tasks(listPageStateNotifier.sortWay))
                      ],
                    ),
                    EditMenu(_menuController, TaskCellShowingIn.tasks)
                  ],
                ),
                endDrawer: Container(
                  width: screenWidth(context) * 0.7,
                  color: Theme.of(context).accentColor,
                  padding: const EdgeInsets.only(left: 32, top: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(S.of(context).setting,
                          style: Theme.of(context).textTheme.title),
                      SizedBox(height: 20),
                      FlatButton.icon(
                          onPressed: () {
                            setting.changeLan(
                                setting.locale.languageCode == 'en'
                                    ? 'zh'
                                    : 'en');
                          },
                          icon: Icon(Icons.language),
                          label: Text(S.of(context).language)),
                      FlatButton.icon(
                          onPressed: () {
                            setting
                                .changeTheme(setting.lightTheme ? false : true);
                          },
                          icon: Icon(Icons.settings_cell),
                          label: Text(S.of(context).theme)),
                      FutureBuilder<String>(
                        future: OneDrive.logInState(),
                        builder: (context, snapshot) {
                          print('ssssssssssssss');
                          if (snapshot.hasData) {
                            return FlatButton.icon(
                                onPressed: OneDrive.logIn,
                                icon: Icon(Icons.cloud),
                                label: Text(snapshot.data));
                          } else {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        },
                      ),
                      FlatButton.icon(
                          onPressed: OneDrive.logOut,
                          icon: Icon(Icons.cloud),
                          label: Text('Log Out')),
                      FlatButton.icon(
                          onPressed: OneDrive.downLoad,
                          icon: Icon(Icons.cloud_download),
                          label: Text('download'))
                    ],
                  ),
                ),
                floatingActionButton: Offstage(
                  offstage: listPageStateNotifier.isEditing,
                  child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return FloatingActionButton(
                          backgroundColor: ColorTween(
                                  begin: Colors.deepOrange, end: Colors.blue)
                              .animate(_controller)
                              .value,
                          onPressed: listPageStateNotifier.isShowingTask
                              ? () => add_task_callback(
                                  context, Task(), tasksNotifier)
                              : () => _add_project(projectsNotifier),
                          child: Icon(Icons.add, color: Colors.white),
                        );
                      }),
                )),
      ),
    );
  }

  // 构建列表
  Widget _task_table(List<Task> tasks) {
    if (tasks.isEmpty) {
      return PlaceHolder(random);
    }
    Widget listView = ListView.builder(
        itemBuilder: (context, index) => TaskCell(
              taskID: tasks[index].id,
              showingIn: TaskCellShowingIn.tasks,
              parentContext: context,
            ),
        itemCount: tasks.length);
    return listView;
  }

  Widget _project_table(List<Project> projects, List<Task> tasks) {
    Widget listView = ListView.builder(
      itemBuilder: (context, index) {
        return ProjectCell(
            projectID: projects[index].id, parentContext: context);
      },
      itemCount: projects.length,
    );
    Column column = Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            FilterCell(filter: TaskType.unassigned, parentContext: context),
            FilterCell(filter: TaskType.nextMove, parentContext: context)
          ],
        ),
        Row(
          children: <Widget>[
            FilterCell(filter: TaskType.plan, parentContext: context),
            FilterCell(filter: TaskType.wait, parentContext: context)
          ],
        ),
        Expanded(child: projects.isEmpty ? Container() : listView)
      ],
    );
    return column;
  }

  //新建project
  _add_project(ProjectsNotifier projectsNotifier) {
    showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(S.of(context).add_project),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            children: <Widget>[
              Container(
                  margin: EdgeInsets.only(left: 24, right: 24),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                        hintText: S.of(context).input_project_hint,
                        border: InputBorder.none),
                    onSubmitted: (str) {
                      Navigator.pop(context, str);
                    },
                  ))
            ],
          );
        }).then((value) {
      if (value == null || value.toString().isEmpty) {
        return;
      }
      projectsNotifier.insert(Project(text: value));
    });
  }

  //通知回调
  Future<void> onSelectNotification(String payload) async {
    final int taskID = int.parse(payload);
    final List<Task> _taskList =
        await DBOperation.retrieveTasks(taskID: taskID);
    if (_taskList.isEmpty) {
      return;
    }
    Navigator.push(
        context,
        PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) {
          return TaskDetailPage(task: _taskList.first);
        }, transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: const Offset(0.0, 0.0),
            ).animate(animation),
            child: child,
          );
        })).then((value) async {
      if (value == null) {
        return;
      }
      if (value.text == null || value.text.isEmpty) {
        return;
      }
      Provider.of<TasksNotifier>(context).update(value);
    });
  }

  Future<void> onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    print('-----------onDidReceiveLocalNotification---------------');
  }

  //oneDrive

}
