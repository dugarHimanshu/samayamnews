import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedNewsStore extends ChangeNotifier {
  SavedNewsStore._();

  static final SavedNewsStore instance = SavedNewsStore._();

  static const String _storageKey = 'saved_news_titles';

  final Set<String> _savedTitles = {};

  bool _loaded = false;

  bool get loaded => _loaded;

  Set<String> get savedTitles => Set.unmodifiable(_savedTitles);

  bool isSaved(String title) {
    return _savedTitles.contains(title);
  }

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList(_storageKey) ?? [];

    _savedTitles
      ..clear()
      ..addAll(saved);

    _loaded = true;

    notifyListeners();
  }

  Future<void> toggle(String title) async {
    if (_savedTitles.contains(title)) {
      _savedTitles.remove(title);
    } else {
      _savedTitles.add(title);
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_storageKey, _savedTitles.toList());
  }

  Future<void> remove(String title) async {
    _savedTitles.remove(title);

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_storageKey, _savedTitles.toList());
  }

  Future<void> clear() async {
    _savedTitles.clear();

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_storageKey);
  }
}