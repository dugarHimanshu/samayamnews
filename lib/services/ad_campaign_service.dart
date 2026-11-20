// lib/services/ad_campaign_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/advertisement_campaign.dart';

/// Central service for planning and managing advertisement campaigns
/// in advance (1-day, 3+1 days, custom schedules) and serving 4-page sliding ads.
class AdCampaignService extends ChangeNotifier {
  AdCampaignService._();
  static final AdCampaignService instance = AdCampaignService._();

  static const String _kStorageKey = 'samayam_ad_campaigns_v1';
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, AdvertisementCampaign> _campaignsById = {};
  bool _initialized = false;

  Map<String, AdvertisementCampaign> get allCampaigns =>
      Map.unmodifiable(_campaignsById);

  /// Campaigns that are currently active right now.
  List<AdvertisementCampaign> get activeCampaigns {
    final list = _campaignsById.values
        .where((c) => c.isCurrentlyActive)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  /// Campaigns planned in advance for future dates.
  List<AdvertisementCampaign> get upcomingCampaigns {
    final list = _campaignsById.values
        .where((c) => c.isUpcoming && c.isEnabled)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return list;
  }

  /// Campaigns that have finished their run.
  List<AdvertisementCampaign> get pastCampaigns {
    final list = _campaignsById.values
        .where((c) => c.isExpired || !c.isEnabled)
        .toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));
    return list;
  }

  /// Loads campaigns from storage and seeds default demo schedules if empty.
  Future<void> load() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStorageKey);

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          final campaign = AdvertisementCampaign.fromMap(
            Map<String, dynamic>.from(item as Map),
          );
          _campaignsById[campaign.id] = campaign;
        }
      }

      // If empty, seed default realistic 4-page sliding ads
      if (_campaignsById.isEmpty) {
        _seedDefaultCampaigns();
        await _saveToLocal();
      }

      // Try background sync with Supabase table if it exists
      try {
        final response = await _supabase.from('advertisement_campaigns').select();
        final rows = List<Map<String, dynamic>>.from(response as List);
        for (final row in rows) {
          final campaign = AdvertisementCampaign.fromMap(row);
          _campaignsById[campaign.id] = campaign;
        }
        await _saveToLocal();
      } catch (_) {
        // Table optional; local prefs guarantee zero downtime
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('AdCampaignService load error: $e');
    }
  }

  void _seedDefaultCampaigns() {
    final now = DateTime.now();

    // 1. AURA MOBILITY EV (3+1 Schedule = 4 Days total) — Active today
    final auraCampaign = AdvertisementCampaign(
      id: 'camp_aura_ev_3plus1',
      sponsor: 'AURA MOBILITY',
      category: 'Automotive',
      scheduleType: AdScheduleType.threePlusOne, // 3 + 1 = 4 days
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 2)), // 4 days total
      ctaText: 'Book Test Drive',
      ctaUrl: 'https://auramobility.example.com',
      createdAt: now.subtract(const Duration(days: 2)),
      slides: const [
        AdSlide(
          pageIndex: 1,
          tag: '3+1 SPECIAL FEATURE',
          headline: 'Next-Gen Electric Vehicles Engineered for Indian Roads.',
          description:
              'Introducing the Aura Apex with 650km verified highway range and ultra-fast hypercharging.',
          imageUrl:
              'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 1 OF 4 • OVERVIEW',
        ),
        AdSlide(
          pageIndex: 2,
          tag: 'BATTERY & CHARGING',
          headline: 'Zero to 80% Charge in Just 18 Minutes at Any Fast Station.',
          description:
              'Liquid-cooled dual motor system with active thermal protection designed specifically for Indian summers.',
          imageUrl:
              'https://images.unsplash.com/photo-1558441719-573255e1b6cb?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 2 OF 4 • PERFORMANCE',
        ),
        AdSlide(
          pageIndex: 3,
          tag: 'CONNECTED COCKPIT',
          headline: 'Autonomous Safety Suite with 360° LIDAR & AI Navigation.',
          description:
              'Over-the-air updates, voice navigation in regional languages, and luxury acoustic interior.',
          imageUrl:
              'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 3 OF 4 • INTERIOR & TECH',
        ),
        AdSlide(
          pageIndex: 4,
          tag: 'LIMITED 3+1 OFFER',
          headline: 'Complimentary Home Fast Charger & 5-Year Free Maintenance.',
          description:
              'Reserve your VIP priority slot today with ₹5,000 refundable booking. Special corporate subsidies available.',
          imageUrl:
              'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 4 OF 4 • EXCLUSIVE REWARD',
        ),
      ],
    );

    // 2. ZENITH WEALTH (1-Day Campaign) — Active today
    final zenithCampaign = AdvertisementCampaign(
      id: 'camp_zenith_1day',
      sponsor: 'ZENITH WEALTH ADVISORY',
      category: 'Finance',
      scheduleType: AdScheduleType.oneDay, // 1 Day Flash
      startDate: now,
      endDate: now, // 1 day
      ctaText: 'Get Free Portfolio Review',
      ctaUrl: 'https://zenithwealth.example.com',
      createdAt: now.subtract(const Duration(hours: 6)),
      slides: const [
        AdSlide(
          pageIndex: 1,
          tag: '1-DAY FLASH PROMO',
          headline: 'Institutional-Grade Wealth Management for High-Growth Professionals.',
          description:
              'Automated algorithmic asset allocation and tax-loss harvesting with zero broker commissions.',
          imageUrl:
              'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 1 OF 4 • FLASH OFFER',
        ),
        AdSlide(
          pageIndex: 2,
          tag: 'PROVEN PERFORMANCE',
          headline: '18.4% Average Annualized Returns Over the Last 5 Years.',
          description:
              'Backed by quantitative models and SEBI-registered portfolio managers managing over ₹1,200 crore.',
          imageUrl:
              'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 2 OF 4 • VERIFIED TRACK RECORD',
        ),
        AdSlide(
          pageIndex: 3,
          tag: 'ZERO PAPERWORK',
          headline: 'Setup Your High-Yield Demat & Mutual Fund Account in 3 Minutes.',
          description:
              'Seamless instant KYC using Aadhaar and DigiLocker. Track real-time dividends directly on your phone.',
          imageUrl:
              'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 3 OF 4 • SEAMLESS ONBOARDING',
        ),
        AdSlide(
          pageIndex: 4,
          tag: 'TODAY ONLY BONUS',
          headline: 'Complimentary 1-on-1 Session with a Senior Financial Advisor.',
          description:
              'Offer valid for registrations completed today before midnight. No management fees for the first quarter.',
          imageUrl:
              'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 4 OF 4 • FINAL CALL',
        ),
      ],
    );

    // 3. ORION RESORTS (Upcoming — Planned in Advance for Next Week)
    final orionCampaign = AdvertisementCampaign(
      id: 'camp_orion_upcoming_3plus1',
      sponsor: 'ORION LUXURY RETREATS',
      category: 'Travel & Lifestyle',
      scheduleType: AdScheduleType.threePlusOne, // 3+1 = 4 Days
      startDate: now.add(const Duration(days: 3)),
      endDate: now.add(const Duration(days: 6)),
      ctaText: 'Pre-Book Getaway',
      ctaUrl: 'https://orionretreats.example.com',
      createdAt: now,
      slides: const [
        AdSlide(
          pageIndex: 1,
          tag: 'UPCOMING • 3+1 RETREAT',
          headline: 'Private Pool Villas Nested in Pristine Hill Stations.',
          description:
              'Escape the hustle with personalized butler service, organic dining, and private cliff-view infinity pools.',
          imageUrl:
              'https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 1 OF 4 • ESCAPE',
        ),
        AdSlide(
          pageIndex: 2,
          tag: 'CULINARY DELIGHT',
          headline: 'Farm-to-Table Gastronomy Curated by Michelin-Star Chefs.',
          description:
              'Hand-crafted 7-course tasting menus using local regional spices and fresh mountain produce.',
          imageUrl:
              'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 2 OF 4 • DINING',
        ),
        AdSlide(
          pageIndex: 3,
          tag: 'SPA & WELLNESS',
          headline: 'Ancient Ayurvedic Rejuvenation & Sound Healing Sessions.',
          description:
              'Holistic detox therapies, morning yoga sessions by the lake, and herbal essential oil massage.',
          imageUrl:
              'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 3 OF 4 • WELLNESS',
        ),
        AdSlide(
          pageIndex: 4,
          tag: 'ADVANCE BOOKING PRIVILEGE',
          headline: 'Stay 3 Nights, Get 1 Night Free (3+1 Holiday Guarantee).',
          description:
              'Early bird package includes free airport transfers and complimentary spa credits.',
          imageUrl:
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 4 OF 4 • 3+1 BONUS',
        ),
      ],
    );

    _campaignsById[auraCampaign.id] = auraCampaign;
    _campaignsById[zenithCampaign.id] = zenithCampaign;
    _campaignsById[orionCampaign.id] = orionCampaign;
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _campaignsById.values.map((c) => c.toMap()).toList();
      await prefs.setString(_kStorageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('AdCampaignService save error: $e');
    }
  }

  /// Adds or updates a scheduled campaign.
  Future<void> saveCampaign(AdvertisementCampaign campaign) async {
    _campaignsById[campaign.id] = campaign;
    await _saveToLocal();

    // Try background Supabase upsert
    try {
      await _supabase.from('advertisement_campaigns').upsert(campaign.toMap());
    } catch (_) {}

    notifyListeners();
  }

  /// Deletes a campaign.
  Future<void> deleteCampaign(String campaignId) async {
    _campaignsById.remove(campaignId);
    await _saveToLocal();

    try {
      await _supabase
          .from('advertisement_campaigns')
          .delete()
          .eq('id', campaignId);
    } catch (_) {}

    notifyListeners();
  }

  /// Toggles active status of a campaign.
  Future<void> toggleEnabled(String campaignId) async {
    final camp = _campaignsById[campaignId];
    if (camp == null) return;

    final updated = AdvertisementCampaign(
      id: camp.id,
      sponsor: camp.sponsor,
      category: camp.category,
      scheduleType: camp.scheduleType,
      startDate: camp.startDate,
      endDate: camp.endDate,
      slides: camp.slides,
      ctaText: camp.ctaText,
      ctaUrl: camp.ctaUrl,
      isEnabled: !camp.isEnabled,
      createdAt: camp.createdAt,
    );

    await saveCampaign(updated);
  }
}
