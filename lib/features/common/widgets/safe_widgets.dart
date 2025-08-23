import 'package:flutter/material.dart';

class FlexibleErrorContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BoxConstraints constraints;
  final Alignment alignment;

  const FlexibleErrorContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.constraints = const BoxConstraints(),
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Container(
            width: width,
            height: height,
            constraints: this.constraints.copyWith(
              minWidth: constraints.minWidth,
              maxWidth: constraints.maxWidth,
            ),
            alignment: alignment,
            child: child,
          ),
        );
      },
    );
  }
}

class SafeTextController extends TextEditingController {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  set text(String newText) {
    if (_isDisposed) return;
    super.text = newText;
  }

  @override
  void clear() {
    if (_isDisposed) return;
    super.clear();
  }
}

/// Safely updates a controller's value only if it's not disposed
void safeSetText(TextEditingController? controller, String text) {
  if (controller == null) return;

  try {
    controller.text = text;
  } catch (e) {
    debugPrint('Error setting text on controller: $e');
  }
}

/// Creates a Unique GlobalKey to prevent duplicate key issues
GlobalKey createUniqueKey(String purpose) {
  return GlobalKey(
    debugLabel: '${purpose}_${DateTime.now().microsecondsSinceEpoch}',
  );
}
