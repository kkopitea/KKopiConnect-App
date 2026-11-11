import 'package:flutter/material.dart';

PageRoute<T> instantPageRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
);
