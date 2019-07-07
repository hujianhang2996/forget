import 'dart:typed_data';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'macro.dart';
import 'time_util.dart';
import '../generated/i18n.dart';
import 'dart:math';

class Task {
  int id;
  bool isDone;
  int priority;
  String text;
  int projectID;
  String project_text;
  int taskType;
  List<int> labels;
  int repeatWay;
  DateTime dateTime;
  List<int> weekDay;

  Color priorityColor() {
    switch (this.priority) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
    }
  }

  String plan_description(BuildContext context) {
    if (taskType != 2) {
      return '';
    }
    switch (repeatWay) {
      case 0:
        return '${dateTime.month}-${dateTime.day}-${dateTime.hour}:${dateTime.minute}';
      case 1:
        return '${dateTime.hour}:${dateTime.minute},' + S.of(context).everyDay;
      case 2:
        return '${dateTime.hour}:${dateTime.minute},' + S.of(context).everyWeek;
    }
  }

  DateTime nextNotifaTime() {
    if (taskType != 2) {
      return null;
    }
    switch (repeatWay) {
      case 0:
        return dateTime;
      case 1:
        return DateTime(DateTime.now().year, DateTime.now().month,
                    DateTime.now().day, dateTime.hour, dateTime.minute)
                .isBefore(DateTime.now())
            ? dateTime.add(Duration(days: 1))
            : dateTime;
      case 2:
        int currentWeekDay =
            DateTime.now().weekday == 7 ? 0 : DateTime.now().weekday;
        int nextWeekDay = weekDay.firstWhere((d) => currentWeekDay <= d,
            orElse: () => weekDay.first);
        if (nextWeekDay > currentWeekDay) {
          return DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day, dateTime.hour, dateTime.minute)
              .add(Duration(days: nextWeekDay - currentWeekDay));
        }
        if (nextWeekDay == currentWeekDay) {
          return DateTime(DateTime.now().year, DateTime.now().month,
                      DateTime.now().day, dateTime.hour, dateTime.minute)
                  .isBefore(DateTime.now())
              ? DateTime(DateTime.now().year, DateTime.now().month,
                      DateTime.now().day, dateTime.hour, dateTime.minute)
                  .add(Duration(days: 7))
              : DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day, dateTime.hour, dateTime.minute);
        }
        if (nextWeekDay < currentWeekDay) {
          return DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day, dateTime.hour, dateTime.minute)
              .add(Duration(days: 7 + nextWeekDay - currentWeekDay));
        }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isDone': isDone ? 1 : 0,
      'priority': priority,
      'text': text,
      'projectID': projectID,
      'taskType': taskType,
      'repeatWay': taskType == 2 ? repeatWay : 0,
      'dateTime': taskType == 2 ? dateTime.toString() : null
    };
  } //供新增数据使用

  Map<String, dynamic> toMapForOutput() {
    return {
      'id': id,
      'isDone': isDone,
      'priority': priority,
      'text': text,
      'projectID': projectID,
      'taskType': taskType,
      'project': project_text,
      'labels': labels,
      'repeatWay': repeatWay,
      'dateTime': dateTime,
      'weakDay': weekDay,
      'nextNotif': nextNotifaTime()
    };
  } //供打印使用

  Task(
      {this.id,
      this.isDone = false,
      this.priority = 1,
      this.text = '',
      this.projectID = 0,
      this.project_text,
      this.taskType = 0,
      this.labels = const [],
      this.repeatWay = 0,
      this.dateTime,
      this.weekDay = const []});

  Task.copyfrom(Task task) {
    this.id = task.id;
    this.isDone = task.isDone;
    this.priority = task.priority;
    this.text = task.text;
    this.projectID = task.projectID;
    this.project_text = task.project_text;
    this.taskType = task.taskType;
    this.labels = task.labels.map((i) => i).toList();
    this.repeatWay = task.repeatWay;
    this.dateTime = task.dateTime;
    this.weekDay = task.weekDay.map((i) => i).toList();
  }
}

class Project {
  int id;
  int sortWay;
  String text;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sortWay': sortWay,
      'text': text,
    };
  }

  Project({this.id, this.text, this.sortWay = 0});
}

class Label {
  int id;
  String text;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
    };
  }

  Label({this.id, this.text});

  Label.copyfrom(Label label) {
    this.id = label.id;
    this.text = label.text;
  }
}

class TaskLabel {
  int id;
  int taskID;
  int labelID;

  Map<String, dynamic> toMap() {
    return {'id': id, 'taskID': taskID, 'labelID': labelID};
  }

  TaskLabel({this.id, this.taskID, this.labelID});
}

enum TaskType { unassigned, nextMove, plan, wait }
enum TaskCellShowingIn { tasks, project, label, filter }

class DBOperation {
  static Future<Database> _getDatabase() async {
    return await openDatabase(
        join(await getDatabasesPath(), 'forget_database.db'),
        onCreate: (db, version) async {
      await db.execute(
          "CREATE TABLE projects(id INTEGER PRIMARY KEY AUTOINCREMENT, sortWay INTEGER, text TEXT);");
      await db.execute(
          "CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "isDone INTEGER, priority INTEGER, text TEXT, projectID INTEGER, taskType INTEGER, repeatWay INTEGER, dateTime TEXT);");
      await db.execute(
          "CREATE TABLE labels(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT);");
      await db.execute(
          "CREATE TABLE tasklabels(id INTEGER PRIMARY KEY AUTOINCREMENT, "
          "taskID INTEGER, labelID INTEGER);");
      await db.execute(
          "CREATE TABLE notifactions(id INTEGER PRIMARY KEY AUTOINCREMENT, "
          "taskID INTEGER, weekDay INTEGER);");
    }, version: 1);
  }

  //task
  static Future<void> insertTask(Task task) async {
    assert(task.id == null);
    final Database db = await _getDatabase();

    int newTaskID = await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    for (int labelID in task.labels) {
      await db.insert(
        'taskLabels',
        {'id': null, 'taskID': newTaskID, 'labelID': labelID},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    if (task.taskType == 2) {
      switch (task.repeatWay) {
        case 0:
        case 1:
          int notifID = await db.insert(
            'notifactions',
            {'id': null, 'taskID': newTaskID, 'weekDay': -1},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          _scheduleNotification(notifID, task, newTaskID, -1);
          break;
        case 2:
          for (int notif in task.weekDay) {
            int notifID = await db.insert(
              'notifactions',
              {'id': null, 'taskID': newTaskID, 'weekDay': notif},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            _scheduleNotification(notifID, task, newTaskID, notif);
          }
      }
    }
  }

  static Future<List<Task>> retrieveTasks(
      {int taskID = 0, int sortBy = 0}) async {
    assert(sortBy == 0 || sortBy == 1 || sortBy == 2);
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> maps = taskID == 0
        ? await db.query('tasks')
        : await db.query('tasks', where: 'id = ?', whereArgs: [taskID]);
    final List<Map<String, dynamic>> projectMaps = await db.query('projects');
    final List<Map<String, dynamic>> taskLabelMaps =
        await db.query('taskLabels');

    List<Task> taskList = [];
    for (Map map in maps) {
      final projects = projectMaps.where((m) => m['id'] == map['projectID']);
      final project_text = projects.isEmpty ? null : projects.first['text'];

      //通过map['id']求出对应的label的List<Map>
      final List<Map> labelMaps =
          taskLabelMaps.where((m) => m['taskID'] == map['id']).toList();
      //提取出labelMaps中的label的id
      List<int> labelIDList =
          List.generate(labelMaps.length, (i) => labelMaps[i]['labelID']);
      final List<Map<String, dynamic>> notifMaps = await db
          .query('notifactions', where: 'taskID = ?', whereArgs: [map['id']]);
      List<int> notifDescriptionList =
          List.generate(notifMaps.length, (i) => notifMaps[i]['weekDay'])
            ..sort();

      taskList.add(Task(
          id: map['id'],
          isDone: map['isDone'] == 1 ? true : false,
          priority: map['priority'],
          text: map['text'],
          projectID: map['projectID'],
          project_text: project_text,
          taskType: map['taskType'],
          labels: labelIDList,
          repeatWay: map['repeatWay'],
          dateTime:
              map['taskType'] != 2 ? null : DateTime.parse(map['dateTime']),
          weekDay: map['repeatWay'] == 2 ? notifDescriptionList : []));
    }
    if (sortBy == 1) {
      taskList.sort((a, b) {
        if (a.taskType == 2 && b.taskType == 2) {
          return b.nextNotifaTime().compareTo(a.nextNotifaTime());
        } else {
          return b.taskType.compareTo(a.taskType);
        }
      });
    }
    if (sortBy == 2) {
      taskList.sort((a, b) => a.priority.compareTo(b.priority));
    }
    return taskList.reversed.toList();
  }

//  static Future<List<Task>> retrieveTasksInProject(int projectID,
//      {int sortBy = 0}) async {
//    assert(sortBy == 0 || sortBy == 1 || sortBy == 2);
//    final Database db = await _getDatabase();
//    final List<Map<String, dynamic>> maps =
//        await db.query('tasks', where: 'projectID = ?', whereArgs: [projectID]);
//    final List<Map<String, dynamic>> taskLabelMaps =
//        await db.query('taskLabels');
//    final List<Map<String, dynamic>> projects =
//        await db.query('projects', where: 'id = ?', whereArgs: [projectID]);
//    final String projectText = projects.first['text'];
//    List<Task> taskList = [];
//
//    for (Map map in maps) {
//      //通过map['id']求出对应的label的List<Map>
//      final List<Map> labelMaps =
//          taskLabelMaps.where((m) => m['taskID'] == map['id']).toList();
//      //提取出labelMaps中的label的id
//      List<int> labelIDList =
//          List.generate(labelMaps.length, (i) => labelMaps[i]['labelID']);
//      final List<Map<String, dynamic>> notifMaps = await db
//          .query('notifactions', where: 'taskID = ?', whereArgs: [map['id']]);
//      List<int> notifDescriptionList =
//          List.generate(notifMaps.length, (i) => notifMaps[i]['weekDay'])
//            ..sort();
//
//      taskList.add(
//        Task(
//            id: map['id'],
//            priority: map['priority'],
//            text: map['text'],
//            projectID: map['projectID'],
//            project_text: projectText,
//            taskType: map['taskType'],
//            labels: labelIDList,
//            repeatWay: map['repeatWay'],
//            dateTime:
//                map['taskType'] != 2 ? null : DateTime.parse(map['dateTime']),
//            weekDay: map['repeatWay'] == 2 ? notifDescriptionList : []),
//      );
//    }
//    if (sortBy == 1) {
//      taskList.sort((a, b) {
//        if (a.taskType == 2 && b.taskType == 2) {
//          return b.nextNotifaTime().compareTo(a.nextNotifaTime());
//        }else{
//          return b.taskType.compareTo(a.taskType);
//        }
//      });
//    }
//    if (sortBy == 2) {
//      taskList.sort((a, b) => a.priority.compareTo(b.priority));
//    }
//    return taskList.reversed.toList();
//  }
//
//  static Future<List<Task>> retrieveTasksInFilter(int taskType,
//      {int sortBy = 0, DateTime selectedDay}) async {
//    assert(sortBy == 0 || sortBy == 1 || sortBy == 2);
//    final Database db = await _getDatabase();
//    final List<Map<String, dynamic>> maps =
//        await db.query('tasks', where: 'taskType = ?', whereArgs: [taskType]);
//    final List<Map<String, dynamic>> projectMaps = await db.query('projects');
//    final List<Map<String, dynamic>> taskLabelMaps =
//        await db.query('taskLabels');
//    List<Task> taskList = [];
//
//    for (Map map in maps) {
//      final projects = projectMaps.where((m) => m['id'] == map['projectID']);
//      final project_text = projects.isEmpty ? null : projects.first['text'];
//      //通过map['id']求出对应的label的List<Map>
//      final List<Map> labelMaps =
//          taskLabelMaps.where((m) => m['taskID'] == map['id']).toList();
//      //提取出labelMaps中的label的id
//      List<int> labelIDList =
//          List.generate(labelMaps.length, (i) => labelMaps[i]['labelID']);
//      final List<Map<String, dynamic>> notifMaps = await db
//          .query('notifactions', where: 'taskID = ?', whereArgs: [map['id']]);
//      List<int> notifDescriptionList =
//          List.generate(notifMaps.length, (i) => notifMaps[i]['weekDay'])
//            ..sort();
//
//      taskList.add(
//        Task(
//            id: map['id'],
//            priority: map['priority'],
//            text: map['text'],
//            projectID: map['projectID'],
//            project_text: project_text,
//            taskType: map['taskType'],
//            labels: labelIDList,
//            repeatWay: map['repeatWay'],
//            dateTime:
//                map['taskType'] != 2 ? null : DateTime.parse(map['dateTime']),
//            weekDay: map['repeatWay'] == 2 ? notifDescriptionList : []),
//      );
//    }
//
//    if (taskType == 2 && selectedDay != null) {
//      taskList = taskList.where((t) {
//        switch (t.repeatWay) {
//          case 0:
//            return TimeUtil.isInSameDay(t.dateTime, selectedDay);
//          case 1:
//            return TimeUtil.compareInDay(selectedDay, DateTime.now()) >= 0;
//          case 2:
//            return t.weekDay.contains(
//                    selectedDay.weekday == 7 ? 0 : selectedDay.weekday) &&
//                TimeUtil.compareInDay(selectedDay, DateTime.now()) >= 0;
//        }
//      }).toList();
//    }
//
//    if (sortBy == 1) {
//      taskList.sort((a, b) {
//        if (a.taskType == 2 && b.taskType == 2) {
//          return b.nextNotifaTime().compareTo(a.nextNotifaTime());
//        }else{
//          return b.taskType.compareTo(a.taskType);
//        }
//      });
//    }
//    if (sortBy == 2) {
//      taskList.sort((a, b) => a.priority.compareTo(b.priority));
//    }
//    return taskList.reversed.toList();
//  }

  static Future<void> updateTask(Task task) async {
    assert(task.id != null);
    final db = await _getDatabase();
    final List<Map<String, dynamic>> taskLabelMaps =
        await db.query('tasklabels', where: 'taskID = ?', whereArgs: [task.id]);
    final List<Map<String, dynamic>> notifMaps = await db
        .query('notifactions', where: 'taskID = ?', whereArgs: [task.id]);
    final List<int> currentLabelIDList =
        List.generate(taskLabelMaps.length, (i) => taskLabelMaps[i]['labelID']);
    await db.update(
      'tasks',
      task.toMap(),
      where: "id = ?",
      whereArgs: [task.id],
    );
    for (int labelID in task.labels) {
      if (currentLabelIDList.contains(labelID)) {
        currentLabelIDList.remove(labelID);
      } else {
        await db.insert(
          'taskLabels',
          {'id': null, 'taskID': task.id, 'labelID': labelID},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    for (int labelID in currentLabelIDList) {
      await db.delete('tasklabels',
          where: 'taskID = ? AND labelID = ?', whereArgs: [task.id, labelID]);
    }

    for (Map notif in notifMaps) {
      await notificationsPlugin.cancel(notif['id']);
    }
    if (task.isDone) return;

    await db.delete('notifactions', where: 'taskID = ?', whereArgs: [task.id]);
    if (task.taskType == 2) {
      switch (task.repeatWay) {
        case 0:
        case 1:
          int notifID = await db.insert(
            'notifactions',
            {'id': null, 'taskID': task.id, 'weekDay': -1},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          _scheduleNotification(notifID, task, task.id, -1);
          break;
        case 2:
          for (int notif in task.weekDay) {
            int notifID = await db.insert(
              'notifactions',
              {'id': null, 'taskID': task.id, 'weekDay': notif},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            _scheduleNotification(notifID, task, task.id, notif);
          }
      }
    }
  }

  static Future<void> deleteTask(int id) async {
    final Database db = await _getDatabase();
    await db.delete('tasklabels', where: 'taskID = ?', whereArgs: [id]);
    final List<Map<String, dynamic>> notifMaps =
        await db.query('notifactions', where: 'taskID = ?', whereArgs: [id]);
    for (Map notif in notifMaps) {
      await notificationsPlugin.cancel(notif['id']);
    }
    await db.delete('notifactions', where: 'taskID = ?', whereArgs: [id]);
    await db.delete(
      'tasks',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  static Future<void> switchDoneOfTask(int id, {bool isDone}) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> maps =
        await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    final Map<String, dynamic> taskMap = maps.first;
    final List<Map<String, dynamic>> notifMaps =
        await db.query('notifactions', where: 'taskID = ?', whereArgs: [id]);
    bool finalIsDone = isDone ?? (taskMap['isDone'] == 1 ? false : true);
    Task newTask = Task(
        id: taskMap['id'],
        isDone: finalIsDone,
        priority: taskMap['priority'],
        text: taskMap['text'],
        projectID: taskMap['projectID'],
        taskType: taskMap['taskType'],
        repeatWay: taskMap['repeatWay'],
        dateTime: taskMap['taskType'] != 2
            ? null
            : DateTime.parse(taskMap['dateTime']));

    await db.update(
      'tasks',
      newTask.toMap(),
      where: "id = ?",
      whereArgs: [id],
    );

    for (Map notif in notifMaps) {
      await notificationsPlugin.cancel(notif['id']);
    }

    if (!finalIsDone) {
      if (taskMap['taskType'] == 2) {
        switch (taskMap['repeatWay']) {
          case 0:
          case 1:
            _scheduleNotification(notifMaps.first['id'], newTask, id, -1);
            break;
          case 2:
            for (Map notifMap in notifMaps) {
              _scheduleNotification(
                  notifMap['id'], newTask, id, notifMap['weekDay']);
            }
        }
      }
    }
  }

  static Future<void> deleteTasks(List<int> ids) async {
    final Database db = await _getDatabase();
    for (int id in ids) {
      await db.delete('tasklabels', where: 'taskID = ?', whereArgs: [id]);
      final List<Map<String, dynamic>> notifMaps =
          await db.query('notifactions', where: 'taskID = ?', whereArgs: [id]);
      for (Map notif in notifMaps) {
        await notificationsPlugin.cancel(notif['id']);
      }
      await db.delete('notifactions', where: 'taskID = ?', whereArgs: [id]);
      await db.delete(
        'tasks',
        where: "id = ?",
        whereArgs: [id],
      );
    }
  }

  static Future<void> addTasksToProject(
      List<int> taskIDs, int projectID) async {
    final db = await _getDatabase();
    for (int taskID in taskIDs) {
      final List<Map<String, dynamic>> maps =
          await db.query('tasks', where: 'id = ?', whereArgs: [taskID]);
      final Map<String, dynamic> taskMap = maps.first;
//      taskMap['projectID'] = projectID;
      await db.update(
        'tasks',
        {
          'id': taskMap['id'],
          'isDone': taskMap['isDone'],
          'priority': taskMap['priority'],
          'text': taskMap['text'],
          'projectID': projectID,
          'taskType': taskMap['taskType'],
          'repeatWay': taskMap['repeatWay'],
          'dateTime': taskMap['dateTime']
        },
        where: "id = ?",
        whereArgs: [taskID],
      );
    }
  }

  static Future<void> addLabelToTasks(List<int> taskIDs, int labelID) async {
    final db = await _getDatabase();
    for (int taskID in taskIDs) {
      final List<Map<String, dynamic>> taskLabelMaps = await db
          .query('tasklabels', where: 'taskID = ?', whereArgs: [taskID]);
      final List<int> currentLabelIDList = List.generate(
          taskLabelMaps.length, (i) => taskLabelMaps[i]['labelID']);

      if (!currentLabelIDList.contains(labelID)) {
        await db.insert(
          'taskLabels',
          {'id': null, 'taskID': taskID, 'labelID': labelID},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  //project
  static Future<void> insertProject(Project project) async {
    assert(project.id == null);
    final Database db = await _getDatabase();
    await db.insert(
      'projects',
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Project>> retrieveProjects() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('projects');

    List<Project> projectList = [];

    for (Map map in maps) {
      projectList.add(
          Project(id: map['id'], text: map['text'], sortWay: map['sortWay']));
    }
    return projectList.reversed.toList();
  }

  static Future<void> updateProject(Project project) async {
    assert(project.id != null);
    final db = await _getDatabase();
    await db.update(
      'projects',
      project.toMap(),
      where: "id = ?",
      whereArgs: [project.id],
    );
  }

  static Future<void> changeSortWayOfProject(int id, {int newSortWay}) async {
    final db = await _getDatabase();
    final List<Map<String, dynamic>> maps =
        await db.query('projects', where: 'id = ?', whereArgs: [id]);
    final Map<String, dynamic> projectMap = maps.first;

    int finalSortWay = newSortWay ??
        (projectMap['sortWay'] == 2 ? 0 : projectMap['sortWay'] + 1);

    await db.update(
      'projects',
      {
        'id': projectMap['id'],
        'text': projectMap['text'],
        'sortWay': finalSortWay
      },
      where: "id = ?",
      whereArgs: [id],
    );
  }

  static Future<void> deleteProject(int id) async {
    final Database db = await _getDatabase();

    final List<Map<String, dynamic>> taskMap = await db.query(
      'tasks',
      where: "projectID = ?",
      whereArgs: [id],
    );
    List<int> taskList = List.generate(taskMap.length, (i) {
      return taskMap[i]['id'];
    });

    for (int i in taskList) {
      await db.delete('tasklabels', where: 'taskID = ?', whereArgs: [i]);
      await notificationsPlugin.cancel(i);

      final List<Map<String, dynamic>> notifMaps =
          await db.query('notifactions', where: 'taskID = ?', whereArgs: [i]);
      for (Map notif in notifMaps) {
        await notificationsPlugin.cancel(notif['id']);
      }
      await db.delete('notifactions', where: 'taskID = ?', whereArgs: [i]);
    }
    await db.delete(
      'tasks',
      where: "projectID = ?",
      whereArgs: [id],
    );
    await db.delete(
      'projects',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  //label
  static Future<int> insertLabel(Label label) async {
    assert(label.id == null);
    final Database db = await _getDatabase();
    final int id = await db.insert(
      'labels',
      label.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<List<Label>> retrieveLabels() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('labels');
    return List.generate(maps.length, (i) {
      return Label(id: maps[i]['id'], text: maps[i]['text']);
    });
  }

  static Future<void> updateLabel(Label label) async {
    assert(label.id != null);
    final db = await _getDatabase();
    await db.update(
      'labels',
      label.toMap(),
      where: "id = ?",
      whereArgs: [label.id],
    );
  }

  static Future<void> deleteLabel(int id) async {
    final Database db = await _getDatabase();
    await db.delete('tasklabels', where: 'labelID = ?', whereArgs: [id]);
    await db.delete(
      'labels',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  //private functions
  static Future<void> _scheduleNotification(
      int notifiID, Task task, int taskID, int weekDay) async {
//    return;
    var vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;
    vibrationPattern[2] = 5000;
    vibrationPattern[3] = 2000;

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'forget_id', 'Forget', 'forget notifactions',
        sound: 'very_long_sound',
        icon: 'ic_noti_icon',
        largeIcon: 'ic_noti_icon',
        importance: Importance.Max,
        priority: Priority.High,
        largeIconBitmapSource: BitmapSource.Drawable,
        vibrationPattern: vibrationPattern,
        enableLights: true,
        color: const Color.fromARGB(255, 150, 150, 150),
        ledColor: const Color.fromARGB(255, 150, 150, 150),
        ledOnMs: 1000,
        ledOffMs: 500);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails(
        presentSound: true,
        sound: "slow_spring_board.aiff",
        presentBadge: true);
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    switch (task.repeatWay) {
      case 0:
        DateTime scheduledNotificationDateTime = task.dateTime;
        await notificationsPlugin.schedule(
            notifiID,
            task.text,
            task.project_text ?? '',
            scheduledNotificationDateTime,
            platformChannelSpecifics,
            payload: taskID.toString());
        break;
      case 1:
        Time scheduledNotificationDateTime =
            Time(task.dateTime.hour, task.dateTime.minute);
        await notificationsPlugin.showDailyAtTime(
            notifiID,
            task.text,
            task.project_text ?? '',
            scheduledNotificationDateTime,
            platformChannelSpecifics,
            payload: taskID.toString());
        break;
      case 2:
        Time scheduledNotificationDateTime =
            Time(task.dateTime.hour, task.dateTime.minute);
        await notificationsPlugin.showWeeklyAtDayAndTime(
            notifiID,
            task.text,
            task.project_text ?? '',
            Day(weekDay + 1),
            scheduledNotificationDateTime,
            platformChannelSpecifics,
            payload: taskID.toString());
    }
  }
}
