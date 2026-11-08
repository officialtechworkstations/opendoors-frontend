import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:opendoors/model/routes_helper.dart';

/// Handles the public property URLs after the app's splash flow has finished.
class PropertyDeepLinks {
  PropertyDeepLinks._();

  static final PropertyDeepLinks instance = PropertyDeepLinks._();
  static const String host = 'links.opendoorsapp.com';

  StreamSubscription<Uri>? _subscription;
  String? _pendingPropertyId;
  bool _ready = false;
  bool _navigationScheduled = false;

  static String? propertyIdFromUri(Uri uri) {
    if (uri.scheme != 'https' || uri.host != host || uri.hasPort) return null;
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments.first != 'properties') return null;
    final id = segments.last.trim();
    if (id.isEmpty || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) return null;
    return id;
  }

  void start() {
    _subscription ??= AppLinks().uriLinkStream.listen((uri) {
      final id = propertyIdFromUri(uri);
      if (id == null) return;
      _pendingPropertyId = id;
      _openPending();
    });
  }

  void markReady() {
    _ready = true;
    _openPending();
  }

  void _openPending() {
    if (!_ready || _pendingPropertyId == null || _navigationScheduled) return;
    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationScheduled = false;
      final id = _pendingPropertyId;
      if (!_ready || id == null) return;
      _pendingPropertyId = null;
      Get.toNamed(Routes.viewDataScreen, arguments: {'id': id});
      if (_pendingPropertyId != null) _openPending();
    });
  }
}
