import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistent user preferences for pandals:
/// - Favorite / Bookmarked pandals
/// - Visited / Hopped pandals with hopping stats
class PandalUserStateService extends ChangeNotifier {
  static const String _favoritesKey = 'user_favorite_pandals';
  static const String _visitedKey = 'user_visited_pandals';

  final SharedPreferences _prefs;
  final Set<String> _favoriteIds = {};
  final Set<String> _visitedIds = {};

  PandalUserStateService(this._prefs) {
    _loadState();
  }

  static Future<PandalUserStateService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PandalUserStateService(prefs);
  }

  void _loadState() {
    final favList = _prefs.getStringList(_favoritesKey) ?? [];
    _favoriteIds.addAll(favList);

    final visList = _prefs.getStringList(_visitedKey) ?? [];
    _visitedIds.addAll(visList);
    notifyListeners();
  }

  bool isFavorite(String pandalId) => _favoriteIds.contains(pandalId);

  bool isVisited(String pandalId) => _visitedIds.contains(pandalId);

  int get favoriteCount => _favoriteIds.length;

  int get visitedCount => _visitedIds.length;

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  Set<String> get visitedIds => Set.unmodifiable(_visitedIds);

  Future<void> toggleFavorite(String pandalId) async {
    if (_favoriteIds.contains(pandalId)) {
      _favoriteIds.remove(pandalId);
    } else {
      _favoriteIds.add(pandalId);
    }
    await _prefs.setStringList(_favoritesKey, _favoriteIds.toList());
    notifyListeners();
  }

  Future<void> toggleVisited(String pandalId) async {
    if (_visitedIds.contains(pandalId)) {
      _visitedIds.remove(pandalId);
    } else {
      _visitedIds.add(pandalId);
    }
    await _prefs.setStringList(_visitedKey, _visitedIds.toList());
    notifyListeners();
  }
}
