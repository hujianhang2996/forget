import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../generated/i18n.dart';

typedef WeekPickerCallback = VoidCallback Function(int) ;
class TimeUtil {
  static const List<int> _daysInMonth = <int>[
    31,
    -1,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  ];

  /// 获取这个月的天数
  static int getDaysInMonth(int year, int month) {
    if (month == DateTime.february) {
      final bool isLeapYear =
          (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
      if (isLeapYear) return 29;
      return 28;
    }
    return _daysInMonth[month - 1];
  }

  /// 获取周Header
  static List<Widget> getDayHeaders(
      MaterialLocalizations localizations, double padding) {
    List<Widget> list = [];
    for (int i = localizations.firstDayOfWeekIndex; true; i = (i + 1) % 7) {
      final String weekday = localizations.narrowWeekdays[i];
      list.add(Flexible(
          child: Container(
        padding: EdgeInsets.only(top: padding, bottom: padding),
        alignment: Alignment.center,
        child: Text(weekday),
      )));
      if (i == (localizations.firstDayOfWeekIndex - 1) % 7) break;
    }
    return list;
  }

  static List<Widget> getDayButtons(BuildContext context,
      MaterialLocalizations localizations, double padding, List<int> weekList, WeekPickerCallback onPressed) {
    List<Widget> list = [];
    for (int i = localizations.firstDayOfWeekIndex; true; i = (i + 1) % 7) {
      final String weekday = localizations.narrowWeekdays[i];
      list.add(Flexible(
          child: FlatButton(
        child: Text(weekday, style: TextStyle(color: weekList.contains(i) ? Colors.deepOrange : null)),
        onPressed: onPressed(i),
      )));
      if (i == (localizations.firstDayOfWeekIndex - 1) % 7) break;
    }
    return list;
  }

  /// 得到这个月的第一天是星期几（0 是 星期日 1 是 星期一...）
  static int computeFirstDayOffset(
      int year, int month, MaterialLocalizations localizations) {
    // 0-based day of week, with 0 representing Monday.
    final int weekdayFromMonday = DateTime(year, month).weekday - 1;
    // 0-based day of week, with 0 representing Sunday.
    final int firstDayOfWeekFromSunday = localizations.firstDayOfWeekIndex;
    // firstDayOfWeekFromSunday recomputed to be Monday-based
    final int firstDayOfWeekFromMonday = (firstDayOfWeekFromSunday - 1) % 7;
    // Number of days between the first day of week appearing on the calendar,
    // and the day corresponding to the 1-st of the month.
    return (weekdayFromMonday - firstDayOfWeekFromMonday) % 7;
  }

  /// 获取某个月所有的天
  static List<DateTime> getDay(
      int year, int month, MaterialLocalizations localizations) {
    List<DateTime> labels = [];
    final int daysInMonth = getDaysInMonth(year, month);
    final int firstDayOffset =
        computeFirstDayOffset(year, month, localizations);
    final int daysInMonthCeil = 6 * DateTime.daysPerWeek;
    for (int i = 0; i < daysInMonthCeil; i += 1) {
      // 1-based day of month, e.g. 1-31 for January, and 1-29 for February on
      // a leap year.
      final int day = i - firstDayOffset + 1;
      if (day < 1) {
        if (month == 1) {
          labels
              .add(DateTime(year - 1, 12, getDaysInMonth(year - 1, 12) + day));
        } else {
          labels.add(
              DateTime(year, month - 1, getDaysInMonth(year, month - 1) + day));
        }
      }
      if (day >= 1 && day <= daysInMonth) {
        labels.add(DateTime(year, month, day));
      }
      if (day > daysInMonth && day <= daysInMonthCeil - firstDayOffset) {
        if (month == 12) {
          labels.add(DateTime(year + 1, 1, day - daysInMonth));
        } else {
          labels.add(DateTime(year, month + 1, day - daysInMonth));
        }
      }
    }
    return labels;
  }

  static DateTime page2date(int page, DateTime startTime) {
    int year = startTime.year + ((startTime.month + page - 1) / 12).floor();
    int month =
        (startTime.month + page) % 12 == 0 ? 12 : (startTime.month + page) % 12;
    return DateTime(year, month);
  }

  static int date2page(DateTime date, DateTime startTime) {
    return (date.year - startTime.year) * 12 + date.month - startTime.month;
  }

  static bool isInSameMonth(DateTime timea, DateTime timeb) {
    return (timea.year * 12 + timea.month == timeb.year * 12 + timeb.month);
  }

  static bool isInSameDay(DateTime timea, DateTime timeb) {
    return (timea.year * 12 + timea.month == timeb.year * 12 + timeb.month && timea.day == timeb.day);
  }

  static int compareInDay(DateTime timea, DateTime timeb) {
    if(timea.year * 12 + timea.month == timeb.year * 12 + timeb.month && timea.day == timeb.day){
      return 0;
    }
    return timea.compareTo(timeb);
  }

  static String monthName(int month, BuildContext context) {
    switch (month) {
      case 1:
        return S.of(context).Jan;
      case 2:
        return S.of(context).Feb;
      case 3:
        return S.of(context).Mar;
      case 4:
        return S.of(context).Apr;
      case 5:
        return S.of(context).May;
      case 6:
        return S.of(context).Jun;
      case 7:
        return S.of(context).Jul;
      case 8:
        return S.of(context).Aug;
      case 9:
        return S.of(context).Sep;
      case 10:
        return S.of(context).Oct;
      case 11:
        return S.of(context).Nov;
      case 12:
        return S.of(context).Dec;
    }
  }

  static String shortName(DateTime time) {
    return '${time.month}-${time.day}';
  }
}

int ceilDivide(int a, int b) {
  int remainder = a % b;
  int c = a ~/ b;
  return remainder == 0 ? c : (c + 1);
}
