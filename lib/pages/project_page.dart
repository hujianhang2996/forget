import 'package:flutter/material.dart';

import 'task_detail_page.dart';
import '../widgets/cells.dart';
import '../widgets/customize_button.dart';
import '../model/model.dart';
import '../model/macro.dart';
import 'package:provider/provider.dart';
import '../notifier/notifier.dart';

class ProjectPage extends StatefulWidget {
  ProjectPage({Key key,@required this.project_id, @required this.project_sortWay}) : super(key: key);
  final int project_id;
  final int project_sortWay;

  @override
  State<StatefulWidget> createState()=>_ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage>
    with SingleTickerProviderStateMixin {
  AnimationController _menuController;
  ListPageStateNotifier _listPageStateNotifier;
  final int random = randomWorker.nextInt(8);
  @override
  void initState() {
    super.initState();
    _menuController =
        AnimationController(vsync: this, duration: shortDuration);
    _listPageStateNotifier = ListPageStateNotifier(s: widget.project_sortWay);
  }
  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<ListPageStateNotifier>.value(value: _listPageStateNotifier)],
      child: Consumer3<TasksNotifier, ProjectsNotifier,
          ListPageStateNotifier>(
          builder: (context, tasksNotifier, projectsNotifier, listPageStateNotifier,  _) =>Scaffold(
              appBar: ForgetAppBar(
                parentContext: context,
                title: projectsNotifier.project(widget.project_id).text,
                actions: <Widget>[
                  MoreMenu(_menuController, TaskCellShowingIn.project, projectID: widget.project_id),
                  EditButton(_menuController),
                  SizedBox(width: 12)
                ],
              ),
              body: Stack(
                children: [
                  _tableView(tasksNotifier.tasksInProject(widget.project_id, listPageStateNotifier.sortWay)),
                  EditMenu(_menuController, TaskCellShowingIn.project, projectID: widget.project_id)
                ],
              ),
              floatingActionButton: Offstage(
                offstage: listPageStateNotifier.isEditing,
                child: FloatingActionButton(
                  backgroundColor: Colors.deepOrange,
                  onPressed: ()=>add_task_callback(
                      context,
                      Task(
                          projectID: widget.project_id,
                          project_text: projectsNotifier.project(widget.project_id).text),
                      tasksNotifier),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ))

      ),
    );
  }

  Widget _tableView(List<Task> tasks) {
    if (tasks.isEmpty) {
//      return ListView(
//        children: <Widget>[
//          Text('Task, 任务', style: Theme.of(context).textTheme.display4),
//          Text('Task, 任务', style: Theme.of(context).textTheme.display3),
//          Text('Task, 任务', style: Theme.of(context).textTheme.display2),
//          Text('Task, 任务', style: Theme.of(context).textTheme.display1),
//          Text('Task, 任务', style: Theme.of(context).textTheme.headline),
//          Text('Task, 任务', style: Theme.of(context).textTheme.title), //checked
//          Text('Task, 任务', style: Theme.of(context).textTheme.subhead),
//          Text('Task, 任务', style: Theme.of(context).textTheme.body2), //checked
//          Text('Task, 任务', style: Theme.of(context).textTheme.body1),
//          Text('Task, 任务',
//              style: Theme.of(context).textTheme.caption), //checked
//          Text('Task, 任务', style: Theme.of(context).textTheme.button),
//          Text('Task, 任务', style: Theme.of(context).textTheme.subtitle),
//          Text('Task, 任务', style: Theme.of(context).textTheme.overline)
//        ],
//      );
    return PlaceHolder(random);
    } else {
      Widget listView = ListView.builder(
          itemBuilder: (context, index) {
            return TaskCell(
                taskID: tasks[index].id,
                showingIn: TaskCellShowingIn.project,
                parentContext: context);
          },
          itemCount: tasks.length);
      return listView;
    }
  }
}
