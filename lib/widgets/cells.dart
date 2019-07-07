import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../model/model.dart';
import '../model/macro.dart';
import '../generated/i18n.dart';
import '../pages/task_detail_page.dart';
import '../pages/project_page.dart';
import '../pages/filter_page.dart';
import 'package:circular_check_box/circular_check_box.dart';
import '../test_page.dart';
import 'package:provider/provider.dart';
import '../notifier/notifier.dart';

class TaskCell extends StatelessWidget {
  TaskCell(
      {Key key,
      @required this.taskID,
      @required this.parentContext,
      this.showingIn = TaskCellShowingIn.tasks})
      : super(key: key);

  final int taskID;
  final BuildContext parentContext;
  final TaskCellShowingIn showingIn;

  GestureTapCallback _click_task_callback(TasksNotifier tasksNotifier,
      ListPageStateNotifier listPageStateNotifier) {
    return listPageStateNotifier.isEditing
        ? () => listPageStateNotifier.changeSelected(taskID)
        : () {
            Navigator.push(
                parentContext,
                PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) {
                  return TaskDetailPage(task: tasksNotifier.task(taskID));
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
              tasksNotifier.update(value);
            });
          };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TasksNotifier, ListPageStateNotifier>(
      builder: (context, tasksNotifier, listPageStateNotifier, _) =>
          Dismissible(
            key: Key(taskID.toString()),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                await tasksNotifier.delete(taskID);
                return true;
              } else {
                await tasksNotifier.switchDone(taskID);
                return false;
              }
            },
            secondaryBackground: Container(
              alignment: AlignmentDirectional.center,
              child: ListTile(
                  trailing: Icon(
                Icons.delete_outline,
                color: Colors.red,
              )),
            ),
            background: Container(
              alignment: AlignmentDirectional.center,
              child: ListTile(
                  leading: Icon(
                      tasksNotifier.task(taskID).isDone
                          ? Icons.redo
                          : Icons.done,
                      color: tasksNotifier.task(taskID).isDone
                          ? Colors.grey
                          : Colors.green)),
            ),
            child: Card(
                margin: EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: InkWell(
                  borderRadius: cellRadius,
                  onTap: _click_task_callback(
                      tasksNotifier, listPageStateNotifier),
                  child: Container(
                    height: cellHeight,
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: Row(
                      children: <Widget>[
                        Icon(
                            iconDataOfFilter(TaskType
                                .values[tasksNotifier.task(taskID).taskType]),
                            color: tasksNotifier.task(taskID).priorityColor()),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(tasksNotifier.task(taskID).text,
                                  maxLines: 1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .body2
                                      .copyWith(
                                          color:
                                              tasksNotifier.task(taskID).isDone
                                                  ? Colors.grey
                                                  : null,
                                          decoration: tasksNotifier
                                                  .task(taskID)
                                                  .isDone
                                              ? TextDecoration.lineThrough
                                              : null)),
                              SizedBox(height: 3),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                children: _task_detail_widgets(
                                    context, tasksNotifier.task(taskID)),
                              )
                            ],
                          ),
                        ),
                        Offstage(
                            offstage: !listPageStateNotifier.isEditing,
                            child: SizedBox(width: 12)),
                        Offstage(
                            offstage: !listPageStateNotifier.isEditing,
                            child: CircularCheckBox(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                activeColor: Colors.deepOrange,
                                value: listPageStateNotifier.selectedTasks
                                    .contains(taskID),
                                onChanged: (b) => listPageStateNotifier
                                    .changeSelected(taskID)))
                      ],
                    ),
                  ),
                )),
          ),
    );
  }

  List<Widget> _task_detail_widgets(BuildContext context, Task task) {
    List<Widget> task_detail_widgets = [];
    if (task.taskType == 2) {
      task_detail_widgets.add(Text(task.plan_description(context),
          style: Theme.of(context)
              .textTheme
              .caption
              .copyWith(color: task.isDone ? Colors.grey : null)));
    }
    if (showingIn != TaskCellShowingIn.project && task.project_text != null) {
      task_detail_widgets.add(Text(task.project_text,
          maxLines: 1,
          style: Theme.of(context)
              .textTheme
              .caption
              .copyWith(color: task.isDone ? Colors.grey : null)));
    }
    if (!task.labels.isEmpty && showingIn != TaskCellShowingIn.label) {
      task_detail_widgets.add(Icon(Icons.label_outline,
          color: task.isDone
              ? Colors.grey
              : Theme.of(context).textTheme.caption.color,
          size: Theme.of(context).textTheme.caption.fontSize));
    }
    if (task_detail_widgets.isEmpty) {
      task_detail_widgets
          .add(Text('', style: Theme.of(context).textTheme.caption));
    }
    return task_detail_widgets;
  }
}

class ProjectCell extends StatelessWidget {
  ProjectCell({Key key, @required this.projectID, @required this.parentContext})
      : super(key: key);
  final int projectID;
  final BuildContext parentContext;

  GestureTapCallback _click_project_callback(int project_sortWay) {
    return () => Navigator.push(
        parentContext,
        PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) {
          return ProjectPage(
              project_id: projectID, project_sortWay: project_sortWay);
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

  GestureTapCallback _click_project_cupertino_callback(int project_sortWay) {
    return () =>
        Navigator.push(parentContext, CupertinoPageRoute(builder: (context) {
          return ProjectPage(
              project_id: projectID, project_sortWay: project_sortWay);
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectsNotifier, TasksNotifier>(
      builder: (context, projectsNotifier, tasksNotifier, _) => Dismissible(
            direction: DismissDirection.endToStart,
            key: Key(projectID.toString()),
            confirmDismiss: (DismissDirection direction) async {
              bool comfirmDelete = await showComfirmDialog(context,
                  S.of(context).deleteProj, S.of(context).deleteProjMsg);
              if (comfirmDelete == null) return false;
              if (comfirmDelete) {
                await projectsNotifier.delete(projectID, context);
                return true;
              } else {
                return false;
              }
            },
            background: Container(
              alignment: AlignmentDirectional.center,
              child: ListTile(
                  trailing: Icon(Icons.delete_outline, color: Colors.red)),
            ),
            child: Card(
                margin: EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: InkWell(
                  borderRadius: cellRadius,
                  onTap: _click_project_callback(
                      projectsNotifier.project(projectID).sortWay),
                  child: Container(
                    height: cellHeight,
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(projectsNotifier.project(projectID).text,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.body2),
                              SizedBox(height: 3),
                              Text(
                                  '${tasksNotifier.tasksInProject(projectID, 0).where((t) => !t.isDone).length}' +
                                      S.of(context).tasks,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.caption)
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )),
          ),
    );
  }
}

class FilterCell extends StatelessWidget {
  FilterCell({Key key, @required this.filter, @required this.parentContext})
      : super(key: key);
  TaskType filter;
  BuildContext parentContext;

  GestureTapCallback _click_filter_callbakc() {
    return () {
      Navigator.push(
          parentContext,
          PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
            return FilterPage(taskType: filter);
          }, transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(animation),
              child: child,
            );
          }));
    };
  }

  @override
  Widget build(BuildContext context) {
    final double cellWidth = (screenWidth(context) - 12 * 3) / 2;
    return Consumer<TasksNotifier>(
      builder: (context, taskNotifier, _) => Card(
//        alignment: Alignment.center,
          margin: EdgeInsets.fromLTRB(12, 4, 0, 4),
//        width: cellWidth,
//        decoration: ShapeDecoration(
//            color: Theme.of(context).accentColor,
//            shape: RoundedRectangleBorder(
//                borderRadius: cellRadius)),
          child: InkWell(
            borderRadius: cellRadius,
            onTap: _click_filter_callbakc(),
            child: Container(
              height: cellHeight,
              padding: const EdgeInsets.only(left: 12, right: 12),
              width: cellWidth,
              child: Row(
                children: <Widget>[
                  Icon(iconDataOfFilter(filter)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(stringOfFilter(filter, context),
                            style: Theme.of(context).textTheme.body2),
                        SizedBox(height: 3),
                        Text(
                            '${taskNotifier.tasksInFilter(filter.index, 0).where((t) => !t.isDone).length}' +
                                S.of(context).tasks,
                            style: Theme.of(context).textTheme.caption)
                      ],
                    ),
                  )
                ],
              ),
            ),
          )),
    );
  }
}
