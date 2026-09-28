import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';

/// Wraps SharedPreferences for persisting user progress and score.
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Creates a [StorageService] with the default SharedPreferences instance.
  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ── Solved Flags ────────────────────────────────────────────────────

  /// Loads the set of ISO codes for all solved flags.
  Future<Set<String>> getSolvedFlags() async {
    final jsonString = _prefs.getString(ApiConstants.prefKeySolvedFlags);
    if (jsonString == null || jsonString.isEmpty) return {};
    try {
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      return decoded.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// Adds a solved flag's ISO code to the persisted set.
  Future<void> addSolvedFlag(String isoCode) async {
    final current = await getSolvedFlags();
    current.add(isoCode);
    await _prefs.setString(
      ApiConstants.prefKeySolvedFlags,
      json.encode(current.toList()),
    );
  }

  // ── Score ───────────────────────────────────────────────────────────

  /// Loads the user's cumulative score.
  Future<int> getScore() async {
    return _prefs.getInt(ApiConstants.prefKeyTotalPoints) ?? 0;
  }

  /// Persists the user's cumulative score.
  Future<void> saveScore(int score) async {
    await _prefs.setInt(ApiConstants.prefKeyTotalPoints, score);
  }
}
