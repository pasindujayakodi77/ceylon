import 'package:ceylon/features/map/presentation/screens/attractions_map_screen_new.dart';
import 'package:flutter/material.dart';

class MapRoutes {
  static const String mapScreen = '/map';

  static Map<String, WidgetBuilder> routes = {
    mapScreen: (context) => const AttractionsMapScreenNew(),
  };
}
