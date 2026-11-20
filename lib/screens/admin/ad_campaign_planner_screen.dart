// lib/screens/admin/ad_campaign_planner_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/advertisement_campaign.dart';
import '../../services/ad_campaign_service.dart';
import '../../widgets/home/auto_sliding_ad_card.dart';

/// Screen allowing Admins and Editors to plan advertising campaigns in advance
/// (1-day campaigns, 3+1 schedules = 4 days total, or custom durations)
/// and manage 4-page auto-sliding advertisements.
class AdCampaignPlannerScreen extends StatefulWidget {
  const AdCampaignPlannerScreen({super.key});

  @override
  State<AdCampaignPlannerScreen> createState() => _AdCampaignPlannerScreenState();
}

class _AdCampaignPlannerScreenState extends State<AdCampaignPlannerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AdCampaignService _adService = AdCampaignService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _adService.load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openPreview(AdvertisementCampaign campaign) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            AutoSlidingAdCard(campaign: campaign),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateCampaignDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateCampaignSheet(
        onSaved: (newCampaign) async {
          await _adService.saveCampaign(newCampaign);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Advertisement planned: ${newCampaign.sponsor} (${newCampaign.scheduleLabel})',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.black87,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _adService,
      builder: (context, _) {
        final active = _adService.activeCampaigns;
        final upcoming = _adService.upcomingCampaigns;
        final past = _adService.pastCampaigns;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F7F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    size: 20,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ad Campaign Planner',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '1-Day & 3+1 (4 Days) Multi-Page Ads',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black45,
              indicatorColor: Colors.black,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Active (${active.length})'),
                Tab(text: 'Upcoming (${upcoming.length})'),
                Tab(text: 'Completed (${past.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCampaignList(active, isLive: true),
              _buildCampaignList(upcoming, isUpcoming: true),
              _buildCampaignList(past, isPast: true),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreateCampaignDialog,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Plan New Ad',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCampaignList(
    List<AdvertisementCampaign> campaigns, {
    bool isLive = false,
    bool isUpcoming = false,
    bool isPast = false,
  }) {
    if (campaigns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  size: 30,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isLive
                    ? 'No Active Campaigns Today'
                    : isUpcoming
                        ? 'No Upcoming Campaigns Planned'
                        : 'No Past Campaigns',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isLive
                    ? 'Plan an advertisement in advance for 1-day or 3+1 schedule.'
                    : 'Scheduled campaigns will automatically appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        final campaign = campaigns[index];
        return _CampaignCard(
          campaign: campaign,
          onPreview: () => _openPreview(campaign),
          onDelete: () => _adService.deleteCampaign(campaign.id),
          onToggle: () => _adService.toggleEnabled(campaign.id),
        );
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final AdvertisementCampaign campaign;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _CampaignCard({
    required this.campaign,
    required this.onPreview,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color badgeTextColor;
    String scheduleBadge;

    if (campaign.scheduleType == AdScheduleType.oneDay) {
      badgeColor = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFB45309);
      scheduleBadge = '1 DAY CAMPAIGN';
    } else if (campaign.scheduleType == AdScheduleType.threePlusOne) {
      badgeColor = const Color(0xFFDBEAFE);
      badgeTextColor = const Color(0xFF1D4ED8);
      scheduleBadge = '3+1 SCHEDULE (4 DAYS)';
    } else {
      badgeColor = const Color(0xFFE0E7FF);
      badgeTextColor = const Color(0xFF4338CA);
      scheduleBadge = 'CUSTOM (${campaign.totalDays} DAYS)';
    }

    final startDateStr =
        '${campaign.startDate.day}/${campaign.startDate.month}/${campaign.startDate.year}';
    final endDateStr =
        '${campaign.endDate.day}/${campaign.endDate.month}/${campaign.endDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: campaign.isCurrentlyActive
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.06),
          width: campaign.isCurrentlyActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category + Schedule Badge + Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    scheduleBadge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: badgeTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  campaign.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.black45,
                  ),
                ),
                const Spacer(),
                if (campaign.isCurrentlyActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'LIVE ON FEED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (campaign.isUpcoming)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'SCHEDULED IN ADVANCE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  )
                else
                  const Text(
                    'COMPLETED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.black38,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Sponsor & Headline
            Text(
              campaign.sponsor,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              campaign.slides.isNotEmpty ? campaign.slides.first.headline : '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.35,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 12),

            // Schedule Dates & Slide Count
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded, size: 14, color: Colors.black45),
                  const SizedBox(width: 6),
                  Text(
                    '$startDateStr  →  $endDateStr',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${campaign.slides.length} Auto-Slides',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                  label: const Text('Preview 4 Slides', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  tooltip: 'Delete Campaign',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet for creating and scheduling advertisements in advance.
class _CreateCampaignSheet extends StatefulWidget {
  final ValueChanged<AdvertisementCampaign> onSaved;

  const _CreateCampaignSheet({required this.onSaved});

  @override
  State<_CreateCampaignSheet> createState() => _CreateCampaignSheetState();
}

class _CreateCampaignSheetState extends State<_CreateCampaignSheet> {
  final _sponsorController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Commercial');
  final _ctaTextController = TextEditingController(text: 'Learn More');
  final _ctaUrlController = TextEditingController();

  AdScheduleType _scheduleType = AdScheduleType.threePlusOne; // 3+1 by default
  DateTime _startDate = DateTime.now();
  int _customDays = 7;

  // 4 Slides
  late final List<TextEditingController> _headlineControllers;
  late final List<TextEditingController> _descControllers;
  late final List<TextEditingController> _imageControllers;

  @override
  void initState() {
    super.initState();
    _headlineControllers = List.generate(
      4,
      (i) => TextEditingController(
        text: i == 0
            ? 'Exclusive Premium Showcase & Launch Announcement'
            : i == 1
                ? 'Unmatched Quality, Reliability & Modern Engineering'
                : i == 2
                    ? 'Verified Customer Excellence & Regional Support'
                    : 'Special Limited-Time 3+1 Schedule Benefit',
      ),
    );
    _descControllers = List.generate(
      4,
      (i) => TextEditingController(
        text: i == 0
            ? 'Discover our next-generation solutions crafted for your daily lifestyle.'
            : i == 1
                ? 'Experience superior performance and peace of mind with 24/7 assistance.'
                : i == 2
                    ? 'Join thousands of satisfied clients experiencing the difference today.'
                    : 'Reserve your priority booking slot now to unlock introductory privileges.',
      ),
    );
    _imageControllers = [
      TextEditingController(
        text: 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?auto=format&fit=crop&w=900&q=80',
      ),
      TextEditingController(
        text: 'https://images.unsplash.com/photo-1558441719-573255e1b6cb?auto=format&fit=crop&w=900&q=80',
      ),
      TextEditingController(
        text: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=900&q=80',
      ),
      TextEditingController(
        text: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=900&q=80',
      ),
    ];
  }

  @override
  void dispose() {
    _sponsorController.dispose();
    _categoryController.dispose();
    _ctaTextController.dispose();
    _ctaUrlController.dispose();
    for (final c in _headlineControllers) {
      c.dispose();
    }
    for (final c in _descControllers) {
      c.dispose();
    }
    for (final c in _imageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime get _calculatedEndDate {
    switch (_scheduleType) {
      case AdScheduleType.oneDay:
        return _startDate; // 1 day
      case AdScheduleType.threePlusOne:
        return _startDate.add(const Duration(days: 3)); // 4 days total
      case AdScheduleType.custom:
        return _startDate.add(Duration(days: _customDays - 1));
    }
  }

  void _save() {
    final sponsor = _sponsorController.text.trim();
    if (sponsor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a sponsor name')),
      );
      return;
    }

    final slides = List.generate(4, (i) {
      return AdSlide(
        pageIndex: i + 1,
        tag: i == 3 && _scheduleType == AdScheduleType.threePlusOne
            ? '3+1 SPECIAL OFFER'
            : 'PAGE ${i + 1} OF 4',
        headline: _headlineControllers[i].text.trim(),
        description: _descControllers[i].text.trim(),
        imageUrl: _imageControllers[i].text.trim(),
        highlightBadge: 'SLIDE ${i + 1} / 4',
      );
    });

    final campaign = AdvertisementCampaign(
      id: 'camp_${DateTime.now().millisecondsSinceEpoch}',
      sponsor: sponsor,
      category: _categoryController.text.trim(),
      scheduleType: _scheduleType,
      startDate: _startDate,
      endDate: _calculatedEndDate,
      slides: slides,
      ctaText: _ctaTextController.text.trim().isNotEmpty
          ? _ctaTextController.text.trim()
          : 'Learn More',
      ctaUrl: _ctaUrlController.text.trim(),
      createdAt: DateTime.now(),
    );

    widget.onSaved(campaign);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Plan Advertisement Campaign',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                children: [
                  // SECTION 1: SCHEDULE PLAN
                  const Text(
                    'CAMPAIGN SCHEDULE TEMPLATE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _scheduleOption(
                          label: '1 Day',
                          subtitle: 'Daily Blast',
                          selected: _scheduleType == AdScheduleType.oneDay,
                          onTap: () => setState(() => _scheduleType = AdScheduleType.oneDay),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _scheduleOption(
                          label: '3+1 Schedule',
                          subtitle: '4 Days Total',
                          selected: _scheduleType == AdScheduleType.threePlusOne,
                          onTap: () => setState(() => _scheduleType = AdScheduleType.threePlusOne),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _scheduleOption(
                          label: 'Custom',
                          subtitle: 'Any Days',
                          selected: _scheduleType == AdScheduleType.custom,
                          onTap: () => setState(() => _scheduleType = AdScheduleType.custom),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Start Date Picker & Auto-calculated End Date
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CAMPAIGN START DATE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black45),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                                  lastDate: DateTime.now().add(const Duration(days: 180)),
                                );
                                if (picked != null) {
                                  setState(() => _startDate = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_today_rounded, size: 14),
                              label: const Text('Change Date', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF1565C0)),
                            const SizedBox(width: 6),
                            Text(
                              'Runs until: ${_calculatedEndDate.day}/${_calculatedEndDate.month}/${_calculatedEndDate.year} (${_scheduleType == AdScheduleType.oneDay ? '1 Day' : (_scheduleType == AdScheduleType.threePlusOne ? '4 Days Total (3+1)' : '$_customDays Days')})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECTION 2: SPONSOR & CATEGORY
                  const Text(
                    'SPONSOR & BRAND DETAILS',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _inputField('Sponsor / Brand Name *', _sponsorController, hint: 'e.g. Aura Mobility'),
                  Row(
                    children: [
                      Expanded(child: _inputField('Category', _categoryController, hint: 'Automotive')),
                      const SizedBox(width: 10),
                      Expanded(child: _inputField('CTA Button Text', _ctaTextController, hint: 'Book Test Drive')),
                    ],
                  ),
                  _inputField('Destination URL / Website', _ctaUrlController, hint: 'https://example.com'),

                  const SizedBox(height: 20),

                  // SECTION 3: 4 AUTO-SLIDING PAGES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '4 AUTO-SLIDING PAGES CONTENT',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Colors.black45,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '4 PAGES SLIDER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...List.generate(4, (i) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                i == 0
                                    ? 'Slide 1: Announcement & Hero'
                                    : i == 1
                                        ? 'Slide 2: Key Features & Specs'
                                        : i == 2
                                            ? 'Slide 3: Benefits & Social Proof'
                                            : 'Slide 4: Offer & Direct CTA',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _inputField('Slide ${i + 1} Headline', _headlineControllers[i]),
                          _inputField('Slide ${i + 1} Description', _descControllers[i], maxLines: 2),
                          _inputField('Slide ${i + 1} Image URL', _imageControllers[i]),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text(
                        'Save & Schedule Campaign',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleOption({
    required String label,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1565C0) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
