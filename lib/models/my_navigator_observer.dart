import 'package:flutter/material.dart';

class MyNavigatorObserver extends NavigatorObserver {
  final Function onReturn;

  MyNavigatorObserver({required this.onReturn});

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    onReturn();
  }
}