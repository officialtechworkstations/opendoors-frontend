import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/model/fontfamily_model.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool alingment;
  final Color chatColor;
  final Color textColor;
  const ChatBubble(
      {super.key,
      required this.message,
      required this.alingment,
      required this.chatColor,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? propertyData;
    if (message.startsWith('{') && message.endsWith('}')) {
      try {
        final parsed = jsonDecode(message);
        if (parsed is Map<String, dynamic> && parsed['type'] == 'property') {
          propertyData = parsed;
        }
      } catch (_) {
        // Not a JSON message or parse error
      }
    }

    if (propertyData != null) {
      final String imageUrl = propertyData['image'] ?? '';
      final String title = propertyData['title'] ?? '';
      final String address = propertyData['address'] ?? '';
      final String info = propertyData['message'] ?? '';

      return Container(
        width: 250,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(alingment ? 0 : 12),
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomRight: Radius.circular(alingment ? 12 : 0)),
          color: chatColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl.startsWith('http') ? imageUrl : '${Config.imageUrl}$imageUrl',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: FontFamily.gilroyBold,
              ),
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: textColor.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.8),
                        fontFamily: FontFamily.gilroyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Divider(color: textColor.withOpacity(0.3), height: 1),
            const SizedBox(height: 6),
            Text(
              info,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontFamily: FontFamily.gilroyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(alingment ? 0 : 12),
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomRight: Radius.circular(alingment ? 12 : 0)),
        color: chatColor,
      ),
      child: Text(
        message,
        style: TextStyle(
            fontSize: 16,
            color: textColor,
            fontFamily: FontFamily.gilroyMedium),
      ),
    );
  }
}
