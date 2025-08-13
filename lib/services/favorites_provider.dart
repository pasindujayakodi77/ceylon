import 'package:ceylon/services/favorites_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Provider for accessing the favorites service
class FavoritesProvider extends StatelessWidget {
  final Widget child;

  const FavoritesProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FavoritesService>(
      create: (_) => FavoritesService(),
      child: child,
    );
  }

  /// Helper method to get the favorites service from context
  static FavoritesService of(BuildContext context) {
    return Provider.of<FavoritesService>(context, listen: false);
  }

  /// Helper method to get the favorites service from context with listening
  static FavoritesService watch(BuildContext context) {
    return Provider.of<FavoritesService>(context);
  }
}
