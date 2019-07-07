import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import '../generated/i18n.dart';
import '../model/model.dart';
import '../model/macro.dart';
import '../notifier/notifier.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sequence_animation/flutter_sequence_animation.dart';
import '../model/macro.dart';
import 'dart:math';
import '../pages/search_page.dart';
import 'package:circular_check_box/circular_check_box.dart';
import '../forget_icons.dart';

class AnimatedChip extends AnimatedWidget {
  AnimationController _controller;
  PageController _pageController;
  SequenceAnimation _animation;

  AnimatedChip(AnimationController controller, PageController pageController)
      : super(listenable: controller) {
    _controller = controller;
    _pageController = pageController;
    _animation = SequenceAnimationBuilder()
        .addAnimatable(
            animatable: ColorTween(begin: Colors.deepOrange, end: Colors.blue),
            from: Duration.zero,
            to: longDuration,
            tag: 'color')
        .addAnimatable(
            animatable: Tween<double>(begin: 0, end: pi),
            from: Duration.zero,
            to: longDuration,
            tag: 'rotate')
        .addAnimatable(
            animatable: TweenSequence([
              TweenSequenceItem(
                  tween: Tween<double>(begin: 1, end: 0), weight: 0.5),
              TweenSequenceItem(
                  tween: Tween<double>(begin: 0, end: 1), weight: 0.5)
            ]),
            from: Duration.zero,
            to: longDuration,
            tag: 'opacity')
        .animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ListPageStateNotifier>(
        builder: (context, listPageStateNotifier, _) => ActionChip(
            elevation: 6,
            backgroundColor: _animation['color'].value,
            avatar: Transform.rotate(
                angle: _animation['rotate'].value,
                child: Icon(Icons.autorenew)),
            label: Opacity(
              opacity: _animation['opacity'].value,
              child: Text(
                listPageStateNotifier.isShowingTask
                    ? S.of(context).main_title_1
                    : S.of(context).main_title_2,
                style: Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(color: Colors.white),
              ),
            ),
            onPressed: () {
              if (listPageStateNotifier.isShowingTask) {
                _controller.forward();
                _pageController.animateToPage(1,
                    duration: longDuration, curve: Curves.linear);
              } else {
                _controller.reverse();
                _pageController.animateToPage(0,
                    duration: longDuration, curve: Curves.linear);
              }
              listPageStateNotifier.switchIsEditing(newValue: false);
              listPageStateNotifier.unselectAll();
              listPageStateNotifier.switchIsShowingTask();
            }));
  }
}

class ForgetAppBar extends StatelessWidget implements PreferredSizeWidget {
  ForgetAppBar(
      {Key key,
      @required this.parentContext,
      this.chipColor = Colors.blue,
      @required this.title,
      this.preferredSize = const Size.fromHeight(60),
      this.actions = const []})
      : super(key: key);
  @override
  Size preferredSize;

  final BuildContext parentContext;
  final Color chipColor;
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: false,
      title: ActionChip(
          onPressed: () => Navigator.pop(parentContext),
          backgroundColor: chipColor,
          elevation: 6,
          avatar: Icon(Icons.arrow_back),
          label: Text(
            title,
            style: Theme.of(parentContext)
                .textTheme
                .title
                .copyWith(color: Colors.white),
          )),
      actions: actions,
    );
  }
}

//class SortWayButton extends StatelessWidget {
//  SortWayButton({Key key, this.showAllOptions = true, @required this.noTasks})
//      : super(key: key);
//  final bool noTasks;
//  final bool showAllOptions;
//
//  @override
//  Widget build(BuildContext context) {
//    return Consumer<ListPageStateNotifier>(
//        builder: (context, states, _) => Offstage(
//            offstage: !states.isShowingTask || noTasks,
//            child: PopupMenuButton<int>(
//              icon: Icon(
//                Icons.swap_vert,
//                color: Theme.of(context).textTheme.body1.color,
//              ),
//              itemBuilder: (context) {
//                return [
//                  PopupMenuItem<int>(
//                      value: 0,
//                      child: Text(S.of(context).additionOrder,
//                          style: Theme.of(context).textTheme.body1.copyWith(
//                              color: states.sortWay == 0
//                                  ? Colors.deepOrange
//                                  : null))),
//                  showAllOptions
//                      ? PopupMenuItem<int>(
//                          value: 1,
//                          child: Text(S.of(context).chronological,
//                              style: Theme.of(context).textTheme.body1.copyWith(
//                                  color: states.sortWay == 1
//                                      ? Colors.deepOrange
//                                      : null)))
//                      : null,
//                  PopupMenuItem<int>(
//                      value: 2,
//                      child: Text(S.of(context).priorityOrder,
//                          style: Theme.of(context).textTheme.body1.copyWith(
//                              color: states.sortWay == 2
//                                  ? Colors.deepOrange
//                                  : null))),
//                ];
//              },
//              onSelected: (index) => states.changeSortWay(newValue: index),
//            )));
////  return IconButton(
////    color: Theme.of(context).iconTheme.color,
////    icon: Icon(Icons.sort),
////    onPressed: (){},
////  );
//  }
//}
//
//class SearchButton extends StatelessWidget {
//  SearchButton(this.cellShowingIn, this.noTasks,
//      {this.projectID = 0, this.taskType = 0});
//  final bool noTasks;
//  final TaskCellShowingIn cellShowingIn;
//  final int projectID;
//  final int taskType;
//
//  @override
//  Widget build(BuildContext context) {
//    return Consumer<ListPageStateNotifier>(
//      builder: (context, listPageStateNotifier, _) => Offstage(
//            offstage: !listPageStateNotifier.isShowingTask || noTasks,
//            child: IconButton(
//                icon: Icon(Icons.search),
//                color: Theme.of(context).iconTheme.color,
//                onPressed: () => _search_callback(context)),
//          ),
//    );
//  }
//
//  GestureTapCallback _search_callback(BuildContext context) {
//    Navigator.push(
//        context,
//        PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) {
//          return SearchPage(cellShowingIn,
//              projectID: projectID, taskType: taskType);
//        }, transitionsBuilder: (
//          context,
//          animation,
//          secondaryAnimation,
//          child,
//        ) {
//          return FadeTransition(
////position: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)).animate(animation),
//            opacity: Tween<double>(begin: 0, end: 1).animate(animation),
//            child: child,
//          );
//        }));
//  }
//}
//
//class ShowAllButton extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return Consumer<TasksNotifier>(
//        builder: (context, tasksNotifier, _) => IconButton(
//              icon: Icon(
//                  tasksNotifier.showIsDone ? Icons.no_sim : Icons.sim_card),
//              onPressed: () => tasksNotifier.switchShowIsDone(),
//            ));
////  return IconButton(
////    color: Theme.of(context).iconTheme.color,
////    icon: Icon(Icons.sort),
////    onPressed: (){},
////  );
//  }
//}

class MoreMenu extends StatelessWidget {
  final AnimationController _controller;
  final TaskCellShowingIn cellShowingIn;
  final int projectID;
  final int taskType;
  final bool showChronological;

  MoreMenu(this._controller, this.cellShowingIn,
      {this.projectID = 0, this.taskType = 0})
      : showChronological =
            !(cellShowingIn == TaskCellShowingIn.filter && taskType != 2);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ListPageStateNotifier, TasksNotifier>(
      builder: (context, listPageStateNotifier, tasksNotifier, _) {
        return Offstage(
          offstage: !listPageStateNotifier.isShowingTask,
          child: PopupMenuButton<int>(
            icon: Icon(Icons.more_horiz,
                color: Theme.of(context).iconTheme.color),
            itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0,
                    child: Row(children: <Widget>[
                      Icon(Icons.list),
                      SizedBox(width: 10),
                      Text(S.of(context).edit,
                          style: Theme.of(context).textTheme.body1)
                    ]),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.sort),
                        SizedBox(width: 10),
                        Text(S.of(context).sort,
                            style: Theme.of(context).textTheme.body1),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.search),
                        SizedBox(width: 10),
                        Text(S.of(context).search,
                            style: Theme.of(context).textTheme.body1),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 3,
                    child: Row(
                      children: <Widget>[
                        Icon(tasksNotifier.showIsDone
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked),
                        SizedBox(width: 10),
                        Text(S.of(context).showIsDone,
                            style: Theme.of(context).textTheme.body1),
                      ],
                    ),
                  )
                ],
            onSelected: (index) => _click_callback(
                index, listPageStateNotifier, tasksNotifier, context),
          ),
        );
      },
    );
  }

  _click_callback(int index, ListPageStateNotifier listPageStateNotifier,
      TasksNotifier tasksNotifier, BuildContext context) {
    switch (index) {
      case 0:
        _editTask(listPageStateNotifier, tasksNotifier);
        break;
      case 1:
        _sort(context, listPageStateNotifier);
        break;
      case 2:
        _search(context, listPageStateNotifier);
        break;
      case 3:
        _showIsDone(tasksNotifier);
    }
  }

  void _editTask(ListPageStateNotifier listPageStateNotifier,
      TasksNotifier tasksNotifier) {
    bool noTasks;
    switch (cellShowingIn) {
      case TaskCellShowingIn.tasks:
        noTasks = tasksNotifier.tasks(0).isEmpty;
        break;
      case TaskCellShowingIn.filter:
        noTasks =
            listPageStateNotifier.isShowingAll || taskType != TaskType.plan.index
                ? tasksNotifier.tasksInFilter(taskType, 0).isEmpty
                : tasksNotifier
                    .tasksInDate(listPageStateNotifier.selectedDate, 0)
                    .isEmpty;
        break;
      case TaskCellShowingIn.project:
        noTasks = tasksNotifier.tasksInProject(projectID, 0).isEmpty;
        break;
      case TaskCellShowingIn.label:
        noTasks = false;
    }
    if (noTasks && !listPageStateNotifier.isEditing) return;
    if (listPageStateNotifier.isEditing) {
      _controller
          .reverse()
          .then((v) => listPageStateNotifier.switchIsEditing());
    } else {
      _controller.forward();
      listPageStateNotifier.switchIsEditing();
    }
    listPageStateNotifier.selectedTasks.clear();
  }

  void _search(
      BuildContext context, ListPageStateNotifier listPageStateNotifier) {
    listPageStateNotifier.switchIsEditing(newValue: false);
    listPageStateNotifier.unselectAll();
    Navigator.push(
        context,
        PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) {
          return SearchPage(cellShowingIn,
              projectID: projectID, taskType: taskType);
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

  void _showIsDone(TasksNotifier tasksNotifier) async {
    await tasksNotifier.switchShowIsDone();
  }

  void _sort(
      BuildContext context, ListPageStateNotifier listPageStateNotifier) {
    showDialog<int>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [0, 1, 2].map((index) {
                    final String title = [
                      S.of(context).additionOrder,
                      S.of(context).chronological,
                      S.of(context).priorityOrder
                    ][index];
                    return ListTile(
                      trailing: Radio<int>(
                          activeColor: Colors.deepOrange,
                          value: index,
                          groupValue: listPageStateNotifier.sortWay,
                          onChanged: (i) => Navigator.pop(context, i)),
                      title:
                          Text(title, style: Theme.of(context).textTheme.body1),
                      onTap: () {
                        Navigator.pop(context, index);
                      },
                    );
                  }).toList(),
                ),
              )
            ],
          );
        }).then((index) {
      if (index == null) return;
      listPageStateNotifier.changeSortWay(
          context, cellShowingIn, TaskType.values[taskType], projectID,
          newValue: index);
    });
  }
}

class EditMenu extends AnimatedWidget {
  Animation _animation;
  final TaskCellShowingIn cellShowingIn;
  final int projectID;
  final int taskType;

  EditMenu(AnimationController controller, this.cellShowingIn,
      {this.projectID = 0, this.taskType = 0})
      : super(listenable: controller) {
    _animation = Tween<double>(begin: cellHeight, end: 0).animate(controller);
  }

  @override
  Widget build(BuildContext context) {
    final Color shadowColor = Colors.black54;
    final double blurRadius = 0;
    return Consumer2<TasksNotifier, ListPageStateNotifier>(
        builder: (context, tasksNotifier, listPageStateNotifier, _) => Offstage(
              offstage: !listPageStateNotifier.isEditing,
              child: Transform.translate(
                offset: Offset(0, _animation.value - 12),
                child: SafeArea(
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: ShapeDecoration(
                            shadows: [
                              BoxShadow(
                                  offset: Offset(0, blurRadius),
                                  blurRadius: blurRadius,
                                  color: shadowColor),
                              BoxShadow(
                                  offset: Offset(0, -blurRadius),
                                  blurRadius: blurRadius,
                                  color: shadowColor)
                            ],
                            color: Theme.of(context)
                                .textTheme
                                .body2
                                .color
                                .withOpacity(Theme.of(context).brightness ==
                                        Brightness.light
                                    ? 0.2
                                    : 0.8),
                            shape: RoundedRectangleBorder(
                                borderRadius: cellRadius * 5)),
                        height: cellHeight,
                        width: screenWidth(context) - 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Flexible(
                              child: FlatButton(
                                  shape: CircleBorder(),
                                  splashColor: Theme.of(context).accentColor,
                                  child: Icon(ForgetIcon.select_all,
                                      color:
                                          Theme.of(context).textSelectionColor),
                                  onPressed: () {
                                    List<Task> _task;
                                    switch (cellShowingIn) {
                                      case TaskCellShowingIn.tasks:
                                        _task = tasksNotifier.tasks(0);
                                        break;
                                      case TaskCellShowingIn.filter:
                                        _task =
                                            listPageStateNotifier.isShowingAll
                                                ? tasksNotifier.tasksInFilter(
                                                    taskType, 0)
                                                : tasksNotifier.tasksInDate(
                                                    listPageStateNotifier
                                                        .selectedDate,
                                                    0);
                                        break;
                                      case TaskCellShowingIn.project:
                                        _task = tasksNotifier.tasksInProject(
                                            projectID, 0);
                                        break;
                                      case TaskCellShowingIn.label:
                                        _task = [];
                                    }
                                    listPageStateNotifier.selectAll(_task);
                                  }),
                            ),
                            Flexible(
                              child: FlatButton(
                                shape: CircleBorder(),
                                splashColor: Theme.of(context).accentColor,
                                child: Icon(ForgetIcon.unselect,
                                    color:
                                        Theme.of(context).textSelectionColor),
                                onPressed: () =>
                                    listPageStateNotifier.unselectAll(),
                              ),
                            ),
                            Flexible(
                              child: FlatButton(
                                  shape: CircleBorder(),
                                  splashColor: Theme.of(context).accentColor,
                                  child: Icon(Icons.delete_outline,
                                      color:
                                          Theme.of(context).textSelectionColor),
                                  onPressed: () {
                                    if (listPageStateNotifier
                                        .selectedTasks.isEmpty) return;
                                    showComfirmDialog(context, '',
                                            S.of(context).deleteTasks)
                                        .then((value) {
                                      if (value == null) return;
                                      if (value) {
                                        tasksNotifier.deleteSeveral(
                                            listPageStateNotifier
                                                .selectedTasks);
                                      }
                                    });
                                  }),
                            ),
                            Flexible(
                              child: FlatButton(
                                shape: CircleBorder(),
                                splashColor: Theme.of(context).accentColor,
                                child: Icon(Icons.assignment,
                                    color:
                                        Theme.of(context).textSelectionColor),
                                onPressed: () => _choose_project(
                                    context,
                                    listPageStateNotifier.selectedTasks,
                                    tasksNotifier),
                              ),
                            ),
                            Flexible(
                              child: FlatButton(
                                shape: CircleBorder(),
                                splashColor: Theme.of(context).accentColor,
                                child: Icon(Icons.label_outline,
                                    color:
                                        Theme.of(context).textSelectionColor),
                                onPressed: () => _add_label(
                                    context,
                                    listPageStateNotifier.selectedTasks,
                                    tasksNotifier),
                              ),
                            ),
                          ],
                        ),
                      )),
                ),
              ),
            ));
  }

  _choose_project(BuildContext context, List<int> selectedTaskIDList,
      TasksNotifier tasksNotifier) {
    if (selectedTaskIDList.isEmpty) {
      return;
    }
    DBOperation.retrieveProjects().then((projectList) {
      showModalBottomSheet<Project>(
          context: context,
          builder: (BuildContext context) {
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
        tasksNotifier.addTasksToProject(selectedTaskIDList, project.id);
      });
    });
  }

  _add_label(BuildContext context, List<int> selectedTaskIDList,
      TasksNotifier tasksNotifier) {
    if (selectedTaskIDList.isEmpty) {
      return;
    }
    DBOperation.retrieveLabels().then((labels) {
      showModalBottomSheet<Label>(
          context: context,
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(S.of(context).add_label,
                      style: Theme.of(context).textTheme.title),
                  Flexible(
                    child: ListView(
                      children: (labels)
                          .map((label) => ListTile(
                                title: Text(
                                  label.text,
                                ),
                                onTap: () {
                                  Navigator.pop(context, label);
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          }).then((label) {
        if (label == null) {
          return;
        }
        tasksNotifier.addLabelToTasks(selectedTaskIDList, label.id);
      });
    });
  }
}

class EditButton extends StatelessWidget {
  final AnimationController _controller;
  EditButton(this._controller);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ListPageStateNotifier, TasksNotifier>(
      builder: (context, listPageStateNotifier, tasksNotifier, _) {
        return Offstage(
          offstage: !listPageStateNotifier.isShowingTask ||
              !listPageStateNotifier.isEditing,
          child: IconButton(
              onPressed: () {
                _controller
                    .reverse()
                    .then((v) => listPageStateNotifier.switchIsEditing());
                listPageStateNotifier.selectedTasks.clear();
              },
              color: Theme.of(context).iconTheme.color,
              icon: Icon(Icons.subdirectory_arrow_left)),
        );
      },
    );
  }
}

class PlaceHolder extends StatelessWidget {
  final int random;
  const PlaceHolder(this.random);
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset('placeholder/motto${random}.png'),
          SizedBox(height: 10),
          Text(
            S.of(context).mottos.split('+')[random],
            style: TextStyle(color: Theme.of(context).textTheme.caption.color),
            textAlign: TextAlign.center,
          )
        ],
      ),
    ));
  }
}
