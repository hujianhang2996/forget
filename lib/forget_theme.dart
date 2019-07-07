import 'package:flutter/material.dart';

ThemeData forgetLightTheme() {
  return ThemeData.light().copyWith(
      primaryColor: Colors.grey[200],
      accentColor: Colors.white,
      textSelectionColor: Colors.white,
      scaffoldBackgroundColor: Colors.grey[200],
      primaryColorBrightness: Brightness.light);
}

ThemeData forgetDarkTheme() {
  return ThemeData.dark().copyWith(
      primaryColor: Colors.grey[800],
      accentColor: Colors.grey[600],
      scaffoldBackgroundColor: Colors.grey[800],
      textSelectionColor: Colors.black,
      cardColor: Colors.grey[600],
//  chipTheme: ThemeData.dark().chipTheme.copyWith(backgroundColor: Colors.grey[850])
      );
}
