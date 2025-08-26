import 'package:flutter/material.dart';

/// Returns a safe [ImageProvider] for the given [url].
///
/// - If [url] is null, empty, or uses the `file:` scheme, this returns null so
///   callers can fall back to a placeholder or omit the background image.
ImageProvider? safeNetworkImageProvider(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  try {
    final uri = Uri.parse(trimmed);
    if (uri.scheme == 'file') return null;
  } catch (_) {
    // If parsing fails, conservatively avoid using it as a network image.
    return null;
  }

  return NetworkImage(trimmed);
}
