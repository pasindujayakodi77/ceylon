// FILE: lib/design_system/widgets/skeletons.dart
import 'package:flutter/material.dart';
import '../tokens.dart';

/// A collection of skeleton (shimmer) loading widgets for different components.
/// These widgets are used to indicate that content is loading.

/// Base skeleton box with configurable dimensions and border radius
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveBorderRadius = borderRadius ?? 
        BorderRadius.circular(CeylonTokens.radiusSmall);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        color: colorScheme.surfaceVariant.withOpacity(
          theme.brightness == Brightness.dark ? 0.3 : 0.5
        ),
      ),
      child: _buildShimmerEffect(context),
    );
  }

  Widget _buildShimmerEffect(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        final colorScheme = Theme.of(context).colorScheme;
        final baseColor = colorScheme.surfaceVariant;
        final highlightColor = Theme.of(context).brightness == Brightness.dark
            ? baseColor.withOpacity(0.05)
            : baseColor.withOpacity(0.2);

        return LinearGradient(
          begin: const Alignment(-1.0, -0.5),
          end: const Alignment(1.0, 0.5),
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: const [0.0, 0.5, 1.0],
          tileMode: TileMode.mirror,
        ).createShader(bounds);
      },
      child: Container(
        color: Colors.white,
      ),
    );
  }
}

/// Skeleton for text lines with customizable count and width
class SkeletonText extends StatelessWidget {
  final int lines;
  final double height;
  final double? width;
  final double spacing;
  final double? lastLineWidth;
  final EdgeInsetsGeometry padding;

  const SkeletonText({
    super.key,
    this.lines = 3,
    this.height = 16.0,
    this.width,
    this.spacing = 8.0,
    this.lastLineWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          lines,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < lines - 1 ? spacing : 0),
            child: SkeletonBox(
              width: index == lines - 1 && lastLineWidth != null
                  ? lastLineWidth!
                  : width ?? double.infinity,
              height: height,
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a list tile with leading, title, and subtitle
class SkeletonListTile extends StatelessWidget {
  final double height;
  final double? leadingSize;
  final bool showLeading;
  final bool showSubtitle;
  final EdgeInsetsGeometry padding;

  const SkeletonListTile({
    super.key,
    this.height = 72.0,
    this.leadingSize = 40.0,
    this.showLeading = true,
    this.showSubtitle = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: CeylonTokens.spacing16,
      vertical: CeylonTokens.spacing12,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      child: Row(
        children: [
          if (showLeading) ...[
            SkeletonBox(
              width: leadingSize!,
              height: leadingSize!,
              borderRadius: BorderRadius.circular(CeylonTokens.radiusSmall),
            ),
            const SizedBox(width: CeylonTokens.spacing16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SkeletonBox(
                  width: double.infinity,
                  height: 18.0,
                ),
                if (showSubtitle) ...[
                  const SizedBox(height: CeylonTokens.spacing8),
                  SkeletonBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 14.0,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a card with image and content
class SkeletonCard extends StatelessWidget {
  final double width;
  final double height;
  final double imageHeight;
  final bool showImage;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const SkeletonCard({
    super.key,
    this.width = double.infinity,
    this.height = 260.0,
    this.imageHeight = 140.0,
    this.showImage = true,
    this.padding = const EdgeInsets.all(CeylonTokens.spacing16),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? 
        BorderRadius.circular(CeylonTokens.radiusMedium);

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        color: Theme.of(context).colorScheme.surface,
        boxShadow: CeylonTokens.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage)
            SkeletonBox(
              width: double.infinity,
              height: imageHeight,
              borderRadius: BorderRadius.only(
                topLeft: effectiveBorderRadius.topLeft,
                topRight: effectiveBorderRadius.topRight,
              ),
            ),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(
                  width: double.infinity,
                  height: 20.0,
                ),
                const SizedBox(height: CeylonTokens.spacing12),
                SkeletonText(
                  lines: 2,
                  height: 14.0,
                  spacing: 8.0,
                  lastLineWidth: width * 0.7,
                ),
                const SizedBox(height: CeylonTokens.spacing16),
                Row(
                  children: [
                    const SkeletonBox(
                      width: 80.0,
                      height: 24.0,
                      borderRadius: BorderRadius.all(
                        Radius.circular(CeylonTokens.radiusMedium),
                      ),
                    ),
                    const Spacer(),
                    const SkeletonBox(
                      width: 24.0,
                      height: 24.0,
                      borderRadius: BorderRadius.all(
                        Radius.circular(CeylonTokens.radiusSmall),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A list of skeleton items
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final bool showLeading;
  final bool showDividers;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72.0,
    this.showLeading = true,
    this.showDividers = true,
    this.padding = EdgeInsets.zero,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final listItems = List.generate(
      itemCount,
      (index) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonListTile(
            height: itemHeight,
            showLeading: showLeading,
          ),
          if (showDividers && index < itemCount - 1)
            const Divider(height: 1),
        ],
      ),
    );

    if (scrollable) {
      return ListView(
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: listItems,
      );
    }

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: listItems,
      ),
    );
  }
}

/// A grid of skeleton cards
class SkeletonGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final double itemHeight;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  const SkeletonGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
    this.itemHeight = 260.0,
    this.mainAxisSpacing = CeylonTokens.spacing16,
    this.crossAxisSpacing = CeylonTokens.spacing16,
    this.padding = const EdgeInsets.all(CeylonTokens.spacing16),
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final gridItems = List.generate(
      itemCount,
      (index) => SkeletonCard(
        height: itemHeight,
      ),
    );

    if (scrollable) {
      return GridView.count(
        padding: padding,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: (1 / (itemHeight / ((MediaQuery.of(context).size.width - padding.horizontal - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount))),
        children: gridItems,
      );
    }

    return Padding(
      padding: padding,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: (1 / (itemHeight / ((MediaQuery.of(context).size.width - padding.horizontal - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount))),
        children: gridItems,
      ),
    );
  }
}
