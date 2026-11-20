import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/demo_news.dart';
import '../../models/news_article.dart';
import '../../widgets/home/news_card.dart';
import '../../services/location_service.dart';
import '../../services/app_strings.dart';
import '../../utils/display_formatters.dart';
import '../home/news_story_page.dart';

class LocationScreen extends StatefulWidget {
  final String selectedLanguage;
  final String selectedState;
  final String selectedDistrict;

  const LocationScreen({
    super.key,
    required this.selectedLanguage,
    required this.selectedState,
    required this.selectedDistrict,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _position;
  String? _errorMessage;
  bool _isLoading = true;

  late final MapController _mapController;

  List<NewsArticle> get _localArticles {
    final byDistrict = demoNews
        .where((article) => article.location == widget.selectedDistrict)
        .toList();

    if (byDistrict.isNotEmpty) {
      return byDistrict;
    }

    return demoNews
        .where((article) => article.location == widget.selectedState)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    _mapController = MapController();

    _loadLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _loadLocation() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final position = await LocationService.instance.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        _position = position;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _position == null) return;

        _mapController.move(
          LatLng(_position!.latitude, _position!.longitude),
          15,
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _recenterMap() {
    if (_position == null) return;

    _mapController.move(LatLng(_position!.latitude, _position!.longitude), 15);
  }

  // ============================================================
  // OPEN NEWS STORY
  // ============================================================

  void _openArticle(NewsArticle article) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return NewsStoryPage(
            article: article,
            selectedLanguage: widget.selectedLanguage,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.black,
          backgroundColor: Colors.white,
          displacement: 30,
          onRefresh: _loadLocation,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(14, 75, 14, 120),
              children: [
                _buildHeader(),

                const SizedBox(height: 22),

                _buildLocationStatus(),

                const SizedBox(height: 16),

                _buildMap(),

                const SizedBox(height: 16),

                _buildLocationDetails(),

                const SizedBox(height: 30),

                _buildLocalNewsHeader(),

                const SizedBox(height: 14),

                _buildLocalNews(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t('your_location', widget.selectedLanguage),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: Colors.redAccent,
                    ),
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LocationPill(
                        district: widget.selectedDistrict,
                        state: widget.selectedState,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 14),

        _buildRefreshButton(),
      ],
    );
  }

  // ============================================================
  // REFRESH BUTTON
  // ============================================================

  Widget _buildRefreshButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: _isLoading ? null : _loadLocation,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: Colors.black54,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: Colors.black87,
                  ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION STATUS
  // ============================================================

  Widget _buildLocationStatus() {
    final hasLocation = !_isLoading && _errorMessage == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasLocation ? const Color(0xFFF0F8F2) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLocation
              ? const Color(0xFFDCEFE0)
              : const Color(0xFFF5E4CF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: hasLocation
                  ? const Color(0xFFDFF2E3)
                  : const Color(0xFFFFEAD2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasLocation
                  ? Icons.my_location_rounded
                  : Icons.location_searching_rounded,
              size: 16,
              color: hasLocation
                  ? const Color(0xFF2E7D4F)
                  : const Color(0xFFB56A21),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoading
                      ? 'Finding your location'
                      : hasLocation
                      ? 'Location is enabled'
                      : 'Location unavailable',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _isLoading
                      ? 'Getting your precise location...'
                      : hasLocation
                      ? 'Showing news around your selected area.'
                      : 'Check your location permission and try again.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    height: 1.35,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          if (hasLocation)
            const Icon(
              Icons.check_circle_rounded,
              size: 19,
              color: Color(0xFF3C8D5C),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMap() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 300,
          child: Stack(
            children: [
              Positioned.fill(child: _buildMapContent()),

              if (!_isLoading && _errorMessage == null)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3C8D5C),
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 7),

                        Text(
                          'CURRENT LOCATION',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (!_isLoading && _errorMessage == null)
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: _buildRecenterButton(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RECENTER BUTTON
  // ============================================================

  Widget _buildRecenterButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      elevation: 0,
      child: InkWell(
        onTap: _recenterMap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location_rounded,
            size: 20,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAP CONTENT
  // ============================================================

  Widget _buildMapContent() {
    if (_isLoading) {
      return Container(
        color: const Color(0xFFEAEAE7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(17),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'Fetching precise location...',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'This may take a moment',
              style: GoogleFonts.inter(fontSize: 9.5, color: Colors.black38),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: const Color(0xFFEAEAE7),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_off_outlined,
                  size: 25,
                  color: Colors.black45,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Unable to find your location',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: _loadLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: Colors.white,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        AppStrings.t('retry', widget.selectedLanguage),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final position = _position!;

    final currentLatLng = LatLng(position.latitude, position.longitude);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: currentLatLng,
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.yourcompany.news_app',
        ),

        CircleLayer(
          circles: [
            CircleMarker(
              point: currentLatLng,
              radius: position.accuracy.clamp(25, 80),
              useRadiusInMeter: true,
              color: Colors.blue.withValues(alpha: 0.10),
              borderColor: Colors.blue.withValues(alpha: 0.25),
              borderStrokeWidth: 1,
            ),
          ],
        ),

        MarkerLayer(
          markers: [
            Marker(
              point: currentLatLng,
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.redAccent,
                    size: 34,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // LOCATION DETAILS
  // ============================================================

  Widget _buildLocationDetails() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.045)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.explore_outlined,
              size: 21,
              color: Colors.black87,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your news area',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  DisplayFormatters.compactLocation(
                    widget.selectedDistrict,
                    widget.selectedState,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          if (_position != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ACCURACY',
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: Colors.black38,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${_position!.accuracy.round()} m',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCAL NEWS HEADER
  // ============================================================

  Widget _buildLocalNewsHeader() {
    final articleCount = _localArticles.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t('local_news', widget.selectedLanguage),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Stories from your area',
                style: GoogleFonts.inter(fontSize: 10.5, color: Colors.black45),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '$articleCount '
            '${articleCount == 1 ? 'Story' : 'Stories'}',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOCAL NEWS
  // ============================================================

  Widget _buildLocalNews() {
    if (_localArticles.isEmpty) {
      return _buildEmptyNewsState();
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _localArticles.map((article) {
          return NewsCard(
            article: article,
            onTap: () {
              _openArticle(article);
            },
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyNewsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.045)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F3F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.article_outlined,
              size: 28,
              color: Colors.black38,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Nothing local yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            AppStrings.t('no_local_news', widget.selectedLanguage),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.5,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 18),

          GestureDetector(
            onTap: _loadLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: Colors.white,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    'CHECK AGAIN',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
