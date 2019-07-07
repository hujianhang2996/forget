import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../widgets/calendar.dart';
import '../widgets/time_picker.dart';
import '../model/model.dart';
import '../model/macro.dart';
import '../model/time_util.dart';
import '../generated/i18n.dart';
import 'package:provider/provider.dart';
import '../notifier/notifier.dart';
import 'package:provider/provider.dart';

class TaskDetailPage extends StatefulWidget {
  TaskDetailPage({Key key, this.task}) : super(key: key);
  Task task;

  @override
  State<StatefulWidget> createState() {
    return _TaskDetailPageState();
  }
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  Task task;
  final FocusNode _focusNode = FocusNode();

  final DateTime startTime = DateTime(2018);
  PageController _pageController;
  TextEditingController _textController;

  List<String> _temp = [];

  @override
  void initState() {
    super.initState();
    task = Task.copyfrom(widget.task);
    _focusNode.addListener(_focusNodeListener);
    _pageController = PageController(
      initialPage: TimeUtil.date2page(DateTime.now(), startTime),
    );
    _textController = TextEditingController.fromValue(TextEditingValue(
        text: task.text,
        selection: TextSelection.fromPosition(TextPosition(
            affinity: TextAffinity.downstream, offset: task.text.length))));
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusNodeListener);
    _pageController.dispose();
    super.dispose();
  }

  Future<Null> _focusNodeListener() async {
//    if (_focusNode.hasFocus) {
//      print('TextField got the focus');
//    } else {
//      print('TextField lost the focus');
//    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).accentColor,
        appBar: PreferredSize(
            child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: FlatButton(
                    shape: CircleBorder(),
                    child: Icon(Icons.block),
                    onPressed: () {
                      _focusNode.unfocus();
                      Navigator.pop(context, null);
                    }),
                actions: <Widget>[
                  PopupMenuButton<int>(
                    icon: Icon(Icons.more_horiz,
                        color: Theme.of(context).iconTheme.color),
                    itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 0,
                            child: Row(children: <Widget>[
                              Icon(task.isDone ? Icons.undo : Icons.done),
                              SizedBox(width: 10),
                              Text(
                                  task.isDone
                                      ? S.of(context).undo
                                      : S.of(context).done,
                                  style: Theme.of(context).textTheme.body1)
                            ]),
                          ),
                          PopupMenuItem(
                            value: 1,
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.delete_outline),
                                SizedBox(width: 10),
                                Text(S.of(context).delete,
                                    style: Theme.of(context).textTheme.body1),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 2,
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.transform),
                                SizedBox(width: 10),
                                Text(S.of(context).convert,
                                    style: Theme.of(context).textTheme.body1),
                              ],
                            ),
                          )
                        ],
                    onSelected: (index) => _edit_task(index),
                  ),
                  SizedBox(width: 12)
                ]),
            preferredSize: Size.fromHeight(60)),
        body: ListView(
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(left: 18, right: 18),
                child: CupertinoTextField(
                  scrollPhysics: NeverScrollableScrollPhysics(),
                  decoration: BoxDecoration(border: Border()),
                  placeholder: S.of(context).input_task_hint,
                  autocorrect: false,
                  maxLines: null,
                  focusNode: _focusNode,
                  autofocus: task.id == null,
                  onChanged: (str) {
                    task.text = str;
                  },
                  keyboardType: TextInputType.multiline,
                  controller: _textController,
                  style: Theme.of(context).textTheme.body2.copyWith(
                        decoration:
                            task.isDone ? TextDecoration.lineThrough : null,
                        color: task.isDone ? Colors.grey : null,
                      ),
                )), // text field
            Container(
              alignment: AlignmentDirectional.centerStart,
              padding: EdgeInsets.only(left: 18, right: 18),
              child: Builder(
                builder: (context) {
                  return FutureBuilder<List<Label>>(
                      future: DBOperation.retrieveLabels(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Wrap(
                            spacing: 8,
                            children: _wrap_widgets(snapshot.data),
                          );
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      });
                },
              ),
            ), // task operation
            Column(children: _toDoList(_temp)),
            Offstage(
                offstage: true, //_temp.isNotEmpty
                child: RaisedButton(
                    onPressed: () => setState(() => _temp.add('0test'))))
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepOrange,
          onPressed: () {
            _focusNode.unfocus();
            Navigator.pop(context, task);
          },
          child: Icon(Icons.done, color: Colors.white),
        ));
  }

  _chooseProject(BuildContext context) {
    DBOperation.retrieveProjects().then((projectList) {
      showModalBottomSheet<Project>(
          context: context,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(S.of(context).choose_project,
                      style: Theme.of(context).textTheme.title),
                  Flexible(
                    child: ListView(
                      children: (projectList + [Project(id: 0)])
                          .map((project) => ListTile(
                                trailing: Radio(
                                    activeColor: Colors.blue,
                                    value: project.id,
                                    groupValue: task.projectID,
                                    onChanged: (i) =>
                                        Navigator.pop(context, project)),
                                title: Text(
                                  project.text ?? S.of(context).none_project,
                                ),
                                onTap: () {
                                  Navigator.pop(context, project);
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          }).then((project) {
        if (project == null) {
          return;
        }
        task.projectID = project.id;
        task.project_text = project.text;
        setState(() {});
      });
    });
  }

  _assignTask(BuildContext context) {
    showModalBottomSheet<TaskType>(
        context: context,
        builder: (BuildContext context) {
          return AssignTaskWidget(task: task, context: context);
        }).then((type) {
      setState(() {});
    });
  }

  _chooseLabels(BuildContext context) {
    showModalBottomSheet<List<Label>>(
        context: context,
        builder: (BuildContext context) {
          return ChooseLabelsWidget(task: task, context: context);
        }).then((newlabelList) {
      setState(() {});
    });
  }

  Color _priority_color(int p) {
    switch (p) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
    }
  }

  _change_priority() {
    switch (task.priority) {
      case 1:
        task.priority = 2;
        break;
      case 2:
        task.priority = 3;
        break;
      case 3:
        task.priority = 1;
    }
    setState(() {});
  }

  List<Widget> _wrap_widgets(List<Label> allLabels) {
    List<Widget> widgetList = <Widget>[
      _actionChip(_change_priority, Icons.lens, _priority_color(task.priority),
          S.of(context).priority),
      _actionChip(() {
        _assignTask(context);
      },
          iconDataOfFilter(TaskType.values[task.taskType]),
          Colors.deepOrange,
          task.taskType == 2
              ? task.plan_description(context)
              : stringOfFilter(TaskType.values[task.taskType], context)),
      _actionChip(() {
        _chooseProject(context);
      }, Icons.assignment, Colors.blue,
          task.project_text ?? S.of(context).project)
    ];

    if (task.labels.length == 0) {
      widgetList.add(_actionChip(() {
        _chooseLabels(context);
      }, Icons.label_outline, Colors.green, S.of(context).label));
    }

    for (int labelID in task.labels) {
      widgetList.add(_actionChip(() {
        _chooseLabels(context);
      }, Icons.label_outline, Colors.green,
          allLabels.singleWhere((l) => l.id == labelID).text));
    }
    return widgetList;
  }

  Widget _actionChip(
      VoidCallback onPressed, IconData icon, Color color, String text) {
    return ActionChip(
      avatar: Icon(icon,
          size: Theme.of(context).textTheme.subhead.fontSize, color: color),
      label: Text(
        text,
        style: Theme.of(context).textTheme.caption,
      ),
      onPressed: onPressed,
    );
  }

  _edit_task(int index) async {
    switch (index) {
      case 0:
        setState(() {
          task.isDone = !task.isDone;
        });
        break;
      case 1:
        if (task.id == null) {
          Navigator.pop(context);
        } else {
          await Provider.of<TasksNotifier>(context).delete(task.id);
          Navigator.pop(context);
        }
        break;
      case 2:
        if (task.text.isEmpty) {
          return;
        } else {
          await Provider.of<ProjectsNotifier>(context)
              .insert(Project(text: task.text));
          if (task.id == null) {
            Navigator.pop(context);
          } else {
            await Provider.of<TasksNotifier>(context).delete(task.id);
            Navigator.pop(context);
          }
        }
    }
  }

  List<Widget> _toDoList(List<String> temp) {
    List<Widget> _list = [];
    for (int index = 0; index < temp.length; index += 1) {
      _list.add(ListTile(
        leading: Checkbox(
            value: temp[index].substring(0, 1) == '1',
            onChanged: (b) {
              setState(() {
                temp[index] = temp[index].replaceRange(0, 1, b ? '1' : '0');
              });
            }),
        title: TextField(
          onEditingComplete: (){setState(() {
            _temp.add('0test');
          });},
          autofocus: true,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(border: InputBorder.none),
        ),
        trailing: Icon(Icons.drag_handle),
      ));
    }
    return _list;
  }
}

class ChooseLabelsWidget extends StatefulWidget {
  ChooseLabelsWidget({Key key, @required this.task, @required this.context})
      : super(key: key);
  Task task;
  BuildContext context;
  @override
  State<StatefulWidget> createState() => _ChooseLabelsWidgetState();
}

class _ChooseLabelsWidgetState extends State<ChooseLabelsWidget> {
  bool onEditMode = false;
  Task task;
  @override
  void initState() {
    super.initState();
    task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(S.of(context).choose_labels,
                    style: Theme.of(context).textTheme.title),
                IconButton(
                  icon: Icon(
                      onEditMode ? Icons.subdirectory_arrow_left : Icons.edit),
                  onPressed: () {
                    onEditMode = !onEditMode;
                    setState(() {});
                  },
                )
              ]),
          SizedBox(height: 8),
          FutureBuilder<List<Label>>(
            future: DBOperation.retrieveLabels(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Wrap(
                  spacing: 8,
                  children: snapshot.data.map((label) {
                    return FilterChip(
                      avatar: onEditMode
                          ? Icon(
                              Icons.clear,
                              size: 15,
                              color: task.labels.contains(label.id)
                                  ? Colors.white
                                  : null,
                            )
                          : null,
                      label: Text(
                        label.text,
                        style: TextStyle(
                            color: task.labels.contains(label.id)
                                ? Colors.white
                                : null),
                      ),
                      backgroundColor:
                          task.labels.contains(label.id) ? Colors.green : null,
                      onSelected: onEditMode
                          ? (b) {
                              showComfirmDialog(
                                      context,
                                      '',
                                      S.of(context).deleteLabel +
                                          label.text +
                                          ' ?')
                                  .then((b) {
                                if (b == null) return;
                                if (b) {
                                  DBOperation.deleteLabel(label.id)
                                      .then((value) {
                                    task.labels.remove(label.id);
                                    setState(() {});
                                  });
                                }
                              });
                            }
                          : (b) {
                              if (task.labels.contains(label.id)) {
                                task.labels.remove(label.id);
                              } else {
                                task.labels.add(label.id);
                              }
                              setState(() {});
                            },
                    );
                  }).followedBy([
                    FilterChip(
                      label: Icon(Icons.add),
                      onSelected: (b) {
                        _add_label();
                      },
                    )
                  ]).toList(),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          )
        ],
      ),
    );
  }

  _add_label() {
    showDialog<String>(
        context: widget.context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(S.of(context).add_label),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            children: <Widget>[
              Container(
                  margin: EdgeInsets.only(left: 24, right: 24),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                        hintText: S.of(context).input_label_hint,
                        border: InputBorder.none),
                    onSubmitted: (str) {
                      Navigator.pop(context, str);
                    },
                  ))
            ],
          );
        }).then((value) async {
      if (value == null || value.toString().isEmpty) {
        return;
      }
      Label newLabel = Label(text: value);
      int labelID = await DBOperation.insertLabel(newLabel);
      setState(() {});
    });
  }
}

class AssignTaskWidget extends StatefulWidget {
  AssignTaskWidget({Key key, this.task, this.context}) : super(key: key);

  Task task;
  BuildContext context;
  @override
  _AssignTaskWidgetState createState() => _AssignTaskWidgetState();
}

class _AssignTaskWidgetState extends State<AssignTaskWidget> {
  Task task;

  @override
  void initState() {
    super.initState();
    task = widget.task;
    task.dateTime ??= DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 18, top: 18),
          child: Text(S.of(context).assign_task,
              style: Theme.of(context).textTheme.title),
        ), //title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: TaskType.values
              .map((type) {
                return FlatButton.icon(
                    onPressed: () {
                      task.taskType = type.index;
                      if (type.index == 2 && task.dateTime == null) {
                        task.dateTime = DateTime.now();
                      }
                      setState(() {});
                    },
                    icon: Icon(iconDataOfFilter(type),
                        color: task.taskType == type.index
                            ? Colors.deepOrange
                            : null),
                    label: Text(stringOfFilter(type, context),
                        style: TextStyle(
                            color: task.taskType == type.index
                                ? Colors.deepOrange
                                : null)));
              })
              .toList()
              .sublist(1),
        ), //taskType
        Offstage(
          offstage: task.taskType != TaskType.plan.index,
          child: Padding(
              padding: const EdgeInsets.only(left: 28, right: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(S.of(context).repeat),
                  DropdownButton(
                      items: [
                        DropdownMenuItem(
                            child: Text(S.of(context).none,
                                style: TextStyle(
                                    color: task.repeatWay == 0
                                        ? Colors.deepOrange
                                        : null)),
                            value: 0),
                        DropdownMenuItem(
                            child: Text(S.of(context).everyDay,
                                style: TextStyle(
                                    color: task.repeatWay == 1
                                        ? Colors.deepOrange
                                        : null)),
                            value: 1),
                        DropdownMenuItem(
                            child: Text(S.of(context).everyWeek,
                                style: TextStyle(
                                    color: task.repeatWay == 2
                                        ? Colors.deepOrange
                                        : null)),
                            value: 2)
                      ],
                      value: task.repeatWay,
                      onChanged: (t) {
                        task.repeatWay = t;
//                        _changeRepeatWay(t);
                        if (t == 2 && !task.weekDay.any((i) => i >= 0)) {
                          task.weekDay.add(0);
                        }
                        setState(() {});
                      })
                ],
              )),
        ), //repeatWay
        Offstage(
          offstage: task.taskType != TaskType.plan.index || task.repeatWay != 2,
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 18),
            child: Row(
              children: TimeUtil.getDayButtons(
                  context,
                  MaterialLocalizations.of(context),
                  8,
                  task.weekDay,
                  _changeWeekDayList),
            ),
          ),
        ), //week
        Padding(
          padding: const EdgeInsets.only(left: 0, right: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Flexible(
                flex:
                    task.taskType != TaskType.plan.index || task.repeatWay != 0
                        ? 0
                        : 7,
                child: Offstage(
                  offstage: task.taskType != TaskType.plan.index ||
                      task.repeatWay != 0,
                  child: Wrap(
                    children: <Widget>[
                      _flatButton(DateTime.now(), context,
                          text: S.of(context).today),
                      _flatButton(
                          DateTime.now().add(Duration(days: 1)), context),
                      _flatButton(
                          DateTime.now().add(Duration(days: 2)), context),
                      _flatButton(
                          DateTime.now().add(Duration(days: 3)), context),
                      _flatButton(
                          DateTime.now().add(Duration(days: 4)), context),
                      FlatButton(
                        color: Theme.of(context).primaryColor,
                        child: Text(
                            _isMoreDate(task.dateTime)
                                ? TimeUtil.shortName(task.dateTime)
                                : 'more',
                            style: TextStyle(
                                color: _isMoreDate(task.dateTime)
                                    ? Colors.deepOrange
                                    : null)),
                        onPressed: _showCalendar(context),
                      )
                    ],
                  ),
                ),
              ), //date
              Offstage(
                  offstage: task.taskType != TaskType.plan.index ||
                      task.repeatWay != 0,
                  child: Container(
                    color: Theme.of(context).disabledColor,
                    width: 1,
                    height: 180,
                  )),
              Flexible(
                flex: 3,
                child: Offstage(
                  offstage: task.taskType != TaskType.plan.index,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        ':',
                        style: Theme.of(context).textTheme.subhead,
                        textAlign: TextAlign.center,
                      ),
                      TimePickerSpinner(
//                        itemWidth: 30,
                        highlightedTextStyle: Theme.of(context)
                            .textTheme
                            .subhead
                            .copyWith(color: Colors.deepOrange),
                        normalTextStyle: Theme.of(context).textTheme.caption,
//                        minutesInterval: 5,
                        time: task.dateTime ?? DateTime.now(),
                        spacing: 0,
                        alignment: Alignment.center,
                        onTimeChange: (t) {
                          task.dateTime ??= DateTime.now();
                          task.dateTime = DateTime(
                              task.dateTime.year,
                              task.dateTime.month,
                              task.dateTime.day,
                              t.hour,
                              t.minute);
                        },
                      )
                    ],
                  ),
                ),
              ) //time
            ],
          ),
        ) //date_time
      ],
    );
  }

  VoidCallback _showCalendar(BuildContext context) {
    VoidCallback callback = () {
      showDialog<DateTime>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              shape: RoundedRectangleBorder(borderRadius: cellRadius),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              children: <Widget>[
                ChangeNotifierProvider<ListPageStateNotifier>.value(
                    value: ListPageStateNotifier(),
                    child: Container(
                      width: screenWidth(context),
                      child: Calendar(
                        startYear: 2018,
                        modalMode: true,
                        controller: PageController(
                          initialPage: TimeUtil.date2page(
                              DateTime.now(), DateTime(2018)),
                        ),
                        daySelectedCallBack: (d) => Navigator.pop(context, d),
                      ),
                    ))
              ],
            );
          }).then((value) {
        if (value == null) {
          return;
        }
        task.dateTime = DateTime(value.year, value.month, value.day,
            task.dateTime.hour, task.dateTime.minute);
        setState(() {});
      });
    };
    return callback;
  }

  VoidCallback _changeWeekDayList(int i) {
    return () {
      if (task.weekDay.where((i) => i >= 0).length == 1 &&
          task.weekDay.contains(i)) {
        return;
      }
      if (task.weekDay.contains(i)) {
        task.weekDay.remove(i);
      } else {
        task.weekDay.add(i);
      }
      setState(() {});
    };
  }

  FlatButton _flatButton(DateTime date, BuildContext context, {String text}) {
    return FlatButton(
      child: Text(
        text ?? TimeUtil.shortName(date),
        style: TextStyle(
            color: TimeUtil.isInSameDay(date, task.dateTime)
                ? Colors.deepOrange
                : null),
      ),
      onPressed: () {
        task.dateTime = DateTime(date.year, date.month, date.day,
            task.dateTime.hour, task.dateTime.minute);
        setState(() {});
      },
    );
  }

  bool _isMoreDate(DateTime date) {
    return !TimeUtil.isInSameDay(date, DateTime.now()) &&
        !TimeUtil.isInSameDay(date, DateTime.now().add(Duration(days: 1))) &&
        !TimeUtil.isInSameDay(date, DateTime.now().add(Duration(days: 2))) &&
        !TimeUtil.isInSameDay(date, DateTime.now().add(Duration(days: 3))) &&
        !TimeUtil.isInSameDay(date, DateTime.now().add(Duration(days: 4)));
  }
}
