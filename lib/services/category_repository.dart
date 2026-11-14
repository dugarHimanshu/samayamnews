import 'api_client.dart';

class Category {
  final int id;
  final String slug;
  final String nameEn;
  final String nameTe;
  final String nameHi;

  const Category({required this.id, required this.slug, required this.nameEn, required this.nameTe, required this.nameHi});
}

/// News categories from /v1/categories, with lookups by id, slug or English name.
class CategoryRepository {
  CategoryRepository._();
  static final CategoryRepository instance = CategoryRepository._();

  List<Category> _items = const [];
  List<Category> get items => _items;

  // App category keys that differ from the API slugs.
  static const Map<String, String> _aliases = {'world': 'international', 'india': 'national', 'lifestyle': 'health'};

  Future<void> init() async {
    if (_items.isNotEmpty) return;
    final res = await ApiClient.instance.get('/categories') as Map;
    _items = (res['items'] as List)
        .map((e) => Category(
              id: e['id'] as int,
              slug: e['slug'].toString(),
              nameEn: e['nameEn'].toString(),
              nameTe: e['nameTe'].toString(),
              nameHi: e['nameHi'].toString(),
            ))
        .toList();
  }

  Category? byName(String? name) {
    if (name == null) return null;
    final n = name.trim().toLowerCase();
    final slug = _aliases[n] ?? n;
    for (final c in _items) {
      if (c.slug == slug || c.nameEn.toLowerCase() == n) return c;
    }
    return null;
  }

  String slugFor(String key) => byName(key)?.slug ?? (_aliases[key.toLowerCase()] ?? key.toLowerCase());
}
