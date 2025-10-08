// import 'dart:developer';

// class ContactInfoFilter {
//   static bool containsContactInfo(String message) {
//     String normalized = _normalizeMessage(message);

//     return _containsPhoneNumber(normalized) ||
//         _containsEmailAddress(normalized) ||
//         _containsDisguisedContact(normalized);
//   }

//   static bool _containsPhoneNumber(String message) {
//     // First check if this looks like a price/non-phone context
//     // if (_isNonPhoneContext(message)) {
//     //   return false;
//     // }

//     List<RegExp> phonePatterns = [
//       // Standard formats: 555-123-4567, 555.123.4567, 555 123 4567
//       RegExp(r'\b\d{3}[-.\s]\d{3}[-.\s]\d{4}\b'),

//       // International with country code: +1-555-123-4567, +234 803 123 4567
//       RegExp(r'\+\d{1,3}[-.\s]?\d{3}[-.\s]?\d{3}[-.\s]?\d{4,6}\b'),

//       // Long digit sequences that look like phone numbers (10-15 digits)
//       RegExp(r'\b\d{10,15}\b'),

//       // Phone with context: "call me at 555123456", "my number is 555123456"
//       // RegExp(
//       //     r'\b(call|text|phone|number|reach)\s*(me|us)?\s*(at|is|on)?\s*:?\s*\+?\d{10,15}\b'),

//       // Bracketed area codes: (555) 123-4567
//       RegExp(r'\(\d{3}\)\s*\d{3}[-.\s]?\d{4}'),
//     ];

//     for (RegExp pattern in phonePatterns) {
//       if (pattern.hasMatch(message)) {
//         // Additional validation to avoid house numbers, years, etc.
//         if (_isLikelyPhoneNumber(message, pattern)) {
//           return true;
//         }
//       }
//     }

//     return false;
//   }

//   static bool _containsEmailAddress(String message) {
//     List<RegExp> emailPatterns = [
//       // Standard email: user@domain.com
//       RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),

//       // Disguised email: user at domain dot com
//       RegExp(r'\b\w+\s*(at|@)\s*\w+\s*(dot|\.)\s*\w{2,}\b'),

//       // Spaced email: user @ domain . com
//       RegExp(r'\b\w+\s*@\s*\w+\s*\.\s*\w{2,}\b'),

//       // Bracket/symbol replacement: user[at]domain[dot]com
//       RegExp(r'\b\w+\[at\]\w+\[dot\]\w{2,}\b'),
//       RegExp(r'\b\w+\(at\)\w+\(dot\)\w{2,}\b'),
//     ];

//     return emailPatterns.any((pattern) => pattern.hasMatch(message));
//   }

//   static bool _containsDisguisedContact(String message) {
//     // Word-to-number substitution detection
//     if (_containsWordedPhoneNumber(message)) {
//       return true;
//     }

//     if (_isNonPhoneContext(message)) {
//       // log('here');
//       return false;
//     }

//     // Other disguised contact patterns
//     List<RegExp> disguisedPatterns = [
//       // Creative spacing: "5 5 5 - 1 2 3 - 4 5 6 7"
//       // RegExp(r'\b(\d\s*){10,15}\b'),

//       // Alternative separators: "555•123•4567", "555★123★4567"
//       RegExp(r'\b\d{3}[^\w\s]\d{3}[^\w\s]\d{4}\b'),

//       // Email with creative separators
//       RegExp(r'\b\w+[^\w\s@]\w+[^\w\s@]\w{2,}\b'),
//     ];

//     return disguisedPatterns.any((pattern) => pattern.hasMatch(message));
//   }

//   static bool _isLikelyPhoneNumber(String message, RegExp matchedPattern) {
//     Match? match = matchedPattern.firstMatch(message);
//     if (match == null) return false;

//     String matchedText = match.group(0)!;
//     String context = _getContext(message, match.start, match.end);

//     // Exclude common false positives with stronger context checking
//     List<RegExp> excludePatterns = [
//       RegExp(r'\$\s*\d+'), // Price with dollar sign
//     ];

//     // Check if context suggests it's not a phone number
//     String fullContext = message.toLowerCase();
//     for (RegExp pattern in excludePatterns) {
//       if (pattern.hasMatch(fullContext)) {
//         // Check if the matched number is near this context
//         Match? contextMatch = pattern.firstMatch(fullContext);
//         if (contextMatch != null) {
//           int contextStart = contextMatch.start;
//           int contextEnd = contextMatch.end;
//           int matchStart = match.start;

//           // If the number is within 30 characters of the context, exclude it
//           if ((matchStart - contextEnd).abs() < 30 ||
//               (contextStart - matchStart).abs() < 30) {
//             return false;
//           }
//         }
//       }
//     }

//     // Additional validation for pure digit sequences
//     String digitsOnly = matchedText.replaceAll(RegExp(r'[^\d]'), '');

//     // Too short or too long to be a phone number
//     if (digitsOnly.length < 10 || digitsOnly.length > 15) {
//       return false;
//     }

//     // Patterns that are unlikely to be phone numbers
//     if (RegExp(r'^(0{5,}|1{5,}|2{5,}|9{5,})')
//             .hasMatch(digitsOnly) || // Repeated digits
//         RegExp(r'^(1234|2345|3456|4567|5678|6789)')
//             .hasMatch(digitsOnly) || // Sequential
//         RegExp(r'^(2024|2023|2022|2021|2020|2019|2018)')
//             .hasMatch(digitsOnly) || // Years
//         RegExp(r'00000').hasMatch(digitsOnly)) {
//       // Too many zeros
//       return false;
//     }

//     return true;
//   }

//   static bool _containsWordedPhoneNumber(String message) {
//     String normalized = message.toLowerCase();

//     // First exclude obvious non-phone contexts
//     if (_isNonPhoneContext(message)) {
//       return false;
//     }

//     // Look for sequences of written numbers that could form phone numbers
//     List<RegExp> wordedPhonePatterns = [
//       // "call me at five five five one two three four five six seven"
//       RegExp(
//           r'\b(call|text|contact|reach|forward|send)\s*(me|us|your)?\s*(at|on)?\s*((zero|one|two|three|four|five|six|seven|eight|nine|oh)\s*){7,15}\b'),

//       // "my number is five five five"
//       RegExp(
//           r'\b(number|phone)\s*(is)?\s*((zero|one|two|three|four|five|six|seven|eight|nine|oh)\s*){7,15}\b'),

//       // General pattern for written numbers in phone-like sequences
//       RegExp(
//           r'\b((zero|one|two|three|four|five|six|seven|eight|nine|oh)\s*){10,15}\b'),
//     ];

//     return wordedPhonePatterns.any((pattern) => pattern.hasMatch(normalized));
//   }

//   static bool _isNonPhoneContext(String message) {
//     String normalized = message.toLowerCase();

//     // Strong indicators this is not a phone number
//     List<RegExp> nonPhonePatterns = [
//       // Price contexts
//       // RegExp(r'\$\s*\d+'), // $25000000000
//       // RegExp(r'\b(price|cost|rent|fee|deposit|amount)\s*(is|of)?\s*\d+'),
//       // RegExp(r'\b\d+\s*(dollar|naira|usd|ngn|per\s*(month|year|week))'),

//       // Property contexts
//       // RegExp(r'\b(house|apartment|unit|room|address)\s*(number|#)?\s*\d+'),
//       // RegExp(r'\b\d+\s*(bedroom|bathroom|bath|bed|sq\s*ft|square)'),

//       // Year contexts
//       // RegExp(r'\b(year|built|constructed)\s*(in)?\s*(19|20)\d{2}'),

//       // Multiple zeros (likely prices, not phone numbers)
//       RegExp(r'\b\d*0{6,}\d*\b'), // 8 or more consecutive zeros
//     ];

//     return nonPhonePatterns.any((pattern) => pattern.hasMatch(normalized));
//   }

//   static String _getContext(String message, int start, int end) {
//     int contextStart = (start - 20).clamp(0, message.length);
//     int contextEnd = (end + 20).clamp(0, message.length);
//     return message.substring(contextStart, contextEnd).toLowerCase();
//   }

//   static String _normalizeMessage(String message) {
//     return message.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
//   }

//   // Simple usage method
//   static FilterResult filterMessage(String message) {
//     if (containsContactInfo(message)) {
//       return FilterResult(
//           blocked: true,
//           reason:
//               "Messages containing phone numbers or email addresses are not allowed for your security.",
//           suggestion: "Please use our secure in-app features to communicate.");
//     }

//     return FilterResult(
//       blocked: false,
//       reason: null,
//       suggestion: null,
//     );
//   }
// }

//

// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:developer';

class ContactInfoFilter {
  /// Public API ---------------------------------------------------------------
  static FilterResult filterMessage(String input) {
    /// Regex compilation is expensive; cache them once.
    final _phoneRegex = _buildPhoneRegex();
    final _emailRegex = _buildEmailRegex();
    final _priceRegex = _buildPriceRegex();
    final _urlRegex = RegExp(
        r'https?://[^\s/$.?#].[^\s]*|www\.[^\s/$.?#].[^\s]*',
        caseSensitive: false);

    // "call me at five five five one two three four five six seven"
    final _wordedNumber1 = RegExp(
        r'\b(call|text|contact|reach|forward|send)\s*(me|us|your)?\s*(at|on)?\s*((zero|one|two|three|four|five|six|seven|eight|nine|oh)\s*){7,15}\b');

    // "my number is five five five"
    final _wordedNumber2 = RegExp(
        r'\b(number|phone)\s*(is)?\s*((zero|one|two|three|four|five|six|seven|eight|nine|oh)\s*){7,15}\b');

    // General pattern for written numbers in phone-like sequences
    final _wordedNumber3 = RegExp(
        r'\b((zero|one|two|three|four|five|six|seven|eight|nine|oh)\s*){10,15}\b');

    try {
      final normalized = _normalize(input);

      // 1. Strip every price-looking substring so we don’t flag 1,200 as 1200
      final withoutPrice =
          normalized.replaceAllMapped(_priceRegex, (m) => 'x' * m[0]!.length);

      // 2. Check for phone numbers
      final phone = _phoneRegex.firstMatch(withoutPrice);
      if (phone != null) {
        return FilterResult(
          blocked: true,
          reason: 'Phone number detected: ${phone.group(0)}',
          suggestion: 'Please do not share personal information.',
        );
      }

      // 3. Check for e-mail addresses
      final email = _emailRegex.firstMatch(withoutPrice);
      if (email != null) {
        return FilterResult(
          blocked: true,
          reason: 'E-mail detected: ${email.group(0)}',
          suggestion: 'Please do not share personal information.',
        );
      }

      final wrd1 = _wordedNumber1.firstMatch(withoutPrice);
      if (wrd1 != null) {
        return FilterResult(
          blocked: true,
          reason: 'Phone number detected: ${wrd1.group(0)}',
          suggestion: 'Please do not share personal information.',
        );
      }

      final wrd2 = _wordedNumber2.firstMatch(withoutPrice);
      if (wrd2 != null) {
        return FilterResult(
          blocked: true,
          reason: 'Phone number detected: ${wrd2.group(0)}',
          suggestion: 'Please do not share personal information.',
        );
      }

      final wrd3 = _wordedNumber3.firstMatch(withoutPrice);
      if (wrd3 != null) {
        return FilterResult(
          blocked: true,
          reason: 'Phone number detected: ${wrd3.group(0)}',
          suggestion: 'Please do not share personal information.',
        );
      }

      // 4. Check URLs that embed phone/mail
      final urlMatch = _urlRegex.allMatches(input);
      for (final m in urlMatch) {
        final url = m.group(0)!;
        if (_phoneRegex.hasMatch(url) || _emailRegex.hasMatch(url)) {
          return FilterResult(
            blocked: true,
            reason: 'External link with contact info: $url',
            suggestion: 'Sharing external contact links is not allowed.',
          );
        }
      }

      return FilterResult(blocked: false);
    } catch (_) {
      // Defensive: never crash the chat
      return FilterResult(blocked: false);
    }
  }

  /// --------------------------------------------------------------------------
  /// Internal helpers
  /// --------------------------------------------------------------------------
  static RegExp _buildPhoneRegex() {
    // language=RegExp
    const digits = r'(?:\p{N}|\p{No})'; // Unicode digits
    const separators = r'[\s.\-_–—]*'; // any separator
    const plus = r'(?:\+|＋|﹢|﹢|﹢|﹢|﹢|﹢|﹢)';
    const open = r'[\(\[\{]';
    const close = r'[\)\]\}]';
    const ext = r'(?:e?xt?\.?|x|extension|#)';

    final patterns = [
      // +91 98765 43210
      '$plus$separators\\d{1,3}$separators\\d{3,4}$separators\\d{3,4}$separators(?:$ext$separators?\\d{1,5})?',

      // (987) 654-3210 OR 987-654-3210 OR 9876543210
      '(?:$open\\d{3}$close$separators?\\d{3}$separators\\d{4}|\\d{3}$separators\\d{3}$separators\\d{4}|\\d{10})',

      // 0 98765 43210 (leading zero)
      '(?:0$separators\\d{3,5}$separators\\d{3,5})',
    ];

    final full = patterns.map((p) => '(?:$p)').join('|');
    return RegExp(full, unicode: true, caseSensitive: false);
  }

  static RegExp _buildEmailRegex() {
    // language=RegExp
    const at = r'(?:@|(?:\[?at\]?)|\u0040|\uFF20)';
    const dot = r'(?:\.|(?:\[?dot\]?)|\u002E|\uFF0E)';
    const word = r'[\p{L}\p{N}._%+-]+';
    return RegExp('$word$at$word(?:$dot$word)+', unicode: true);
  }

  static RegExp _buildPriceRegex() {
    // language=RegExp
    return RegExp(
        r'(?:\$\s*\d{1,3}(?:,\d{3})*(?:\.\d{2})?|₹\s*\d{1,3}(?:,\d{3})*(?:\.\d{2})?|\d+(?:\.\d+)?\s*(?:k|cr|lacs?|lakh|inr|usd|ngn|naira))',
        caseSensitive: false);
  }

  static String _normalize(String text) {
    return text
        // homoglyph map (only most common)
        .replaceAll('ο', 'o')
        .replaceAll('а', 'a')
        .replaceAll('е', 'e')
        .replaceAll('і', 'i')
        // remove zero-width chars
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        // collapse repeated punctuation
        .replaceAll(RegExp(r'([+.\-_])\1{2,}'), r'$1')
        .toLowerCase();
  }
}

/// --------------------------------------------------------------------------
/// Model
/// --------------------------------------------------------------------------

class FilterResult {
  final bool blocked;
  final String? reason;
  final String? suggestion;

  FilterResult({
    required this.blocked,
    this.reason,
    this.suggestion,
  });
}

// Usage example
void filterTest() {
  // Test cases
  List<String> testMessages = [
    "Please call me at 555-123-4567", // BLOCKED - phone number
    "My email is john@example.com", // BLOCKED - email
    "Please call me when you're ready", // ALLOWED - no contact info
    "The house number is 1234", // ALLOWED - house number context
    "Built in 2020, very modern", // ALLOWED - year context
    "Call me at five five five one two three", // BLOCKED - worded phone
    "Contact: user at gmail dot com", // BLOCKED - disguised email
    "Price is \$2500 per month", // ALLOWED - price context
  ];

  for (String message in testMessages) {
    FilterResult result = ContactInfoFilter.filterMessage(message);
    log("Message: '$message'");
    log("Blocked: ${result.blocked}");
    if (result.blocked) log("Reason: ${result.reason}");
    log("---");
  }
}
