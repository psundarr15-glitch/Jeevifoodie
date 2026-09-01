import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Deliberately does NOT include a generic "open this URL in a browser"
/// method - the app must never redirect to the web frontend for any
/// reason, since that frontend won't be deployed once the app ships
/// (see StaticPageScreen, DeliveryPartnerSignupScreen, VendorSignupScreen
/// for the in-app replacements). tel:/mailto: below are OS-level
/// intents, not the app leaving to a website, so they're fine to keep.
class LinkLauncher {
  static Future<void> call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't start a call")),
      );
    }
  }

  static Future<void> email(BuildContext context, String address) async {
    final uri = Uri(scheme: 'mailto', path: address);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open an email app")),
      );
    }
  }
}
