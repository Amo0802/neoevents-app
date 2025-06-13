import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;
  
  static Future<T?> navigateTo<T>(Route<T> route) {
    return navigator!.push(route);
  }
  
  static Future<T?> navigateToNamed<T>(String routeName, {Object? arguments}) {
    return navigator!.pushNamed(routeName, arguments: arguments);
  }
  
  static void goBack<T>([T? result]) {
    return navigator!.pop(result);
  }
}