import 'package:flutter/material.dart';

import 'task_detail_page.dart';
import '../widgets/cells.dart';
import '../widgets/customize_button.dart';
import '../model/model.dart';
import '../model/macro.dart';
import 'package:provider/provider.dart';
import '../notifier/notifier.dart';

class LabelPage extends StatefulWidget {
  LabelPage({Key key, this.label_id, this.label_text}) : super(key: key);
  final int label_id;
  final String label_text;

  @override
  State<StatefulWidget> createState()=>_LabelPageState();
}

class _LabelPageState extends State<LabelPage>{
  ListPageStateNotifier _listPageStateNotifier = ListPageStateNotifier();
  final int random = randomWorker.nextInt(8);
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<ListPageStateNotifier>.value(value: _listPageStateNotifier)],
      child: Consumer3<TasksNotifier, ProjectsNotifier,
          ListPageStateNotifier>(
          builder: (context, tasksNotifier, projectsNotifier, listPageStateNotifier,  _) =>Scaffold(
              appBar: AppBar(
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  centerTitle: false,
                  title: ActionChip(
                      onPressed: () => Navigator.pop(context),
                      backgroundColor: Colors.green,
                      elevation: 6,
                      avatar: Icon(Icons.arrow_back),
                      label: Text(
                        widget.label_text,
                        style: Theme.of(context)
                            .textTheme
                            .title
                            .copyWith(color: Colors.white),
                      ))),
              body: _tableView(tasksNotifier.tasksWithLabel(widget.label_id)))

      ),
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
                showingIn: TaskCellShowingIn.label,
                parentContext: context);
          },
          itemCount: tasks.length);
      return listView;
    }
  }
}
