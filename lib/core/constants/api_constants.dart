/// API and storage constants used throughout the app.
class ApiConstants {
  ApiConstants._();

  // ── REST Countries API ──────────────────────────────────────────────

  /// Base URL for the REST Countries API.
  static const String baseUrl = 'https://restcountries.com/v3.1';

  /// Endpoint to fetch all countries with only the fields we need.
  static const String allCountriesEndpoint = '$baseUrl/all?fields=name,cca2';

  // ── Flag CDN ────────────────────────────────────────────────────────

  /// URL template for flag images. Replace `{iso}` with the lowercase
  /// ISO 3166-1 alpha-2 code (e.g. `de`, `fr`, `jp`).
  static const String flagUrlTemplate = 'https://flagcdn.com/w320/{iso}.png';

  /// Builds a flag image URL for the given ISO code.
  static String flagUrl(String isoCode) =>
      flagUrlTemplate.replaceFirst('{iso}', isoCode.toLowerCase());

  // ── SharedPreferences Keys ─────────────────────────────────────────

  /// Key for the user's cumulative score.
  static const String prefKeyTotalPoints = 'total_points';

  /// Key for the JSON-encoded list of solved flag ISO codes.
  static const String prefKeySolvedFlags = 'solved_flags';
}
