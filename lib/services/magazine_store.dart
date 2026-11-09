import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MagazineStore extends ChangeNotifier {
  MagazineStore._();

  static final MagazineStore instance = MagazineStore._();

  static const String _savedKey = 'saved_magazine_ids';
  static const String _likedKey = 'liked_magazine_ids';

  final Set<String> _savedIds = {};
  final Set<String> _likedIds = {};
  bool _loaded = false;

  bool get loaded => _loaded;
  Set<String> get savedIds => Set.unmodifiable(_savedIds);
  Set<String> get likedIds => Set.unmodifiable(_likedIds);

  bool isSaved(String id) => _savedIds.contains(id);
  bool isLiked(String id) => _likedIds.contains(id);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _savedIds
      ..clear()
      ..addAll(prefs.getStringList(_savedKey) ?? []);
    _likedIds
      ..clear()
      ..addAll(prefs.getStringList(_likedKey) ?? []);
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleSave(String id) async {
    if (_savedIds.contains(id)) {
      _savedIds.remove(id);
    } else {
      _savedIds.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedKey, _savedIds.toList());
  }

  Future<void> toggleLike(String id) async {
    if (_likedIds.contains(id)) {
      _likedIds.remove(id);
    } else {
      _likedIds.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_likedKey, _likedIds.toList());
  }
}
