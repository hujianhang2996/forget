import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'task_detail_page.dart';
import '../widgets/cells.dart';
import '../widgets/customize_button.dart';
import '../model/model.dart';
import '../model/macro.dart';
import 'package:provider/provider.dart';
import '../notifier/notifier.dart';
import '../generated/i18n.dart';
import '../pages/label_page.dart';

class SearchPage extends StatefulWidget {
  SearchPage(this.cellShowingIn, {this.projectID = 0, this.taskType = 0});
  final TaskCellShowingIn cellShowingIn;
  final int projectID;
  final int taskType;

  @override
  State<StatefulWidget> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  ListPageStateNotifier _listPageStateNotifier = ListPageStateNotifier();
  final TextEditingController _textController = TextEditingController();
  String _query = '';
  final int random = randomWorker.nextInt(8);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ListPageStateNotifier>.value(
            value: _listPageStateNotifier)
      ],
      child: Consumer3<TasksNotifier, ProjectsNotifier, ListPageStateNotifier>(
          builder: (context, tasksNotifier, projectsNotifier,
              listPageStateNotifier, _) {
        List<Task> _tasks;
        switch (widget.cellShowingIn) {
          case TaskCellShowingIn.tasks:
            _tasks = tasksNotifier.tasks(listPageStateNotifier.sortWay,
                query: _query);
            break;
          case TaskCellShowingIn.project:
            _tasks = tasksNotifier.tasksInProject(
                widget.projectID, listPageStateNotifier.sortWay,
                query: _query);
            break;
          case TaskCellShowingIn.filter:
            _tasks = tasksNotifier.tasksInFilter(
                widget.taskType, listPageStateNotifier.sortWay,
                query: _query);
            break;
          case TaskCellShowingIn.label:
            _tasks = [];
        }
        return Scaffold(
            appBar: PreferredSize(
                child: AppBar(
                    automaticallyImplyLeading: false,
                    elevation: 0,
                    centerTitle: false,
                    title: ActionChip(
                        onPressed: () => Navigator.pop(context),
                        backgroundColor: Colors.deepOrange,
                        elevation: 6,
                        avatar: Icon(Icons.arrow_back),
                        label: Text(
                          S.of(context).search,
                          style: Theme.of(context)
                              .textTheme
                              .title
                              .copyWith(color: Colors.white),
                        ))),
                preferredSize: Size.fromHeight(60)),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.fromLTRB(
                            24, 10, _query.isEmpty ? 24 : 0, 10),
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        decoration: ShapeDecoration(
                            color: Theme.of(context).accentColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: cellRadius),
                            shadows: [
                              BoxShadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 5),
                                  blurRadius: 5),
                              BoxShadow(
                                  color: Colors.black54,
                                  offset: Offset(0, -1),
                                  blurRadius: 2)
                            ]),
                        child: CupertinoTextField(
                          autofocus: true,
                          controller: _textController,
                          onChanged: (str) {
                            setState(() {
                              _query = str;
                            });
                          },
                          decoration: BoxDecoration(border: Border()),
                        ),
                      ),
                    ),
                    Offstage(
                      offstage: _query.isEmpty,
                      child: IconButton(
                          onPressed: () => setState(() {
                                _textController.clear();
                                _query = '';
                              }),
                          color: Theme.of(context).iconTheme.color,
                          icon: Icon(Icons.clear)),
                    )
                  ],
                ),
                _labelView(),
                Expanded(
                  child: _tableView(_tasks),
                ),
              ],
            ));
      }),
    );
  }

  Widget _labelView() {
    return FutureBuilder<List<Label>>(
      future: DBOperation.retrieveLabels(),
      builder: (context, snapshhot) {
        if (snapshhot.hasData) {
          return Padding(
            padding: const EdgeInsets.only(left: 18, right: 18),
            child: Wrap(
              spacing: 8,
              children: snapshhot.data
                  .where((label) => _query.isEmpty
                      ? false
                      : label.text.toLowerCase().contains(_query.toLowerCase()))
                  .map((label) => ActionChip(
                        backgroundColor: Colors.green,
                        label: Text(
                          label.text,
                          style: TextStyle(
                              color: Theme.of(context).textTheme.body2.color),
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              PageRouteBuilder(pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                return LabelPage(
                                    label_id: label.id, label_text: label.text);
                              }, transitionsBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                                child,
                              ) {
                                return FadeTransition(
//position: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)).animate(animation),
                                  opacity: Tween<double>(begin: 0, end: 1)
                                      .animate(animation),
                                  child: child,
                                );
                              }));
                        },
                      ))
                  .toList(),
            ),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _tableView(List<Task> tasks) {
    if (tasks.isEmpty) {
      return PlaceHolder(random);
    } else {
      Widget listView = ListView.builder(
          itemBuilder: (context, index) {
            return TaskCell(
                taskID: tasks[index].id,
                showingIn: TaskCellShowingIn.tasks,
                parentContext: context);
          },
          itemCount: tasks.length);
      return listView;
    }
  }
}
