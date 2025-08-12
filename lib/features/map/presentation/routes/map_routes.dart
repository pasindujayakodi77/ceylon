import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:ceylon/features/attractions/presentation/screens/place_details_screen.dart';
import 'package:ceylon/features/map/presentation/screens/attractions_map_screen_new.dart';
import 'package:flutter/material.dart';

class MapRoutes {
  static const String mapScreen = '/map';
  static const String placeDetailsScreen = '/place-details';

  static Map<String, WidgetBuilder> routes = {
    mapScreen: (context) => const AttractionsMapScreenNew(),
    // Place details requires parameters, so we use a builder function that
    // expects the parameters to be passed in the Navigator arguments
    placeDetailsScreen: (context) {
      final attraction =
          ModalRoute.of(context)!.settings.arguments as Attraction;
      return PlaceDetailsScreen(attraction: attraction);
    },
  };
}
