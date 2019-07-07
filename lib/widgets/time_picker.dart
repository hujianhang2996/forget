import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/rendering.dart';

class ItemScrollPhysics extends ScrollPhysics {
  /// Creates physics for snapping to item.
  /// Based on PageScrollPhysics
  final double itemHeight;
  final double targetPixelsLimit;

  const ItemScrollPhysics({
    ScrollPhysics parent,
    this.itemHeight,
    this.targetPixelsLimit = 3.0,
  }) : assert(itemHeight != null && itemHeight > 0),
        super(parent: parent);

  @override
  ItemScrollPhysics applyTo(ScrollPhysics ancestor) {
    return ItemScrollPhysics(parent: buildParent(ancestor), itemHeight: itemHeight);
  }

  double _getItem(ScrollPosition position) {
    double maxScrollItem = (position.maxScrollExtent / itemHeight).floorToDouble();
    return min(max(0, position.pixels / itemHeight), maxScrollItem);
  }

  double _getPixels(ScrollPosition position, double item) {
    return item * itemHeight;
  }

  double _getTargetPixels(ScrollPosition position, Tolerance tolerance, double velocity) {
    double item = _getItem(position);
    if (velocity < -tolerance.velocity)
      item -= targetPixelsLimit;
    else if (velocity > tolerance.velocity)
      item += targetPixelsLimit;
    return _getPixels(position, item.roundToDouble());
  }

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a item boundary.
//    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
//        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent))
//      return super.createBallisticSimulation(position, velocity);
    Tolerance tolerance = this.tolerance;
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels)
      return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

typedef SelectedIndexCallback = void Function(int) ;
typedef TimePickerCallback = void Function(DateTime) ;

class TimePickerSpinner extends StatefulWidget {
  final DateTime time;
  final int minutesInterval;
  final TextStyle highlightedTextStyle;
  final TextStyle normalTextStyle;
  final double itemHeight;
  final double itemWidth;
  final AlignmentGeometry alignment;
  final double spacing;
  final bool isForce2Digits;
  final TimePickerCallback onTimeChange;

  TimePickerSpinner({
    Key key,
    this.time,
    this.minutesInterval = 1,
    this.highlightedTextStyle,
    this.normalTextStyle,
    this.itemHeight,
    this.itemWidth,
    this.alignment,
    this.spacing,
    this.isForce2Digits = false,
    this.onTimeChange
  }) : super(key: key);

  @override
  _TimePickerSpinnerState createState() => new _TimePickerSpinnerState();

}

class _TimePickerSpinnerState extends State<TimePickerSpinner> {
  ScrollController hourController = new ScrollController();
  ScrollController minuteController = new ScrollController();
  int currentSelectedHourIndex = -1;
  int currentSelectedMinuteIndex = -1;
  DateTime currentTime;
  bool isHourScrolling = false;
  bool isMinuteScrolling = false;

  /// default settings
  TextStyle defaultHighlightTextStyle = new TextStyle(
      fontSize: 32,
      color: Colors.black
  );
  TextStyle defaultNormalTextStyle = new TextStyle(
      fontSize: 32,
      color: Colors.black54
  );
  double defaultItemHeight = 60;
  double defaultItemWidth = 45;
  double defaultSpacing = 20;
  AlignmentGeometry defaultAlignment = Alignment.centerRight;

  /// getter

  TextStyle _getHighlightedTextStyle(){
    return widget.highlightedTextStyle ?? defaultHighlightTextStyle;
  }
  TextStyle _getNormalTextStyle(){
    return widget.normalTextStyle ?? defaultNormalTextStyle;
  }
  int _getMinuteCount(){
    return (60 / widget.minutesInterval).floor();
  }
  double _getItemHeight(){
    return widget.itemHeight ?? defaultItemHeight;
  }
  double _getItemWidth(){
    return widget.itemWidth ?? defaultItemWidth;
  }
  double _getSpacing(){
    return widget.spacing ?? defaultSpacing;
  }
  AlignmentGeometry _getAlignment(){
    return widget.alignment ?? defaultAlignment;
  }

  bool isLoop(int value){
    return value > 10;
  }
  DateTime getDateTime() {
    int hour = currentSelectedHourIndex - 24;
    int minute = (currentSelectedMinuteIndex - (isLoop(_getMinuteCount()) ? _getMinuteCount() : 1)) * widget.minutesInterval;
    return DateTime(currentTime.year, currentTime.month, currentTime.day, hour, minute);
  }

  @override
  void initState() {
    currentTime = widget.time ?? DateTime.now();

    currentSelectedMinuteIndex = (currentTime.minute / widget.minutesInterval).floor() + _getMinuteCount();
    minuteController = new ScrollController(initialScrollOffset: (currentSelectedMinuteIndex - 1) * _getItemHeight() );

    currentSelectedHourIndex = (currentTime.hour % 24) + 24;
    hourController = new ScrollController(initialScrollOffset: (currentSelectedHourIndex - 1) * _getItemHeight() );
    super.initState();

    if(widget.onTimeChange != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onTimeChange(getDateTime()));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [
      new SizedBox(
        width: _getItemWidth(),
        height: _getItemHeight() * 3,
        child: spinner(
          hourController,
          24,
          currentSelectedHourIndex,
          isHourScrolling,
          1,
              (index) {
            currentSelectedHourIndex = index;
            isHourScrolling = true;
          },
              () => isHourScrolling = false,
        ),
      ),
      spacer(),
      new SizedBox(
        width: _getItemWidth(),
        height: _getItemHeight() * 3,
        child: spinner(
          minuteController,
          _getMinuteCount(),
          currentSelectedMinuteIndex,
          isMinuteScrolling,
          widget.minutesInterval,
              (index) {
            currentSelectedMinuteIndex = index;
            isMinuteScrolling = true;
          },
              () => isMinuteScrolling = false,
        ),
      ),
    ];

    return new Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: contents,
    );
  }

  Widget spacer(){
    return new Container(
      width: _getSpacing(),
      height: _getItemHeight() * 3,
    );
  }

  Widget spinner(
      ScrollController controller,
      int max,
      int selectedIndex,
      bool isScrolling,
      int interval,
      SelectedIndexCallback onUpdateSelectedIndex,
      VoidCallback onScrollEnd
      ){
    /// wrapping the spinner with stack and add container above it when it's scrolling
    /// this thing is to prevent an error causing by some weird stuff like this
    /// flutter: Another exception was thrown: 'package:flutter/src/widgets/scrollable.dart': Failed assertion: line 469 pos 12: '_hold == null || _drag == null': is not true.
    /// maybe later we can find out why this error is happening

    Widget _spinner = NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification){
        if(scrollNotification is UserScrollNotification){
          if(scrollNotification.direction == ScrollDirection.idle) {
            if(isLoop(max)) {
              int segment = (selectedIndex / max).floor();
              if (segment == 0) {
                onUpdateSelectedIndex(selectedIndex + max);
                controller.jumpTo(controller.offset + (max * _getItemHeight()));
              }
              else if (segment == 2) {
                onUpdateSelectedIndex(selectedIndex - max);
                controller.jumpTo(controller.offset - (max * _getItemHeight()));
              }
            }
            setState(() {
              onScrollEnd();
              if(widget.onTimeChange != null) {
                widget.onTimeChange(getDateTime());
              }
            });
          }
        }
        else if (scrollNotification is ScrollUpdateNotification){
          setState(() {
            onUpdateSelectedIndex((controller.offset / _getItemHeight()).round() + 1);
          });
        }
      },
      child: new ListView.builder(
        itemBuilder: (context, index) {
          String text = '';
          if(isLoop(max)){
            text = ((index % max) * interval).toString();
          }
          else if(index != 0 && index != max + 1){
            text = (((index - 1)  % max) * interval).toString();
          }
          if(widget.isForce2Digits && text != ''){
            text = text.padLeft(2, '0');
          }
          return new Container(
            height: _getItemHeight(),
            alignment: _getAlignment(),
            child: new Text(
              text,
              style: selectedIndex == index
                  ? _getHighlightedTextStyle()
                  : _getNormalTextStyle(),
            ),
          );
        },
        controller: controller,
        itemCount: isLoop(max) ? max * 3 : max + 2,
        physics: ItemScrollPhysics(
            itemHeight: _getItemHeight()
        ),
      ),
    );

    return new Stack(
      children: <Widget>[
        Positioned.fill(
            child: _spinner
        ),
        isScrolling
            ? Positioned.fill(
            child: new Container()
        )
            : new Container()
      ],
    );
  }
}
