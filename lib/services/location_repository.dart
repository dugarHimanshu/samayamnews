import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// One LGD-coded place (state, district, mandal or village).
class Place {
  final int id;
  final String level;
  final int? parentId;
  final String nameEn;
  final String? nameTe;

  const Place({required this.id, required this.level, this.parentId, required this.nameEn, this.nameTe});

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as int,
        level: j['level'].toString(),
        parentId: j['parentId'] as int?,
        nameEn: j['nameEn'].toString(),
        nameTe: j['nameTe']?.toString(),
      );

  /// Telugu name when the app language is Telugu and we have one.
  String display(String language) =>
      (language.toLowerCase().startsWith('te') && (nameTe?.isNotEmpty ?? false)) ? nameTe! : nameEn;
}

/// Official LGD location hierarchy served by the API (/v1/locations).
/// States + districts load at startup; mandals and villages load on demand and
/// notify listeners when they arrive.
class LocationRepository extends ChangeNotifier {
  LocationRepository._();
  static final LocationRepository instance = LocationRepository._();

  final Map<int, Place> _byId = {};
  final Map<int, List<Place>> _children = {}; // parentId → children (sorted by name)
  final List<Place> _states = [];
  final Set<int> _loading = {};
  bool _ready = false;

  bool get isReady => _ready;
  List<Place> get states => List.unmodifiable(_states);

  Future<void> init() async {
    if (_ready) return;
    final res = await ApiClient.instance.get('/locations');
    _states
      ..clear()
      ..addAll(_parse(res));
    for (final s in _states) {
      _byId[s.id] = s;
      await _loadChildren(s.id, notify: false);
    }
    _ready = true;
    notifyListeners();
  }

  List<Place> _parse(dynamic res) =>
      ((res as Map)['items'] as List).map((e) => Place.fromJson(Map<String, dynamic>.from(e as Map))).toList();

  Future<void> _loadChildren(int parentId, {bool notify = true}) async {
    if (_children.containsKey(parentId) || _loading.contains(parentId)) return;
    _loading.add(parentId);
    try {
      final items = _parse(await ApiClient.instance.get('/locations', query: {'parent': parentId}));
      for (final p in items) {
        _byId[p.id] = p;
      }
      _children[parentId] = items;
      if (notify) notifyListeners();
    } catch (e) {
      debugPrint('Location load failed for $parentId: $e');
    } finally {
      _loading.remove(parentId);
    }
  }

  /// Children if cached; otherwise starts loading them and returns an empty list for now.
  List<Place> childrenOf(int? parentId) {
    if (parentId == null) return const [];
    final cached = _children[parentId];
    if (cached != null) return cached;
    _loadChildren(parentId);
    return const [];
  }

  Future<List<Place>> loadChildren(int parentId) async {
    await _loadChildren(parentId);
    return _children[parentId] ?? const [];
  }

  Place? byId(int? id) => id == null ? null : _byId[id];

  Place? _findByName(List<Place> list, String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final n = _norm(name);
    for (final p in list) {
      if (_norm(p.nameEn) == n || (p.nameTe != null && p.nameTe == name.trim())) return p;
    }
    return null;
  }

  String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ఀ-౿]'), '');

  Place? state(String? name) => _findByName(_states, name);
  Place? district(String? stateName, String? districtName) =>
      _findByName(childrenOf(state(stateName)?.id), districtName);
  Place? mandal(String? stateName, String? districtName, String? mandalName) =>
      _findByName(childrenOf(district(stateName, districtName)?.id), mandalName);
  Place? village(String? stateName, String? districtName, String? mandalName, String? villageName) =>
      _findByName(childrenOf(mandal(stateName, districtName, mandalName)?.id), villageName);

  /// Finds a district anywhere (used when only a district name is known).
  Place? districtAnywhere(String? districtName) {
    for (final s in _states) {
      final d = _findByName(childrenOf(s.id), districtName);
      if (d != null) return d;
    }
    return null;
  }
}
