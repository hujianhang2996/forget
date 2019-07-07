import 'package:flutter/material.dart';
import '../widgets/calendar.dart';
import '../widgets/cells.dart';
import '../widgets/customize_button.dart';
import '../generated/i18n.dart';
import '../model/time_util.dart';
import '../model/model.dart';
import '../model/macro.dart';
import '../notifier/notifier.dart';
import 'package:provider/provider.dart';

class FilterPage extends StatefulWidget {
  FilterPage({Key key, this.taskType = TaskType.unassigned}) : super(key: key);
  final TaskType taskType;

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage>
    with SingleTickerProviderStateMixin {
  final DateTime startTime = DateTime(2018);
  PageController _pageController;
  AnimationController _menuController;

  ListPageStateNotifier _listPageStateNotifier;
  final int random = randomWorker.nextInt(8);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: TimeUtil.date2page(DateTime.now(), startTime),
    );
    _menuController = AnimationController(vsync: this, duration: shortDuration);
    _listPageStateNotifier = ListPageStateNotifier(s: getSortWay(false, widget.taskType));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<ListPageStateNotifier>.value(value: _listPageStateNotifier)],
      child: Consumer3<TasksNotifier, ProjectsNotifier, ListPageStateNotifier>(
        builder: (context, tasksNotifier, projectsNotifier, listPageStateNotifier,
            _) =>
            Scaffold(
                appBar: ForgetAppBar(
                  parentContext: context,
                  title: stringOfFilter(widget.taskType, context),
                  actions: <Widget>[
                    Offstage(
                      offstage: widget.taskType != TaskType.plan,
                      child: IconButton(
                        color: Theme.of(context).iconTheme.color,
                        icon: Icon(Icons.today),
                        onPressed: () {
                          _pageController.jumpToPage(
                              TimeUtil.date2page(DateTime.now(), startTime));
                          listPageStateNotifier.selectDate(DateTime.now());
                        },
                      ),
                    ),
                    MoreMenu(_menuController, TaskCellShowingIn.filter, taskType: widget.taskType.index,),
                    EditButton(_menuController),
                    SizedBox(width: 12)
                  ],
                ),
                body: Stack(
                  children: [
                    Column(
                      children: <Widget>[
                        Offstage(
                            offstage: widget.taskType != TaskType.plan,
                            child: Calendar(
                                startYear: startTime.year,
                                controller: _pageController,
                                tasks: widget.taskType.index == 2
                                    ? tasksNotifier
                                    .tasksInFilter(widget.taskType.index, listPageStateNotifier.sortWay)
                                    : [])),
                        Expanded(
                          child: _tableView(
                              listPageStateNotifier.isShowingAll || widget.taskType != TaskType.plan
                                  ? tasksNotifier
                                  .tasksInFilter(widget.taskType.index, listPageStateNotifier.sortWay)
                                  : tasksNotifier.tasksInDate(
                                  listPageStateNotifier.selectedDate, listPageStateNotifier.sortWay),
                              listPageStateNotifier),
                        )
                      ],
                    ),
                    Offstage(
                        offstage: !listPageStateNotifier.isEditing,
                        child: EditMenu(_menuController, TaskCellShowingIn.filter, taskType: widget.taskType.index,))
                  ],
                ),
                floatingActionButton: Offstage(
                  offstage: listPageStateNotifier.isEditing,
                  child: FloatingActionButton(
                    backgroundColor: Colors.deepOrange,
                    onPressed: ()=>add_task_callback(
                        context,
                        Task(
                            taskType: widget.taskType.index,
                            dateTime: DateTime(
                                listPageStateNotifier.selectedDate.year,
                                listPageStateNotifier.selectedDate.month,
                                listPageStateNotifier.selectedDate.day,
                                DateTime.now().hour,
                                DateTime.now().minute)),
                        tasksNotifier),
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                )),
      )
    );
  }

  Widget _tableView(
      List<Task> tasks, ListPageStateNotifier listPageStateNotifier) {
    if (tasks.isEmpty && widget.taskType.index != 2) {
      return PlaceHolder(random);
    } else {
      Widget listView = ListView.builder(
          itemBuilder: (context, index) {
            return index == tasks.length
                ? Offstage(
                    offstage: widget.taskType.index != 2,
                    child: Center(
                      heightFactor: 1.3,
                      child: FlatButton(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                  listPageStateNotifier.isShowingAll
                                      ? S.of(context).showCurrent
                                      : S.of(context).showAll,
                                  style: Theme.of(context).textTheme.caption),
                              Icon(
                                listPageStateNotifier.isShowingAll
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color:
                                    Theme.of(context).textTheme.caption.color,
                              )
                            ],
                          ),
                          onPressed: () {
                            listPageStateNotifier.switchIsShowingAll();
                          }),
                    ),
                  )
                : TaskCell(
                    taskID: tasks[index].id,
                    showingIn: TaskCellShowingIn.filter,
                    parentContext: context);
          },
          itemCount: tasks.length + 1);
      return listView;
    }
  }
}
