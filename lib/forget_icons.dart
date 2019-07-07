import 'package:flutter/widgets.dart';

class ForgetIcon {
  static const IconData dash_circle = const _ForgetIconData(0xe686);
  static const IconData select_all = const _ForgetIconData(0xe678);
  static const IconData unselect = const _ForgetIconData(0xe679);
  static const IconData unassigned = const _ForgetIconData(0xe782);
}

class _ForgetIconData extends IconData {
  const _ForgetIconData(int codePoint)
      : super(
    codePoint,
    fontFamily: 'ForgetIcon',
  );
}