import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Centralized application logging with consistent scopes and safe metadata.
abstract final class AppLogger {
  static void debug(String scope, String message,
          {Map<String, Object?> data = const {}}) =>
      _write(500, 'DEBUG', scope, message, data: data);

  static void info(String scope, String message,
          {Map<String, Object?> data = const {}}) =>
      _write(800, 'INFO', scope, message, data: data);

  static void warning(String scope, String message,
          {Map<String, Object?> data = const {}}) =>
      _write(900, 'WARN', scope, message, data: data);

  static void error(
    String scope,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> data = const {},
  }) =>
      _write(1000, 'ERROR', scope, message,
          data: data, error: error, stackTrace: stackTrace);

  static void _write(
    int level,
    String label,
    String scope,
    String message, {
    required Map<String, Object?> data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode) return;
    final safeData = _sanitize(data);
    final metadata = safeData.isEmpty ? '' : ' | ${jsonEncode(safeData)}';
    developer.log(
      '[$label] $message$metadata',
      time: DateTime.now(),
      name: 'OpenDoors.$scope',
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Map<String, Object?> _sanitize(Map<String, Object?> values) =>
      values.map((key, value) => MapEntry(key, _safeValue(key, value)));

  static Object? _safeValue(String key, Object? value) {
    final normalizedKey = key.toLowerCase();
    const sensitiveTerms = {
      'token',
      'password',
      'secret',
      'authorization',
      'base64',
      'image_bytes',
    };
    if (sensitiveTerms.any(normalizedKey.contains)) return '<redacted>';
    if (value is Map) {
      return value.map((nestedKey, nestedValue) => MapEntry(
            nestedKey.toString(),
            _safeValue(nestedKey.toString(), nestedValue),
          ));
    }
    if (value is Iterable) {
      return value.map((item) => _safeValue(key, item)).toList();
    }
    final text = value?.toString();
    if (text != null && text.length > 500) {
      return '${text.substring(0, 500)}…<truncated>';
    }
    return value == null || value is num || value is bool || value is String
        ? value
        : text;
  }
}
