/// Utility to check if a string is a valid direct image URL.
/// Accepts common image extensions and trusted image CDNs.
bool isValidImageUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final lower = url.toLowerCase();
  // Accept common image extensions
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif')) {
    return true;
  }
  // Accept Unsplash, Picsum, or other trusted image CDNs
  if (lower.contains('unsplash.com/') || lower.contains('picsum.photos/')) {
    return true;
  }
  // Add more trusted sources as needed
  return false;
}
