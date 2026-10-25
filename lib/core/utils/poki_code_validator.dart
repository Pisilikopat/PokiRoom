// lib/core/utils/poki_code_validator.dart

class PokiCodeValidator {
  PokiCodeValidator._();

  static const String prefix = '#POKI-';
  static final RegExp _suffixPattern = RegExp(r'^[A-Z0-9]{4,12}$');

  /// "#poki-4829", "POKI-4829", " 4829 " -> "4829"
  static String extractSuffix(String input) {
    var v = input.trim().toUpperCase().replaceAll(' ', '');
    if (v.startsWith('#')) v = v.substring(1);
    if (v.startsWith('POKI-')) v = v.substring(5);
    return v;
  }

  static bool isValidSuffix(String suffix) => _suffixPattern.hasMatch(suffix);

  static String toFullTag(String suffix) => '$prefix$suffix';
}
