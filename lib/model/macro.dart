import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/cupertino.dart';
import 'model.dart';
import '../generated/i18n.dart';
import '../pages/task_detail_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../notifier/notifier.dart';
import 'package:provider/provider.dart';
import '../widgets/cells.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../forget_icons.dart';

FlutterLocalNotificationsPlugin notificationsPlugin;

double screenWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double screenHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

IconData iconDataOfFilter(TaskType type) {
  switch (type) {
    case TaskType.unassigned:
      return ForgetIcon.unassigned;
    case TaskType.nextMove:
      return Icons.play_arrow;
    case TaskType.plan:
      return Icons.calendar_today;
    case TaskType.wait:
      return Icons.access_time;
  }
}

BorderRadius cellRadius = BorderRadius.circular(4);

const double cellHeight = 56;

final String oneDriveURL =
    'https://login.microsoftonline.com/common/oauth2/v2.0/authorize?'
    'client_id=04f758af-9e5b-4b09-b50b-de9b656c8a23'
    '&scope=files.readwrite%20offline_access'
    '&response_type=code'
    '&redirect_uri=msal04f758af-9e5b-4b09-b50b-de9b656c8a23://auth';

Random randomWorker = Random.secure();

Duration longDuration = Duration(milliseconds: 300);
Duration shortDuration = Duration(milliseconds: 100);

String stringOfFilter(TaskType type, BuildContext context) {
  switch (type) {
    case TaskType.unassigned:
      return S.of(context).unassigned;
    case TaskType.nextMove:
      return S.of(context).next_move;
    case TaskType.plan:
      return S.of(context).plan;
    case TaskType.wait:
      return S.of(context).wait;
  }
}

add_task_callback(
    BuildContext context, Task task, TasksNotifier tasksNotifier) {
  Navigator.push<Task>(
      context,
      PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) {
        return TaskDetailPage(task: task);
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
      })).then((value) {
    if (value == null) {
      return;
    }
    if (value.text == null || value.text.isEmpty) {
      return;
    }
    tasksNotifier.insert(value);
  });
}

Future<bool> showComfirmDialog(
    BuildContext context, String title, String descrip) {
  return showDialog<bool>(
      context: context,
      builder: (context) => SimpleDialog(
            title: Text(title),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            children: <Widget>[
              Container(
                  margin: EdgeInsets.only(left: 24, right: 24),
                  child: Text(descrip)),
              ButtonBar(
                children: <Widget>[
                  FlatButton(
                      child: Text(S.of(context).cancel),
                      onPressed: () => Navigator.pop(context, false)),
                  FlatButton(
                      child: Text(S.of(context).OK,
                          style: TextStyle(color: Colors.red)),
                      onPressed: () => Navigator.pop(context, true))
                ],
              )
            ],
          ));
}

SharedPreferences prefs;

int getSortWay(bool homePage, TaskType taskType) {
  int sortWay;
  if (homePage) {
    sortWay = prefs.getInt('homeSortWay') ?? 0;
  } else {
    switch (taskType) {
      case TaskType.unassigned:
        sortWay = prefs.getInt('unassignedSortWay') ?? 0;
        break;
      case TaskType.nextMove:
        sortWay = prefs.getInt('nextMoveSortWay') ?? 0;
        break;
      case TaskType.plan:
        sortWay = prefs.getInt('planSortWay') ?? 0;
        break;
      case TaskType.wait:
        sortWay = prefs.getInt('waitSortWay') ?? 0;
    }
  }
  return sortWay;
}

add_task_cupertino_callback(
    BuildContext context, Task task, TasksNotifier tasksNotifier) {
  Navigator.push<Task>(context, CupertinoPageRoute(builder: (context) {
    return TaskDetailPage(task: task);
  })).then((value) {
    if (value == null) {
      return;
    }
    if (value.text == null || value.text.isEmpty) {
      return;
    }
    tasksNotifier.insert(value);
  });
}

GestureTapCallback showTodoSnackBar(BuildContext context) {
  return () => Scaffold.of(context).showSnackBar(SnackBar(
      content: Text('TODO', textAlign: TextAlign.center),
      duration: Duration(milliseconds: 200)));
}

class CupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const CupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  SynchronousFuture<_DefaultCupertinoLocalizations> load(Locale locale) {
    return SynchronousFuture<_DefaultCupertinoLocalizations>(
        _DefaultCupertinoLocalizations(locale.languageCode));
  }

  @override
  bool shouldReload(CupertinoLocalizationsDelegate old) => false;
}

class _DefaultCupertinoLocalizations extends CupertinoLocalizations {
  _DefaultCupertinoLocalizations(this._languageCode)
      : assert(_languageCode != null);

  final DefaultCupertinoLocalizations _en =
      const DefaultCupertinoLocalizations();
  final String _languageCode;

  final Map<String, Map<String, String>> _dict = <String, Map<String, String>>{
    'en': <String, String>{
      'alert': 'Alert',
      'copy': 'Copy',
      'paste': 'Paste',
      'cut': 'Cut',
      'selectAll': 'Select all'
    },
    'zh': <String, String>{
      'alert': '提醒',
      'copy': '复制',
      'paste': '粘贴',
      'cut': '剪切',
      'selectAll': '全选'
    }
  };

  @override
  String get alertDialogLabel => _get('alert');

  @override
  String get anteMeridiemAbbreviation => _en.anteMeridiemAbbreviation;

  @override
  String get postMeridiemAbbreviation => _en.postMeridiemAbbreviation;

  @override
  String get copyButtonLabel => _get('copy');

  @override
  String get cutButtonLabel => _get('cut');

  @override
  String get pasteButtonLabel => _get('paste');

  @override
  String get selectAllButtonLabel => _get('selectAll');

  @override
  DatePickerDateOrder get datePickerDateOrder => _en.datePickerDateOrder;

  @override
  DatePickerDateTimeOrder get datePickerDateTimeOrder =>
      _en.datePickerDateTimeOrder;

  @override
  String datePickerDayOfMonth(int dayIndex) =>
      _en.datePickerDayOfMonth(dayIndex);

  @override
  String datePickerHour(int hour) => _en.datePickerHour(hour);

  @override
  String datePickerHourSemanticsLabel(int hour) =>
      _en.datePickerHourSemanticsLabel(hour);

  @override
  String datePickerMediumDate(DateTime date) => _en.datePickerMediumDate(date);

  @override
  String datePickerMinute(int minute) => _en.datePickerMinute(minute);

  @override
  String datePickerMinuteSemanticsLabel(int minute) =>
      _en.datePickerMinuteSemanticsLabel(minute);

  @override
  String datePickerMonth(int monthIndex) => _en.datePickerMonth(monthIndex);

  @override
  String datePickerYear(int yearIndex) => _en.datePickerYear(yearIndex);

  @override
  String timerPickerHour(int hour) => _en.timerPickerHour(hour);

  @override
  String timerPickerHourLabel(int hour) => _en.timerPickerHourLabel(hour);

  @override
  String timerPickerMinute(int minute) => _en.timerPickerMinute(minute);

  @override
  String timerPickerMinuteLabel(int minute) =>
      _en.timerPickerMinuteLabel(minute);

  @override
  String timerPickerSecond(int second) => _en.timerPickerSecond(second);

  @override
  String timerPickerSecondLabel(int second) =>
      _en.timerPickerSecondLabel(second);

  String _get(String key) {
    return _dict[_languageCode][key];
  }
}

class SearchWorker extends SearchDelegate<String> {
  final TaskCellShowingIn cellShowingIn;
  final int projectID;
  final int taskType;

  SearchWorker(this.cellShowingIn, {this.projectID = 0, this.taskType = 0});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(
          Icons.clear,
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () => query = '',
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
//    return ActionChip(
//        onPressed: () => close(context, ''),
//        backgroundColor: Colors.blue,
//        elevation: 6,
//        avatar: Icon(Icons.arrow_back),
//        label: Text(
//          'back',
//          style: Theme.of(context)
//              .textTheme
//              .title
//              .copyWith(color: Colors.white),
//        ));

    return IconButton(
      icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _build(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _build(context);
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context);
  }

  Widget _build(BuildContext context) {
    if (query.isEmpty) {
      return Container();
    } else {
      List<Task> tasks;
      switch (cellShowingIn) {
        case TaskCellShowingIn.tasks:
          tasks = Provider.of<TasksNotifier>(context).tasks(0);
          break;
        case TaskCellShowingIn.filter:
          tasks =
              Provider.of<TasksNotifier>(context).tasksInFilter(taskType, 0);
          break;
        case TaskCellShowingIn.project:
          tasks =
              Provider.of<TasksNotifier>(context).tasksInProject(projectID, 0);
          break;
        case TaskCellShowingIn.label:
          tasks = [];
          break;
      }

      List<Task> suggestTasks = tasks
          .where((t) => t.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
      return ChangeNotifierProvider<ListPageStateNotifier>.value(
        value: ListPageStateNotifier(),
        child: ListView.builder(
            itemBuilder: (context, index) {
              return TaskCell(
                  taskID: suggestTasks[index].id, parentContext: context);
            },
            itemCount: suggestTasks.length),
      );
    }
  }
}
