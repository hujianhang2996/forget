import 'package:flutter/material.dart';
import '../model/model.dart';
import 'package:provider/provider.dart';
import '../model/time_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/macro.dart';

class TasksNotifier extends ChangeNotifier {
  bool _showIsDone;
  List<Task> _tasks;

  bool get showIsDone => _showIsDone;

  TasksNotifier({List<Task> t, bool s}) {
    _tasks = t ?? [];
    _showIsDone = s ?? false;
  }

  Task task(int id) {
    return _tasks.singleWhere((t) => t.id == id);
  }

  Future<void> _refresh() async {
    _tasks = await DBOperation.retrieveTasks();
    notifyListeners();
  }

  Future<void> _sortTasks(int sortBy) {
    if (sortBy == 0) {
      _tasks.sort((a, b) => b.id.compareTo(a.id));
    }
    if (sortBy == 1) {
      _tasks.sort((a, b) {
        if (a.taskType == 2 && b.taskType == 2) {
          return a.nextNotifaTime().compareTo(b.nextNotifaTime());
        } else {
          return a.taskType.compareTo(b.taskType);
        }
      });
    }
    if (sortBy == 2) {
      _tasks.sort((a, b) => b.priority.compareTo(a.priority));
    }
    _tasks.sort((a, b){
      if (a.isDone && b.isDone)return 0;
      if (a.isDone && !b.isDone)return 1;
      if (!a.isDone && b.isDone)return -1;
      if (!a.isDone && !b.isDone)return 0;
    });
  }

  Future<void> switchShowIsDone({bool newValue}) async {
    if (newValue == null){
      _showIsDone = !_showIsDone;
    }else{
      _showIsDone = newValue;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showIsDone', _showIsDone);
    notifyListeners();
  }

  List<Task> tasks(int sortBy, {String query}) {
    _sortTasks(sortBy);
    if (query == null) {
      return _tasks.where((t)=>_showIsDone ? true : !t.isDone).toList();
    } else {
      return _tasks
          .where((t) => query.isEmpty ? false : t.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  List<Task> tasksInProject(int projectID, int sortBy, {String query}) {
    _sortTasks(sortBy);
    if (query == null) {
      return _tasks.where((t) => t.projectID == projectID).toList().where((t)=>_showIsDone ? true : !t.isDone).toList();
    } else {
      return _tasks
          .where((t) => t.projectID == projectID)
          .toList()
          .where((t) => query.isEmpty ? false : t.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  List<Task> tasksInFilter(int taskType, int sortBy, {String query}) {
    _sortTasks(sortBy);
    if (query == null) {
      return _tasks.where((t) => t.taskType == taskType).toList().where((t)=>_showIsDone ? true : !t.isDone).toList();
    } else {
      return _tasks
          .where((t) => t.taskType == taskType)
          .toList()
          .where((t) => query.isEmpty ? false : t.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  List<Task> tasksInDate(DateTime date, int sortBy, {String query}) {
    _sortTasks(sortBy);
    if (query == null) {
      return _tasks.where((t) {
        if (t.taskType != 2) {
          return false;
        }
        switch (t.repeatWay) {
          case 0:
            return TimeUtil.isInSameDay(t.dateTime, date);
          case 1:
            return TimeUtil.compareInDay(date, DateTime.now()) >= 0;
          case 2:
            return t.weekDay.contains(date.weekday == 7 ? 0 : date.weekday) &&
                TimeUtil.compareInDay(date, DateTime.now()) >= 0;
        }
      }).toList().where((t)=>_showIsDone ? true : !t.isDone).toList();
    }else{
      return _tasks.where((t) {
        if (t.taskType != 2) {
          return false;
        }
        switch (t.repeatWay) {
          case 0:
            return TimeUtil.isInSameDay(t.dateTime, date);
          case 1:
            return TimeUtil.compareInDay(date, DateTime.now()) >= 0;
          case 2:
            return t.weekDay.contains(date.weekday == 7 ? 0 : date.weekday) &&
                TimeUtil.compareInDay(date, DateTime.now()) >= 0;
        }
      }).toList().where((t) => query.isEmpty ? false : t.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

  }

  List<Task> tasksWithLabel(int labelID) {
    return _tasks.where((task)=>task.labels.contains(labelID)).toList();
  }

  Future<void> insert(Task task) async {
    await DBOperation.insertTask(task);
    await _refresh();
  }

  Future<void> delete(int id) async {
    await DBOperation.deleteTask(id);
    await _refresh();
  }

  Future<void> deleteSeveral(List<int> ids) async {
    await DBOperation.deleteTasks(ids);
    await _refresh();
  }

  Future<void> update(Task task) async {
    await DBOperation.updateTask(task);
    await _refresh();
  }

  Future<void> switchDone(int id, {bool isDone}) async {
    await DBOperation.switchDoneOfTask(id, isDone: isDone);
    await _refresh();
  }

  Future<void> addTasksToProject(List<int> taskIDs, int projectID) async {
    await DBOperation.addTasksToProject(taskIDs, projectID);
    await _refresh();
  }

  Future<void> addLabelToTasks(List<int> taskIDs, int labelID) async {
    await DBOperation.addLabelToTasks(taskIDs, labelID);
    await _refresh();
  }
}

class ProjectsNotifier extends ChangeNotifier {
  List<Project> _projects;

  List<Project> get projects => _projects;

  ProjectsNotifier({List<Project> p}) {
    _projects = p ?? [];
  }

  Future<void> _refresh() async {
    _projects = await DBOperation.retrieveProjects();
    notifyListeners();
  }

  Project project(int id) {
    return _projects.singleWhere((p) => p.id == id);
  }

  Future<void> insert(Project project) async {
    await DBOperation.insertProject(project);
    await _refresh();
  }

  Future<void> delete(int id, BuildContext context) async {
    await DBOperation.deleteProject(id);
    await Provider.of<TasksNotifier>(context)._refresh();
    await _refresh();
  }

  Future<void> update(Project project, BuildContext context) async {
    await DBOperation.updateProject(project);
    await Provider.of<TasksNotifier>(context)._refresh();
    await _refresh();
  }
}

class LabelsNotifier extends ChangeNotifier {
  List<Label> _labels;

  List<Label> get labels => _labels;

  LabelsNotifier({List<Label> l}) {
    _labels = l ?? [];
  }

  Future<void> _refresh() async {
    _labels = await DBOperation.retrieveLabels();
    notifyListeners();
  }

  Future<void> insert(Label label) async {
    await DBOperation.insertLabel(label);
    await _refresh();
  }

  Future<void> delete(int id) async {
    await DBOperation.deleteLabel(id);
    await _refresh();
  }
}

class ListPageStateNotifier extends ChangeNotifier {
  bool _isShowingTask = true;
  bool _isEditing = false;
  bool _isShowingAll = false;
  int _sortWay;
  DateTime _selectedDate = DateTime.now();
  List<int> _selectedTasks = [];

  List<int> get selectedTasks => _selectedTasks;
  bool get isShowingTask => _isShowingTask;
  bool get isEditing => _isEditing;
  bool get isShowingAll => _isShowingAll;
  int get sortWay => _sortWay;
  DateTime get selectedDate => _selectedDate;

  ListPageStateNotifier({int s}){
    _sortWay = s ?? 0;
  }

  void switchIsShowingTask({bool newValue}) {
    if (newValue == null) {
      _isShowingTask = !_isShowingTask;
    } else {
      _isShowingTask = newValue;
    }
    notifyListeners();
  }

  void switchIsEditing({bool newValue}) {
    if (newValue == null) {
      _isEditing = !_isEditing;
    } else {
      _isEditing = newValue;
    }
    notifyListeners();
  }

  void switchIsShowingAll({bool newValue}) {
    if (newValue == null) {
      _isShowingAll = !_isShowingAll;
    } else {
      _isShowingAll = newValue;
    }
    notifyListeners();
  }

  void changeSelected(int id) {
    if (_selectedTasks.contains(id)) {
      _selectedTasks.remove(id);
    } else {
      _selectedTasks.add(id);
    }
    notifyListeners();
  }

  Future<void> changeSortWay(BuildContext context, TaskCellShowingIn cellShowingIn, TaskType taskType, int projectID, {int newValue}) async {
    if (newValue == null) {
      _sortWay = _sortWay == 2 ? 0 : _sortWay + 1;
    } else {
      _sortWay = newValue;
    }

    switch (cellShowingIn) {
      case TaskCellShowingIn.tasks:
        await prefs.setInt('homeSortWay', _sortWay);
        break;
      case TaskCellShowingIn.filter:
        switch (taskType) {
          case TaskType.unassigned:
            await prefs.setInt('unassignedSortWay', _sortWay);
            break;
          case TaskType.nextMove:
            await prefs.setInt('nextMoveSortWay', _sortWay);
            break;
          case TaskType.plan:
            await prefs.setInt('planSortWay', _sortWay);
            break;
          case TaskType.wait:
            await prefs.setInt('waitSortWay', _sortWay);
        }
        break;
      case TaskCellShowingIn.project:
        await DBOperation.changeSortWayOfProject(projectID, newSortWay: newValue);
        await Provider.of<ProjectsNotifier>(context)._refresh();
        break;
      case TaskCellShowingIn.label:
    }
    notifyListeners();
  }

  void unselectAll() {
    _selectedTasks = [];
    notifyListeners();
  }

  void selectAll(List<Task> tasks) {
    _selectedTasks = tasks
        .map((t) => t.id)
        .toList();
    notifyListeners();
  }

  void selectDate(DateTime newValue) {
    _selectedDate = newValue;
    notifyListeners();
  }
}

class Setting extends ChangeNotifier {
  Locale _locale;
  bool _lightThheme;
  bool _login;

  Locale get locale => _locale;
  bool get lightTheme => _lightThheme;
  bool get login => _login;

  Setting({String lanCode, bool isLightTheme, bool isLogin}){
    _locale = Locale(lanCode ?? 'zh');
    _lightThheme = isLightTheme ?? true;
    _login = isLogin ?? false;
  }

  _refresh() {
    String lanCode = prefs.getString('lanCode') ?? 'zh';
    _locale = Locale(lanCode);
    _lightThheme = prefs.getBool('theme') ?? true;
    notifyListeners();
  }

  void setLocale(Locale newLocale){
    _locale = newLocale;
    notifyListeners();
  }

  void setLogin(bool isLogin){
    _login = isLogin;
    notifyListeners();
  }

  Future<void> changeLan(String lanCode) async{
    await prefs.setString('lanCode', lanCode);
    _refresh();
  }

  Future<void> changeTheme(bool lightTheme) async{
    await prefs.setBool('theme', lightTheme);
    _refresh();
  }
}
