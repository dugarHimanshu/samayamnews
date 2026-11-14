/// An in-house ad served inside the feed by the API.
class AdvertisementItem {
  final String id;
  final String sponsor;
  final String headline;
  final String tag;
  final String description;
  final String ctaText;
  final String ctaUrl;
  final String imageUrl;

  const AdvertisementItem({
    required this.id,
    required this.sponsor,
    required this.headline,
    required this.tag,
    required this.description,
    required this.ctaText,
    required this.imageUrl,
    this.ctaUrl = '',
  });

  factory AdvertisementItem.fromApi(Map<String, dynamic> j) => AdvertisementItem(
        id: (j['id'] ?? '').toString(),
        sponsor: (j['sponsor'] ?? '').toString(),
        headline: (j['headline'] ?? '').toString(),
        tag: (j['tag'] ?? 'SPONSORED').toString(),
        description: (j['description'] ?? '').toString(),
        ctaText: (j['ctaText'] ?? 'Learn more').toString(),
        ctaUrl: (j['ctaUrl'] ?? '').toString(),
        imageUrl: (j['imageUrl'] ?? '').toString(),
      );
}
