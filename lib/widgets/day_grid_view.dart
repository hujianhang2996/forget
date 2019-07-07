import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'dart:math';
import '../model/time_util.dart';
import '../model/macro.dart';
import '../generated/i18n.dart';
import '../model/model.dart';

typedef TimeSelected = void Function(
    DateTime time, int crrentYear, int currentMonth);

class DayGridView extends StatefulWidget {
  DateTime currentDate;
  DateTime selectDate;
  int year;
  int month;
  final dayCellAspectRatio;
  TimeSelected onChange;
  final List<Task> tasks;

  DayGridView(
      {Key key,
      @required this.currentDate,
      @required this.selectDate,
      @required this.year,
      @required this.month,
      this.dayCellAspectRatio = 1.3,
      this.onChange,
      this.tasks = const []});

  @override
  State<DayGridView> createState() => _DayGridViewState();
}

class _DayGridViewState extends State<DayGridView> {
  @override
  void initState() {
    super.initState();
  }

  List<Widget> _dayItems() {
    List<DateTime> days = TimeUtil.getDay(
        widget.year, widget.month, MaterialLocalizations.of(context));

    List dayWidgets = days.map((value) {
      GestureTapCallback onTap =
          () => widget.onChange(value, widget.year, widget.month);
      TextStyle dayStyle;
      Decoration dayDecoration =
          ShapeDecoration(shape: Border(), color: Colors.transparent);

      if (value == widget.currentDate) {
        dayStyle = Theme.of(context)
            .textTheme
            .subhead
            .copyWith(color: Colors.deepOrange);
      }
      if (value != widget.currentDate) {
        dayStyle = TextStyle(
            color: Theme.of(context)
                .textTheme
                .subhead
                .color
                .withAlpha(value.month == widget.month ? 255 : 100));
      }
      if (value == widget.selectDate && value.month == widget.month) {
        dayStyle = TextStyle(color: Colors.white);
        dayDecoration =
            ShapeDecoration(shape: CircleBorder(), color: Colors.deepOrange);
      }

      Offstage taskIcon =
          Offstage(offstage: true, child: Icon(Icons.lens, size: 8));

      int maxRepeatWay = 1;

      for (Task task in widget.tasks) {
        switch (task.repeatWay) {
          case 0:
            if (TimeUtil.isInSameDay(task.dateTime, value)) {
              maxRepeatWay = 0;
              taskIcon = Offstage(
                  offstage: false,
                  child: Icon(
                    Icons.lens,
                    size: 8,
                    color: value == widget.selectDate &&
                            value.month == widget.month
                        ? Colors.white
                        : Theme.of(context)
                            .textTheme
                            .body1
                            .color
                            .withAlpha(value.month == widget.month ? 255 : 100),
                  ));
            }
            break;
          case 2:
            if (task.weekDay.contains(value.weekday == 7 ? 0 : value.weekday) &&
                TimeUtil.compareInDay(value, widget.currentDate) >= 0 &&
                maxRepeatWay > 0) {
              maxRepeatWay = 2;
              taskIcon = Offstage(
                  offstage: false,
                  child: Icon(
                    Icons.trip_origin,
                    size: 8,
                    color: value == widget.selectDate &&
                            value.month == widget.month
                        ? Colors.white
                        : Theme.of(context)
                            .textTheme
                            .body1
                            .color
                            .withAlpha(value.month == widget.month ? 255 : 100),
                  ));
            }
            break;
        }
      }

      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              alignment: Alignment.center,
              decoration: dayDecoration,
              child: Text(
                value.day.toString(),
                style: dayStyle,
              ),
            ),
            Container(
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.only(bottom: 5),
                child: taskIcon)
          ],
        ),
      );
    }).toList();
    return dayWidgets;
  }

  List<TableRow> _table_rows() {
    List<Widget> list = _dayItems();
    List<TableRow> _table_rows = [];
    for (int i = 0; i < 6; i++) {
      _table_rows.add(TableRow(children: list.sublist(i * 7, (i + 1) * 7)));
    }
    return _table_rows;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> list = _dayItems();
    return AspectRatio(
        aspectRatio: widget.dayCellAspectRatio * DateTime.daysPerWeek / 6,
        child: GridView.count(
            physics: NeverScrollableScrollPhysics(),
            childAspectRatio: widget.dayCellAspectRatio,
//      mainAxisSpacing: widget.dayCellPadding * 2,
            crossAxisCount: DateTime.daysPerWeek,
            children: list,
            cacheExtent: 100));
  }
}
