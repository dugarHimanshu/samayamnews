// lib/models/advertisement_campaign.dart

import '../data/demo_ads.dart';

/// Pre-configured advertising schedule templates.
enum AdScheduleType {
  /// Displayed for exactly 1 day (e.g. flash sales, 24h event promos).
  oneDay,

  /// 3 days standard run + 1 bonus day = 4 days total run.
  threePlusOne,

  /// Custom number of days or custom start and end date range.
  custom,
}

/// An individual slide/page within a 4-page auto-sliding advertisement.
class AdSlide {
  final int pageIndex; // 1, 2, 3, or 4
  final String tag;
  final String headline;
  final String description;
  final String imageUrl;
  final String? highlightBadge;

  const AdSlide({
    required this.pageIndex,
    required this.tag,
    required this.headline,
    required this.description,
    required this.imageUrl,
    this.highlightBadge,
  });

  Map<String, dynamic> toMap() {
    return {
      'page_index': pageIndex,
      'tag': tag,
      'headline': headline,
      'description': description,
      'image_url': imageUrl,
      'highlight_badge': highlightBadge,
    };
  }

  factory AdSlide.fromMap(Map<String, dynamic> map) {
    return AdSlide(
      pageIndex: (map['page_index'] as num?)?.toInt() ?? 1,
      tag: map['tag']?.toString() ?? 'SPONSORED',
      headline: map['headline']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      highlightBadge: map['highlight_badge']?.toString(),
    );
  }
}

/// Represents an advertisement campaign with advance scheduling (1-day, 3+1 schedule),
/// and a multi-page (4 slides) auto-sliding presentation.
class AdvertisementCampaign {
  final String id;
  final String sponsor;
  final String category;
  final AdScheduleType scheduleType;
  final DateTime startDate;
  final DateTime endDate;
  final List<AdSlide> slides; // 4 slides
  final String ctaText;
  final String ctaUrl;
  final bool isEnabled;
  final DateTime createdAt;
  // Where the ad is shown: 'all' (both Telugu states), 'state' or 'district'.
  final String targetScope;
  final int? targetStateId;
  final int? targetDistrictId;
  final String targetLabel; // e.g. "Telangana", "Karimnagar district"

  bool get isServerSaved => RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-').hasMatch(id);

  const AdvertisementCampaign({
    required this.id,
    required this.sponsor,
    required this.category,
    required this.scheduleType,
    required this.startDate,
    required this.endDate,
    required this.slides,
    required this.ctaText,
    required this.ctaUrl,
    this.isEnabled = true,
    required this.createdAt,
    this.targetScope = 'all',
    this.targetStateId,
    this.targetDistrictId,
    this.targetLabel = 'Telangana + Andhra Pradesh',
  });

  AdvertisementCampaign copyWith({bool? isEnabled, String? id}) => AdvertisementCampaign(
        id: id ?? this.id,
        sponsor: sponsor,
        category: category,
        scheduleType: scheduleType,
        startDate: startDate,
        endDate: endDate,
        slides: slides,
        ctaText: ctaText,
        ctaUrl: ctaUrl,
        isEnabled: isEnabled ?? this.isEnabled,
        createdAt: createdAt,
        targetScope: targetScope,
        targetStateId: targetStateId,
        targetDistrictId: targetDistrictId,
        targetLabel: targetLabel,
      );

  /// Body for POST/PATCH /v1/admin/ads (start of the first day → end of the last day).
  Map<String, dynamic> toApi() {
    final first = slides.isNotEmpty ? slides.first : null;
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    String? url(String u) => Uri.tryParse(u)?.hasScheme == true ? u : null;
    return {
      'sponsor': sponsor,
      'headline': (first?.headline.trim().isNotEmpty ?? false) ? first!.headline.trim() : sponsor,
      'description': first?.description,
      'tag': first?.tag,
      'ctaText': ctaText.isEmpty ? null : ctaText,
      'ctaUrl': url(ctaUrl),
      'imageUrl': url(first?.imageUrl ?? ''),
      'startsAt': start.toUtc().toIso8601String(),
      'endsAt': end.toUtc().toIso8601String(),
      'isActive': isEnabled,
      'slides': [
        for (final s in slides)
          {
            'pageIndex': s.pageIndex,
            'tag': s.tag,
            'headline': s.headline,
            'description': s.description,
            'imageUrl': s.imageUrl,
            'highlightBadge': s.highlightBadge,
          }
      ],
      'scheduleType': scheduleType.name,
      'category': category,
      'targetScope': targetScope,
      'targetStateId': targetStateId,
      'targetDistrictId': targetDistrictId,
    };
  }

  /// From an ad served by the API (feed item or admin list row).
  factory AdvertisementCampaign.fromApi(Map<String, dynamic> j, {String Function(int? stateId, int? districtId, String scope)? labelFor}) {
    final rawSlides = (j['slides'] as List?) ?? const [];
    final slides = <AdSlide>[
      for (final r in rawSlides)
        AdSlide(
          pageIndex: ((r as Map)['pageIndex'] as num?)?.toInt() ?? 1,
          tag: (r['tag'] ?? '').toString(),
          headline: (r['headline'] ?? '').toString(),
          description: (r['description'] ?? '').toString(),
          imageUrl: (r['imageUrl'] ?? '').toString(),
          highlightBadge: r['highlightBadge']?.toString(),
        ),
    ];
    if (slides.isEmpty) {
      slides.add(AdSlide(
        pageIndex: 1,
        tag: (j['tag'] ?? 'SPONSORED').toString(),
        headline: (j['headline'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        imageUrl: (j['imageUrl'] ?? '').toString(),
      ));
    }
    final type = switch (j['scheduleType']?.toString()) {
      'oneDay' => AdScheduleType.oneDay,
      'threePlusOne' => AdScheduleType.threePlusOne,
      _ => AdScheduleType.custom,
    };
    final start = DateTime.tryParse((j['startsAt'] ?? '').toString())?.toLocal() ?? DateTime.now().subtract(const Duration(days: 1));
    final end = DateTime.tryParse((j['endsAt'] ?? '').toString())?.toLocal() ?? DateTime.now().add(const Duration(days: 365));
    final scope = (j['targetScope'] ?? 'all').toString();
    final stateId = (j['targetStateId'] as num?)?.toInt();
    final districtId = (j['targetDistrictId'] as num?)?.toInt();
    return AdvertisementCampaign(
      id: (j['id'] ?? '').toString(),
      sponsor: (j['sponsor'] ?? 'Sponsor').toString(),
      category: (j['category'] ?? 'General').toString(),
      scheduleType: type,
      startDate: start,
      endDate: end,
      slides: slides,
      ctaText: (j['ctaText'] ?? 'Learn More').toString(),
      ctaUrl: (j['ctaUrl'] ?? '').toString(),
      isEnabled: j['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
      targetScope: scope,
      targetStateId: stateId,
      targetDistrictId: districtId,
      targetLabel: labelFor?.call(stateId, districtId, scope) ?? (scope == 'all' ? 'Telangana + Andhra Pradesh' : scope),
    );
  }

  /// Total duration in days.
  int get totalDays {
    switch (scheduleType) {
      case AdScheduleType.oneDay:
        return 1;
      case AdScheduleType.threePlusOne:
        return 4; // 3 days + 1 bonus day
      case AdScheduleType.custom:
        final diff = endDate.difference(startDate).inDays;
        return diff <= 0 ? 1 : diff + 1;
    }
  }

  /// Human-readable schedule label.
  String get scheduleLabel {
    switch (scheduleType) {
      case AdScheduleType.oneDay:
        return '1-Day Campaign';
      case AdScheduleType.threePlusOne:
        return '3+1 Schedule (4 Days)';
      case AdScheduleType.custom:
        return 'Custom ($totalDays Days)';
    }
  }

  /// Whether the campaign is currently running right now based on current date.
  bool get isCurrentlyActive {
    if (!isEnabled) return false;
    final now = DateTime.now();
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return now.isAfter(start) && now.isBefore(end);
  }

  /// Whether this campaign is planned in advance for a future date.
  bool get isUpcoming {
    final now = DateTime.now();
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    return now.isBefore(start);
  }

  /// Whether the campaign has completed its scheduled run.
  bool get isExpired {
    final now = DateTime.now();
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return now.isAfter(end);
  }

  /// Days remaining in the active schedule.
  int get remainingDays {
    final now = DateTime.now();
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    if (now.isAfter(end)) return 0;
    return end.difference(now).inDays + 1;
  }

  /// Converts this campaign to a backward-compatible [AdvertisementItem] for the feed.
  AdvertisementItem toAdvertisementItem() {
    final firstSlide = slides.isNotEmpty ? slides.first : null;
    return AdvertisementItem(
      id: id,
      sponsor: sponsor,
      headline: firstSlide?.headline ?? sponsor,
      tag: scheduleType == AdScheduleType.threePlusOne
          ? 'SPONSORED (3+1 SPECIAL)'
          : (firstSlide?.tag ?? 'SPONSORED'),
      description: firstSlide?.description ?? '',
      ctaText: ctaText,
      imageUrl: firstSlide?.imageUrl ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sponsor': sponsor,
      'category': category,
      'schedule_type': scheduleType.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'slides': slides.map((s) => s.toMap()).toList(),
      'cta_text': ctaText,
      'cta_url': ctaUrl,
      'is_enabled': isEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AdvertisementCampaign.fromMap(Map<String, dynamic> map) {
    AdScheduleType type;
    final typeStr = map['schedule_type']?.toString();
    if (typeStr == 'oneDay') {
      type = AdScheduleType.oneDay;
    } else if (typeStr == 'threePlusOne') {
      type = AdScheduleType.threePlusOne;
    } else {
      type = AdScheduleType.custom;
    }

    final rawSlides = (map['slides'] as List<dynamic>?) ?? [];
    final parsedSlides = rawSlides
        .map((s) => AdSlide.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList();

    return AdvertisementCampaign(
      id: map['id']?.toString() ?? '',
      sponsor: map['sponsor']?.toString() ?? 'Sponsor',
      category: map['category']?.toString() ?? 'General',
      scheduleType: type,
      startDate: map['start_date'] != null
          ? DateTime.tryParse(map['start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: map['end_date'] != null
          ? DateTime.tryParse(map['end_date'].toString()) ??
              DateTime.now().add(const Duration(days: 3))
          : DateTime.now().add(const Duration(days: 3)),
      slides: parsedSlides,
      ctaText: map['cta_text']?.toString() ?? 'Learn More',
      ctaUrl: map['cta_url']?.toString() ?? '',
      isEnabled: map['is_enabled'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
