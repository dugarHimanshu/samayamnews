// lib/services/ad_campaign_service.dart

import 'package:flutter/foundation.dart';

import '../models/advertisement_campaign.dart';
import 'api_client.dart';
import 'location_repository.dart';

/// Central service for planning and managing advertisement campaigns
/// in advance (1-day, 3+1 days, custom schedules) and serving 4-page sliding ads.
class AdCampaignService extends ChangeNotifier {
  AdCampaignService._();
  static final AdCampaignService instance = AdCampaignService._();


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

  bool loading = false;
  String? error;

  /// Label for where an ad runs, from LGD ids.
  static String targetLabel(int? stateId, int? districtId, String scope) {
    final loc = LocationRepository.instance;
    if (scope == 'district') return '${loc.byId(districtId)?.nameEn ?? 'District'} district';
    if (scope == 'state') return loc.byId(stateId)?.nameEn ?? 'State';
    return 'Telangana + Andhra Pradesh';
  }

  /// Loads every campaign from the server (admin only). Campaigns are stored on the
  /// server, so they reach every reader's phone and respect the chosen area.
  Future<void> load({bool force = false}) async {
    if (_initialized && !force) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await LocationRepository.instance.init().catchError((_) {});
      final res = await ApiClient.instance.get('/admin/ads') as Map;
      _campaignsById
        ..clear()
        ..addEntries([
          for (final raw in res['items'] as List)
            () {
              final c = AdvertisementCampaign.fromApi(Map<String, dynamic>.from(raw as Map), labelFor: targetLabel);
              return MapEntry(c.id, c);
            }(),
        ]);
      _initialized = true;
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Could not load campaigns.';
      debugPrint('AdCampaignService load error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Creates or updates a campaign on the server.
  Future<void> saveCampaign(AdvertisementCampaign campaign) async {
    final body = campaign.toApi();
    final res = campaign.isServerSaved
        ? await ApiClient.instance.patch('/admin/ads/${campaign.id}', body)
        : await ApiClient.instance.post('/admin/ads', body);
    final saved = AdvertisementCampaign.fromApi(Map<String, dynamic>.from(res as Map), labelFor: targetLabel);
    _campaignsById.remove(campaign.id);
    _campaignsById[saved.id] = saved;
    notifyListeners();
  }

  /// Deletes a campaign.
  Future<void> deleteCampaign(String campaignId) async {
    if (RegExp(r'^[0-9a-f]{8}-').hasMatch(campaignId)) await ApiClient.instance.delete('/admin/ads/$campaignId');
    _campaignsById.remove(campaignId);
    notifyListeners();
  }

  /// Pauses / resumes a campaign.
  Future<void> toggleEnabled(String campaignId) async {
    final camp = _campaignsById[campaignId];
    if (camp == null) return;
    await ApiClient.instance.patch('/admin/ads/$campaignId', {'isActive': !camp.isEnabled});
    _campaignsById[campaignId] = camp.copyWith(isEnabled: !camp.isEnabled);
    notifyListeners();
  }
}
