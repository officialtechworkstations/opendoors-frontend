/// Keeps track of every OTP issued during the current verification session.
///
/// SMS providers can deliver messages out of order. Retaining the earlier codes
/// prevents a valid, delayed message from being rejected after the user taps
/// resend. The tracker lives only as long as the OTP screen does.
class OtpCodeTracker {
  OtpCodeTracker([Object? initialCode]) {
    add(initialCode);
  }

  final Set<String> _codes = <String>{};

  void add(Object? code) {
    final normalized = _normalize(code);
    if (normalized.isNotEmpty) {
      _codes.add(normalized);
    }
  }

  bool accepts(Object? code) => _codes.contains(_normalize(code));

  static String _normalize(Object? code) => code?.toString().trim() ?? '';
}
