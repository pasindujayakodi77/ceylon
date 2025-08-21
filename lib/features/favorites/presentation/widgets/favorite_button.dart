import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:ceylon/l10n/app_localizations.dart';
import 'package:ceylon/services/favorites_provider.dart';
import 'package:flutter/material.dart';

/// A reusable favorite button that can be used across the app
class FavoriteButton extends StatefulWidget {
  final Attraction attraction;
  final Color? color;
  final Color? activeColor;
  final bool showText;
  final double size;

  const FavoriteButton({
    super.key,
    required this.attraction,
    this.color,
    this.activeColor = Colors.red,
    this.showText = false,
    this.size = 24,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attraction.id != widget.attraction.id) {
      _checkFavorite();
    }
  }

  Future<void> _checkFavorite() async {
    setState(() => _isLoading = true);

    final favoriteService = FavoritesProvider.of(context);
    final isFav = await favoriteService.isFavorite(widget.attraction.id);

    if (mounted) {
      setState(() {
        _isFavorite = isFav;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);

    final favoriteService = FavoritesProvider.of(context);
    await favoriteService.toggleFavorite(widget.attraction);

    if (mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return _isLoading
        ? SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite
                      ? widget.activeColor
                      : widget.color ?? theme.iconTheme.color,
                  size: widget.size,
                ),
                onPressed: _toggleFavorite,
                tooltip: _isFavorite
                    ? localizations.removeFavorite
                    : localizations.saveFavorite,
              ),
              if (widget.showText)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    _isFavorite
                        ? localizations.removeFavorite
                        : localizations.saveFavorite,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          );
  }
}
