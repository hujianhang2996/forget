import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import '../model/time_util.dart';
import '../model/macro.dart';
import 'day_grid_view.dart';
import '../model/model.dart';
import 'package:provider/provider.dart';
import '../notifier/notifier.dart';

typedef DaySelectedCallBack = void Function(DateTime time);

class Calendar extends StatefulWidget {
  final int startYear;
  final int endYear;
  final bool modalMode;
  PageController controller;
  final double dayCellAspectRatio;
  final double weekdayCellPadding;
  final List<Task> tasks;
  final DaySelectedCallBack daySelectedCallBack;

  Calendar(
      {Key key,
      @required this.startYear,
      this.endYear = 2035,
      this.modalMode = false,
      @required this.controller,
      this.dayCellAspectRatio = 1.3,
      this.weekdayCellPadding = 8,
      this.tasks = const [],
      this.daySelectedCallBack})
      : super(key: key);

  @override
  State<Calendar> createState() {
    return _CalendarState();
  }
}

class _CalendarState extends State<Calendar> {
  DateTime currentTime = DateTime.now();



  onChange(ListPageStateNotifier listPageStateNotifier) {
    return (DateTime time, int year, int month){
      if (listPageStateNotifier.selectedDate != time) {
        if ((time.year * 12 + time.month) < (year * 12 + month) &&
            !widget.modalMode) {
          widget.controller
              .previousPage(duration: longDuration, curve: Curves.linear);
        }
        if ((time.year * 12 + time.month) > (year * 12 + month) &&
            !widget.modalMode) {
          widget.controller
              .nextPage(duration: longDuration, curve: Curves.linear);
        }
        listPageStateNotifier.selectDate(time);
      }
      if (widget.daySelectedCallBack != null){widget.daySelectedCallBack(time);}
    };
  }

  @override
  Widget build(BuildContext context) {
    final DateTime startTime = DateTime(widget.startYear);
    final DateTime endTime = DateTime(widget.endYear);
    return Consumer2<TasksNotifier, ListPageStateNotifier>(
      builder: (context, tasksNotifier, listPageStateNotifier, _)=>Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: TimeUtil.getDayHeaders(
                MaterialLocalizations.of(context), widget.weekdayCellPadding),
          ),
          SizedBox(height: 5),
          AspectRatio(
            aspectRatio: widget.dayCellAspectRatio * DateTime.daysPerWeek / 6,
            child: PageView.builder(
              scrollDirection: Axis.horizontal,
              onPageChanged: (i) {
                if (widget.modalMode) {
                  return;
                }
                DateTime newDay = TimeUtil.page2date(i, startTime);
                if (TimeUtil.isInSameMonth(newDay, currentTime)) {
                  newDay = currentTime;
                }
                if (!TimeUtil.isInSameMonth(listPageStateNotifier.selectedDate, newDay)) {
                  listPageStateNotifier.selectDate(newDay);
                }
              },
              itemBuilder: (BuildContext context, int index) {
                return Stack(
                  children: <Widget>[
                    Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '${TimeUtil.page2date(index, startTime).year}',
                              style: TextStyle(
                                  fontSize:
                                  Theme.of(context).textTheme.display2.fontSize,
                                  color: Theme.of(context).accentColor),
                            ),
                            Text(
                              TimeUtil.monthName(
                                  TimeUtil.page2date(index, startTime).month,
                                  context),
                              style: TextStyle(
                                  fontSize:
                                  Theme.of(context).textTheme.display3.fontSize,
                                  color: Theme.of(context).accentColor),
                            )
                          ],
                        )),
                    DayGridView(
                      tasks: widget.tasks,
                      currentDate: DateTime(
                          currentTime.year, currentTime.month, currentTime.day),
                      selectDate: DateTime(
                          listPageStateNotifier.selectedDate.year, listPageStateNotifier.selectedDate.month, listPageStateNotifier.selectedDate.day),
                      year: TimeUtil.page2date(index, startTime).year,
                      month: TimeUtil.page2date(index, startTime).month,
                      dayCellAspectRatio: widget.dayCellAspectRatio,
                      onChange: onChange(listPageStateNotifier),
                    )
                  ],
                );
              },
              itemCount: TimeUtil.date2page(endTime, startTime),
              controller: widget.controller,
            ),
          ),
        ],
      ),
    );
  }
}
