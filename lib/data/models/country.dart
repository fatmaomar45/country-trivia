import '../../core/constants/api_constants.dart';

/// Represents a country with its name and ISO alpha-2 code.
class Country {
  /// The common name of the country (e.g. "Germany").
  final String name;

  /// The ISO 3166-1 alpha-2 code (e.g. "DE").
  final String isoCode;

  const Country({required this.name, required this.isoCode});

  /// Creates a [Country] from a JSON object returned by the REST Countries API.
  ///
  /// Expected shape:
  /// ```json
  /// { "name": { "common": "Germany" }, "cca2": "DE" }
  /// ```
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name']['common'] as String,
      isoCode: json['cca2'] as String,
    );
  }

  /// The URL for this country's flag image (320px wide PNG).
  String get flagUrl => ApiConstants.flagUrl(isoCode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          isoCode == other.isoCode;

  @override
  int get hashCode => isoCode.hashCode;

  @override
  String toString() => 'Country(name: $name, isoCode: $isoCode)';
}
