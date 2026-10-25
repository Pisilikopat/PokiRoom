// lib/core/errors/poki_exception.dart

/// Kullanıcıya doğrudan gösterilebilecek, sevimli dilli hata.
class PokiException implements Exception {
  const PokiException(this.message);
  final String message;

  @override
  String toString() => message;
}
