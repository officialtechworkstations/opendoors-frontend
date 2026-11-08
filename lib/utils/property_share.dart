import 'package:flutter/material.dart';
import 'package:opendoors/Api/config.dart';
import 'package:share_plus/share_plus.dart';

/// Shares text and URLs so receiving apps do not discard the message when an
/// image file is attached. Link previews depend on the receiving app/site.
class PropertyShare {
  static String? imageUrl(String? path) {
    final value = path?.trim();
    if (value == null || value.isEmpty || value == 'null') return null;
    return Uri.parse(Config.imageUrl).resolve(value).toString();
  }

  static Future<void> share({
    required BuildContext context,
    required String message,
    required String subject,
    String? link,
    String? propertyImage,
  }) async {
    final size = MediaQuery.sizeOf(context);
    final origin = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
    final parts = <String>[message];
    final hasShareLink = link?.trim().isNotEmpty == true;
    if (hasShareLink) parts.add(link!.trim());
    final photoUrl = imageUrl(propertyImage);
    if (!hasShareLink && photoUrl != null) {
      parts.add('Property photo: $photoUrl');
    }
    final text = parts.join('\n');
    await Share.share(text, subject: subject, sharePositionOrigin: origin);
  }
}
