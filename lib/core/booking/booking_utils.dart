import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

/// Build a WhatsApp deep link with a sanitized international phone (E.164 or digits) and message.
Uri buildWhatsAppUri({required String phone, required String message}) {
  // Sanitize: keep + and digits only
  final normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final text = Uri.encodeComponent(message);
  // Use the universal wa.me link so it works on iOS/Android/Web
  return Uri.parse('https://wa.me/$normalized?text=$text');
}

/// Build a generic https URL for booking forms (Google Forms or any site).
Uri buildFormUri(String url) => Uri.parse(url);

/// Open a URL safely (external app/browser).
Future<bool> openUri(Uri uri) async {
  // Prefer external application for wa.me; web fallback opens a new tab
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

/// Convenience: try WhatsApp first; if it fails, return false so caller can show a snackbar.
Future<bool> openWhatsApp({
  required String phone,
  required String message,
}) async {
  final uri = buildWhatsAppUri(phone: phone, message: message);
  return openUri(uri);
}
