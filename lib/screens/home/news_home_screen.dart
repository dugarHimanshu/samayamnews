import 'dart:math' as math; // pi, sin for the curl maths
import 'dart:ui' as ui; // ui.Image (page snapshot), ui.Gradient, ui.Vertices
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart'; // SpringSimulation (settle animation after you let go)
import 'package:flutter/rendering.dart'; // RenderRepaintBoundary (used to snapshot a page)
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/demo_news.dart';
import '../../data/demo_magazines.dart';
import '../../data/demo_ads.dart';
import '../../models/magazine.dart';
import '../../models/news_article.dart';
import '../../services/news_service.dart';
import '../../services/saved_news_store.dart';
import '../../services/magazine_store.dart';
import '../../services/article_translator.dart';
import '../magazine/magazine_reader_page.dart';

// ============================================================
// LAYOUT CONFIG
// Decides the device type and sizes (hero image height, max width)
// ============================================================

enum DeviceType { mobile, foldable, tablet, desktop }

class NewsLayoutConfig {
  // Works out what kind of device we are on, based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final shortest = MediaQuery.of(context).size.shortestSide;
    if (width < 320 || (width >= 280 && width <= 360 && shortest < 450)) {
      return DeviceType.foldable;
    }
    if (width < 600) return DeviceType.mobile;
    if (width < 1024) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  // Maximum width of a news page (limits it on big screens)
  static double maxWidth(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.foldable:
      case DeviceType.mobile:
        return double.infinity;
      case DeviceType.tablet:
        return 680;
      case DeviceType.desktop:
        return 780;
    }
  }

  // Height of the hero image at the top of each story
  static double heroHeight(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    if (h < 640) return h * 0.30;
    if (h < 750) return h * 0.33;
    if (h < 880) return h * 0.36;
    return h * 0.38; // for tall flagship devices like S25 Ultra, Pixel 9 Pro XL
  }
}

// ============================================================
// BOOK PAGE FLIP (replaces PageView)
//
// HOW IT WORKS
// 1. The current page is photographed (a snapshot image).
// 2. While you drag, that snapshot is redrawn as a bent mesh:
//    the bottom part of the page wraps around a cylinder (the curl),
//    and the end of the page lies flipped over on top (the back side).
// 3. The NEXT page is a normal live widget waiting underneath,
//    and a soft shadow is painted on it by the curl.
// ============================================================

class BookPageFlip extends StatefulWidget {
  // How many pages in total
  final int itemCount;

  // Builds the page for a given index (same idea as PageView.builder)
  final IndexedWidgetBuilder itemBuilder;

  // Called when the visible page changes (after the flip passes halfway)
  final ValueChanged<int>? onPageChanged;

  // Called every frame with the live page position (e.g. 1.37 = 37% into flipping page 1)
  final ValueChanged<double>? onPageScroll;

  const BookPageFlip({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onPageChanged,
    this.onPageScroll,
  });

  @override
  State<BookPageFlip> createState() => BookPageFlipState();
}

class BookPageFlipState extends State<BookPageFlip>
    with SingleTickerProviderStateMixin {
  // ----------------------------------------------------------
  // TUNING KNOBS - change these numbers to adjust the feel
  // ----------------------------------------------------------

  // Size of the curl roll as a fraction of screen height.
  // 0.05 = tight thin curl, 0.10 = big soft curl.
  static const double _curlRadiusFactor = 0.075;

  // Strength of the shadow the curl casts on the page underneath (0 - 1)
  static const double _castShadowStrength = 0.45;

  // How dark the page underneath starts (0 - 1). It brightens as you flip.
  static const double _underPageDim = 0.30;

  // Fraction of the screen height you drag to flip one full page (smaller = more sensitive)
  static const double _dragDistanceFactor = 0.9;

  // Swipe speed (pixels/second) that counts as a "fling" and always flips the page
  static const double _flingVelocity = 500;

  // Sharpness of the page snapshot (device pixel ratio is capped to this).
  // Higher = sharper but uses more memory.
  static const double _maxSnapshotPixelRatio = 3.0;

  // Colour of the back of the paper (the side you see on the flipped part)
  static const Color _paperColor = Color(0xFFF3F0E8);

  // Background behind every page (same as the screen background)
  static const Color _pageBackground = Color(0xFFF8F8F6);

  // Spring used when the page settles after you let go
  static final SpringDescription _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 140, // higher = faster snap
    ratio: 1.0, // 1.0 = no bounce
  );

  // ----------------------------------------------------------
  // STATE
  // ----------------------------------------------------------

  // Holds the live page position as a decimal number.
  // Example: 2.0 = page 2 fully shown, 2.5 = page 2 half flipped.
  late final AnimationController _ctrl;

  int _currentPage = 0; // last page reported through onPageChanged
  Size _size = const Size(1, 1); // available size, measured in build()
  bool _dragging = false; // true while the finger is on the screen
  bool _dirty = false; // true if the pages changed while we were moving

  // Snapshots (photos) of pages, by page index. Used while flipping.
  final Map<int, ui.Image> _snaps = {};

  // One GlobalKey per page so we can photograph that page.
  final Map<int, GlobalKey> _keys = {};

  // Cache of built page widgets (so they are not rebuilt on every frame).
  final Map<int, Widget> _pageCache = {};

  // True when nothing is moving
  bool get _isIdle => !_dragging && !_ctrl.isAnimating;

  @override
  void initState() {
    super.initState();
    // "unbounded" lets the value be any number, so we can use it as a page position
    _ctrl = AnimationController.unbounded(vsync: this, value: 0);
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
    _captureNeeded(); // take the first snapshots after the first frame
  }

  @override
  void didUpdateWidget(covariant BookPageFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent rebuilt (news changed, liked, etc.): forget cached pages
    _pageCache.clear();
    if (_isIdle) {
      _captureNeeded(refresh: true); // re-photograph the pages
    } else {
      _dirty = true; // do it once the page stops moving
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    for (final img in _snaps.values) {
      img.dispose();
    }
    _snaps.clear();
    super.dispose();
  }

  // Runs every time the page position changes (drag or spring animation)
  void _onTick() {
    widget.onPageScroll?.call(_ctrl.value);

    // Report a page change when the position rounds to a different page
    final rounded = _ctrl.value.round();
    if (rounded != _currentPage) {
      _currentPage = rounded;
      widget.onPageChanged?.call(rounded);
    }
  }

  // Runs when the spring animation finishes
  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final refresh = _dirty;
      _dirty = false;
      _captureNeeded(refresh: refresh);
    }
  }

  // Jump to a page instantly with no animation (used via GlobalKey)
  void jumpToPage(int page) {
    _ctrl.stop();
    _ctrl.value = page.toDouble();
    _captureNeeded(refresh: true);
  }

  // ----------------------------------------------------------
  // SNAPSHOTS (photos of pages)
  // ----------------------------------------------------------

  // Gets (or creates) the key used to photograph page [i]
  GlobalKey _keyFor(int i) => _keys.putIfAbsent(i, () => GlobalKey());

  // Photographs the pages around the current one (previous, current, next).
  // Runs after the next frame is painted, so the pages are ready to be photographed.
  void _captureNeeded({bool refresh = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final centre = _ctrl.value.round();

      for (final i in [centre, centre - 1, centre + 1]) {
        _capture(i, refresh: refresh);
      }

      // Throw away snapshots / cached pages that are far away (saves memory)
      if (_isIdle) {
        _snaps.removeWhere((i, img) {
          final far = (i - centre).abs() > 2;
          if (far) img.dispose();
          return far;
        });
        _pageCache.removeWhere((i, _) => (i - centre).abs() > 2);
      }
    });
    WidgetsBinding.instance.scheduleFrame(); // make sure a frame happens
  }

  // Takes one snapshot of page [i]
  Future<void> _capture(int i, {bool refresh = false}) async {
    if (i < 0 || i >= widget.itemCount) return;
    if (!refresh && _snaps.containsKey(i)) return; // already have it

    final boundary = _keys[i]?.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return; // page not on screen

    final ratio = MediaQuery.of(context)
        .devicePixelRatio
        .clamp(1.0, _maxSnapshotPixelRatio)
        .toDouble();

    try {
      final img = await boundary.toImage(pixelRatio: ratio);
      if (!mounted) {
        img.dispose();
        return;
      }
      final old = _snaps[i];
      // Never swap an image that might be on screen right now
      if (old != null && !_isIdle) {
        img.dispose();
        return;
      }
      _snaps[i] = img;
      old?.dispose();
    } catch (_) {
      // Snapshot failed this time; it will be retried on the next drag
    }
  }

  // ----------------------------------------------------------
  // GESTURES
  // ----------------------------------------------------------

  // Finger touched and started dragging: stop any running animation
  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _ctrl.stop();
    _captureNeeded(); // make sure snapshots are ready
  }

  // Finger is moving: update the page position directly
  void _onDragUpdate(DragUpdateDetails d) {
    final maxPage = (widget.itemCount - 1).toDouble();

    // Dragging UP (negative dy) goes to the next page, so we subtract
    final target = (_ctrl.value - d.delta.dy / (_size.height * _dragDistanceFactor))
        .clamp(0.0, maxPage)
        .toDouble();

    // The page that will be curled needs a snapshot first.
    // If it is not ready yet, wait (it only takes a frame or two).
    final isWholePage = (target - target.round()).abs() < 0.002;
    if (!isWholePage && !_snaps.containsKey(target.floor())) {
      _captureNeeded();
      return;
    }

    _ctrl.value = target;
  }

  // Finger lifted
  void _onDragEnd(DragEndDetails d) => _release(d.primaryVelocity ?? 0);

  // Drag was cancelled (e.g. a system gesture took over)
  void _onDragCancel() => _release(0);

  // Decide which page to land on, then spring there
  void _release(double velocity) {
    _dragging = false; // velocity is px/s, negative = swiping up
    final maxPage = (widget.itemCount - 1).toDouble();

    // Default: snap to the nearest page
    double target = _ctrl.value.roundToDouble();

    // A fast swipe overrides it, so quick flicks always flip
    if (velocity < -_flingVelocity) {
      target = _ctrl.value.ceilToDouble(); // go forward
    } else if (velocity > _flingVelocity) {
      target = _ctrl.value.floorToDouble(); // go back
    }
    target = target.clamp(0.0, maxPage).toDouble();

    // Spring from the current position to the target, keeping the finger's speed
    _ctrl.animateWith(
      SpringSimulation(
        _spring,
        _ctrl.value,
        target,
        -velocity / (_size.height * _dragDistanceFactor), // px/s -> pages/s
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILDING
  // ----------------------------------------------------------

  // One real (live) page. It is cached so it is not rebuilt every frame.
  // Only the top page can be touched; hidden ones ignore touches.
  Widget _page(int i, {required bool interactive}) {
    final inner = _pageCache.putIfAbsent(
      i,
      () => RepaintBoundary(
        key: _keyFor(i), // lets us take a snapshot of this page
        child: ColoredBox(
          color: _pageBackground, // makes every page fully opaque
          child: widget.itemBuilder(context, i),
        ),
      ),
    );

    return KeyedSubtree(
      key: ValueKey('page_$i'), // keeps each page's state when layers reorder
      child: IgnorePointer(ignoring: !interactive, child: inner),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to show
    if (widget.itemCount == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: _onDragStart,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          onVerticalDragCancel: _onDragCancel,
          // ClipRect hides anything that goes outside the screen
          child: ClipRect(
            // Rebuild every time the page position changes
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => _buildStack(),
            ),
          ),
        );
      },
    );
  }

  // Builds the layers for the current page position
  Widget _buildStack() {
    final maxPage = widget.itemCount - 1;
    final pos = _ctrl.value.clamp(0.0, maxPage.toDouble()).toDouble();

    // "settled" = the position is (almost) exactly on one page
    final nearest = pos.round();
    final settled = (pos - nearest).abs() < 0.002;

    final base = settled ? nearest : pos.floor(); // the page being flipped
    final t = settled ? 0.0 : pos - base; // flip progress: 0 = flat, 1 = gone

    // We can only draw the curl if we have a snapshot of the page
    final peeling = !settled && _snaps.containsKey(base);

    final layers = <Widget>[];

    // Previous page: hidden at the very bottom (kept ready for flipping back)
    if (base - 1 >= 0) layers.add(_page(base - 1, interactive: false));

    if (peeling) {
      // Order (bottom -> top): current (hidden), next page, curl drawing
      layers.add(_page(base, interactive: false));
      layers.add(_page(base + 1, interactive: false));
      layers.add(
        Positioned.fill(
          key: const ValueKey('curl'),
          child: IgnorePointer(
            child: CustomPaint(
              painter: _CurlPainter(
                image: _snaps[base]!,
                progress: t,
                maxRadius: _size.height * _curlRadiusFactor,
                castShadow: _castShadowStrength,
                underDim: _underPageDim,
                paperColor: _paperColor,
              ),
            ),
          ),
        ),
      );
    } else {
      // Resting: next page hidden underneath, current page live on top
      if (base + 1 <= maxPage) layers.add(_page(base + 1, interactive: false));
      layers.add(_page(base, interactive: settled));
    }

    return Stack(fit: StackFit.expand, children: layers);
  }
}

// ============================================================
// CURL PAINTER
// Draws the snapshot of a page bent around a cylinder.
//
// Page coordinates: y = 0 is the top of the page, y = height is the bottom.
// "a" is the line where the curl starts (it moves from the bottom to the top).
// "r" is the radius of the curl roll.
//
//   y <= a            -> flat part of the page (stays where it is)
//   a < y < a + pi*r  -> wraps around the roll (the curved part)
//   y >= a + pi*r     -> flipped over, lying on top (back of the paper)
// ============================================================

class _CurlPainter extends CustomPainter {
  final ui.Image image; // snapshot of the page being flipped
  final double progress; // 0 = flat page, 1 = page completely gone
  final double maxRadius; // biggest radius of the roll, in pixels
  final double castShadow; // strength of the shadow on the page underneath
  final double underDim; // how dark the page underneath starts
  final Color paperColor; // colour of the back of the paper

  const _CurlPainter({
    required this.image,
    required this.progress,
    required this.maxRadius,
    required this.castShadow,
    required this.underDim,
    required this.paperColor,
  });

  // How many slices the curved part is cut into (more = smoother curve)
  static const int _steps = 28;

  // Converts a position on the flat page (y) to where it appears on screen.
  static double _screenY(double y, double a, double r) {
    final d = y - a; // distance past the start of the curl
    if (d <= 0) return y; // flat part
    if (d < math.pi * r) return a + r * math.sin(d / r); // on the roll
    return a - (d - math.pi * r); // flipped back, going upwards
  }

  // Grey colour used to darken / lighten (1 = unchanged, 0 = black)
  static Color _gray(double v, [double alpha = 1.0]) {
    final c = (v.clamp(0.0, 1.0) * 255).round();
    return Color.fromRGBO(c, c, c, alpha);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // The roll starts tight, gets fuller in the middle, tightens at the end
    final r = maxRadius * (0.55 + 0.45 * math.sin(math.pi * progress));

    // Where the curl starts. Moves from the bottom (h) to above the top (-2r).
    final a = h - progress * (h + 2 * r);

    // Ratio between snapshot pixels and screen pixels
    final sx = image.width / w;
    final sy = image.height / h;

    // Paint that uses the snapshot as its texture
    final texPaint = Paint()
      ..shader = ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      )
      ..filterQuality = FilterQuality.medium;

    // ------------------------------------------------------
    // 1) PAGE UNDERNEATH: darken it and add the curl's shadow
    // ------------------------------------------------------

    // Overall dimming that fades away as the page is revealed
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.black.withValues(alpha: underDim * (1 - progress)),
    );

    // Soft shadow just below the lowest point of the curl
    final lowestFrontY = math.min(math.max(a + math.pi * r / 2, 0.0), h);
    final edgeY = _screenY(lowestFrontY, a, r);
    final shadowLen = r * 3 + 24;
    final shadowAlpha = castShadow * (1 - progress);
    canvas.drawRect(
      Rect.fromLTWH(0, edgeY, w, shadowLen),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, edgeY),
          Offset(0, edgeY + shadowLen),
          [
            Colors.black.withValues(alpha: shadowAlpha),
            Colors.black.withValues(alpha: shadowAlpha * 0.3),
            Colors.black.withValues(alpha: 0),
          ],
          [0.0, 0.35, 1.0],
        ),
    );

    // ------------------------------------------------------
    // 2) FRONT OF THE PAGE: flat part + the curved part facing us
    // ------------------------------------------------------

    final frontEnd = math.min(a + math.pi * r / 2, h); // roll turns sideways here
    final frontStart = math.max(a, 0.0);
    final frontYs = <double>[];
    if (frontEnd > frontStart) {
      if (a > 0) frontYs.add(0.0); // top of the page (flat part)
      for (var i = 0; i <= _steps; i++) {
        frontYs.add(frontStart + (frontEnd - frontStart) * i / _steps);
      }
    }

    // Front shading: gets darker as the paper turns away from us
    double frontShade(double y) {
      final d = y - a;
      if (d <= 0) return 1.0;
      final theta = (d / r).clamp(0.0, math.pi / 2).toDouble();
      return 1 - 0.38 * math.pow(math.sin(theta), 1.2).toDouble();
    }

    _drawStrip(
      canvas,
      frontYs,
      w: w,
      a: a,
      r: r,
      sx: sx,
      sy: sy,
      colorAt: (y) => _gray(frontShade(y)),
      texPaint: texPaint,
      mode: BlendMode.modulate, // texture x colour = shaded page
    );

    // ------------------------------------------------------
    // 3) SHADOW of the flipped part on the flat page below it
    // ------------------------------------------------------

    final hasFlatBack = h > a + math.pi * r;
    if (hasFlatBack) {
      final tip = _screenY(h, a, r); // where the end of the page is on screen
      if (tip > 0) {
        final top = math.max(0.0, tip - 40);
        canvas.drawRect(
          Rect.fromLTRB(0, top, w, tip),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, top),
              Offset(0, tip),
              [
                Colors.black.withValues(alpha: 0),
                Colors.black.withValues(alpha: 0.22),
              ],
            ),
        );
      }
    }

    // ------------------------------------------------------
    // 4) BACK OF THE PAGE: the part that is turned over
    // ------------------------------------------------------

    final backStart = math.max(a + math.pi * r / 2, 0.0);
    final backYs = <double>[];
    if (backStart < h) {
      final curveEnd = math.min(a + math.pi * r, h);
      if (curveEnd > backStart) {
        for (var i = 0; i <= _steps; i++) {
          backYs.add(backStart + (curveEnd - backStart) * i / _steps);
        }
      } else {
        backYs.add(backStart);
      }
      if (curveEnd < h) backYs.add(h); // the flat flipped end
    }

    // Back shading: dark where it turns away, lighter as it lies flat
    double backShade(double y) {
      final d = y - a;
      if (d >= math.pi * r) return 0.97;
      final u = ((d / r - math.pi / 2) / (math.pi / 2)).clamp(0.0, 1.0).toDouble();
      return 0.62 + 0.35 * math.pow(u, 0.7).toDouble();
    }

    // 4a) plain paper colour
    _drawStrip(
      canvas,
      backYs,
      w: w,
      a: a,
      r: r,
      sx: sx,
      sy: sy,
      colorAt: (y) => Color.lerp(Colors.black, paperColor, backShade(y))!,
      texPaint: null,
      mode: BlendMode.src,
    );

    // 4b) a very faint ghost of the print showing through the paper
    _drawStrip(
      canvas,
      backYs,
      w: w,
      a: a,
      r: r,
      sx: sx,
      sy: sy,
      colorAt: (y) => _gray(backShade(y), 0.14),
      texPaint: texPaint,
      mode: BlendMode.modulate,
    );
  }

  // Draws one strip of the page as a triangle mesh.
  // [ys] are the page positions of each slice (top to bottom).
  // If [texPaint] is null only colours are drawn (plain paper).
  void _drawStrip(
    Canvas canvas,
    List<double> ys, {
    required double w,
    required double a,
    required double r,
    required double sx,
    required double sy,
    required Color Function(double y) colorAt,
    required Paint? texPaint,
    required BlendMode mode,
  }) {
    if (ys.length < 2) return; // need at least one slice

    final positions = <Offset>[]; // where each point goes on screen
    final texCoords = <Offset>[]; // which pixel of the snapshot it shows
    final colors = <Color>[]; // shading colour of each point

    for (final y in ys) {
      final screenY = _screenY(y, a, r);
      final c = colorAt(y);

      // left and right point of this slice
      positions.add(Offset(0, screenY));
      positions.add(Offset(w, screenY));

      texCoords.add(Offset(0, y * sy));
      texCoords.add(Offset(w * sx, y * sy));

      colors.add(c);
      colors.add(c);
    }

    final vertices = ui.Vertices(
      ui.VertexMode.triangleStrip,
      positions,
      textureCoordinates: texPaint != null ? texCoords : null,
      colors: colors,
    );
    canvas.drawVertices(vertices, mode, texPaint ?? Paint());
  }

  @override
  bool shouldRepaint(covariant _CurlPainter old) =>
      old.progress != progress ||
      old.image != image ||
      old.maxRadius != maxRadius;
}

// ============================================================
// NEWS HOME SCREEN (the widget main_shell.dart uses)
// ============================================================

class NewsHomeScreen extends StatefulWidget {
  final String selectedLanguage;
  final String selectedState;
  final String selectedDistrict;
  final ValueChanged<bool>? onChromeVisibilityChanged;

  const NewsHomeScreen({
    super.key,
    required this.selectedLanguage,
    required this.selectedState,
    required this.selectedDistrict,
    this.onChromeVisibilityChanged,
  });

  @override
  State<NewsHomeScreen> createState() => _NewsHomeScreenState();
}

class _NewsHomeScreenState extends State<NewsHomeScreen>
    with WidgetsBindingObserver {
  // Key lets us call jumpToPage() on the flip widget (used after reloading news)
  final GlobalKey<BookPageFlipState> _flipKey = GlobalKey<BookPageFlipState>();

  final NewsService _newsService = NewsService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final SavedNewsStore _savedStore = SavedNewsStore.instance;
  final MagazineStore _magazineStore = MagazineStore.instance;

  List<NewsArticle> _articles = [];
  final List<dynamic> _feedItems = []; // Contains NewsArticle, _AdSlot, or Magazine
  bool _isLoading = true;
  int _currentPage = 0;
  bool _showHeader = true;
  double _lastPage = 0;
  final Set<String> _likedArticleIds = {};
  RealtimeChannel? _channel;
  static const int _newsPerAd = 4; // an ad approximately every 4 news items

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _savedStore.load();
    _magazineStore.load();
    _loadNews();
    _subscribe();
  }

  // Reload news when state / district / language changes
  @override
  void didUpdateWidget(covariant NewsHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedState != widget.selectedState ||
        oldWidget.selectedDistrict != widget.selectedDistrict ||
        oldWidget.selectedLanguage != widget.selectedLanguage) {
      _loadNews();
    }
  }

  // Refresh quietly when the app comes back to the foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSilently();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
    }
    super.dispose();
  }

  // Listens to the Supabase table and refreshes when it changes
  void _subscribe() {
    if (_channel != null) return;
    _channel = _supabase
        .channel('news-feed')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'news_articles',
          callback: (_) => _refreshSilently(),
        )
        .subscribe();
  }

  // Fetches news without showing a loading spinner
  Future<void> _refreshSilently() async {
    try {
      final live = await _newsService.fetchNews(
        state: widget.selectedState,
        district: widget.selectedDistrict,
      );
      if (!mounted) return;
      setState(() {
        _articles = _merge(live);
        _buildFeedItems();
      });
    } catch (_) {}
  }

  // Combines live news with demo news and removes duplicates
  List<NewsArticle> _merge(List<NewsArticle> live) {
    final res = <NewsArticle>[];
    final ids = <String>{};
    final titles = <String>{};
    for (var a in [...live, ...demoNews]) {
      final id = a.id.trim();
      final title = a.title.trim().toLowerCase();
      if ((id.isNotEmpty && ids.contains(id)) ||
          (title.isNotEmpty && titles.contains(title))) {
        continue;
      }
      if (id.isNotEmpty) ids.add(id);
      if (title.isNotEmpty) titles.add(title);
      res.add(a);
    }
    return res;
  }

  // Intersperses news articles with ads strictly every 5 news articles
  // and non-repeating unique magazines placed in between
  void _buildFeedItems() {
    _feedItems.clear();
    if (_articles.isEmpty) return;

    // Use shuffled pool of unique ads so none repeat until pool is exhausted
    final adPool = List<AdvertisementItem>.from(demoAds)..shuffle(math.Random());
    int adPoolIndex = 0;

    // Use shuffled pool of unique magazines so none repeat
    final magPool = List<Magazine>.from(demoMagazines)..shuffle(math.Random());
    int magPoolIndex = 0;

    int newsCountSinceAd = 0;

    for (int i = 0; i < _articles.length; i++) {
      _feedItems.add(_articles[i]);
      newsCountSinceAd++;

      // Optionally spawn a unique magazine between news (e.g. at article 2 or 3 of the 5-block)
      // without disrupting the strict 5-news ad cycle
      if (newsCountSinceAd == 3 && magPoolIndex < magPool.length) {
        _feedItems.add(magPool[magPoolIndex]);
        magPoolIndex++;
      }

      // STRICT RULE: An advertisement appears after every 5 news articles
      if (newsCountSinceAd == 5) {
        // Pick unique ad without repeating
        final adToInsert = adPoolIndex < adPool.length
            ? adPool[adPoolIndex++]
            : demoAds[(i ~/ 5) % demoAds.length];
        _feedItems.add(adToInsert);
        newsCountSinceAd = 0;
      }
    }
  }

  // Loads news (with a spinner unless refresh = true)
  Future<void> _loadNews({bool refresh = false}) async {
    setState(() {
      if (!refresh) {
        _isLoading = true;
      }
    });

    try {
      final live = await _newsService.fetchNews(
        state: widget.selectedState,
        district: widget.selectedDistrict,
      );
      if (!mounted) return;
      setState(() {
        _articles = _merge(live);
        _buildFeedItems();
        _isLoading = false;
        _currentPage = 0;
        _lastPage = 0;
      });
      // Go back to the first page after reloading
      _flipKey.currentState?.jumpToPage(0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _articles = _merge([]);
        _buildFeedItems();
        _isLoading = false;
      });
    }
  }

  // Called every frame while flipping, with the live page position.
  // Hides the header when flipping forward, shows it when flipping back.
  void _onScroll(double page) {
    if (page > _lastPage + 0.02 && _showHeader) {
      _showHeader = false;
      widget.onChromeVisibilityChanged?.call(false);
    } else if ((page < _lastPage - 0.02 || page <= 0.05) && !_showHeader) {
      _showHeader = true;
      widget.onChromeVisibilityChanged?.call(true);
    }
    _lastPage = page;
  }

  // Tap anywhere to show / hide the header
  void _toggleChrome() {
    setState(() {
      _showHeader = !_showHeader;
      widget.onChromeVisibilityChanged?.call(_showHeader);
    });
  }

  // Total pages in feed
  int _totalPages() => _feedItems.length;

  // Builds one page (a news story, an ad, or a magazine card). Passed to BookPageFlip.
  Widget _buildPage(BuildContext context, int index) {
    if (index >= _feedItems.length) return const SizedBox();

    final item = _feedItems[index];

    // Case 1: Ad page
    if (item is AdvertisementItem) {
      return _AdPage(ad: item);
    }
    if (item is _AdSlot) {
      return _AdPage(ad: demoAds[index % demoAds.length]);
    }

    // Case 2: Magazine page
    if (item is Magazine) {
      return _MagazineFeedCard(
        magazine: item,
        selectedLanguage: widget.selectedLanguage,
      );
    }

    // Case 3: News article
    final article = item as NewsArticle;
    final articleKey = article.id.isNotEmpty ? article.id : '${article.title}-$index';

    return _SinglePageStory(
      key: ValueKey(articleKey),
      article: article,
      liked: _likedArticleIds.contains(articleKey),
      bookmarked: _savedStore.isSaved(article.title),
      onLike: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (_likedArticleIds.contains(articleKey)) {
            _likedArticleIds.remove(articleKey);
          } else {
            _likedArticleIds.add(articleKey);
          }
        });
      },
      onBookmark: () async {
        await _savedStore.toggle(article.title);
        setState(() {});
      },
      selectedLanguage: widget.selectedLanguage,
      selectedDistrict: widget.selectedDistrict,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading spinner
    if (_isLoading) {
      return Container(
        color: const Color(0xFFF8F8F6),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.black54),
        ),
      );
    }

    // Empty state with a refresh button
    if (_articles.isEmpty) {
      return Container(
        color: const Color(0xFFF8F8F6),
        child: Center(
          child: OutlinedButton(
            onPressed: () => _loadNews(refresh: true),
            child: const Text('REFRESH'),
          ),
        ),
      );
    }

    final total = _totalPages();

    return Container(
      color: const Color(0xFFF8F8F6),
      child: Stack(
        children: [
          // Tap anywhere to show/hide the header (drags are handled by BookPageFlip)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleChrome,
            child: BookPageFlip(
              key: _flipKey,
              itemCount: total,
              itemBuilder: _buildPage,
              onPageScroll: _onScroll,
              onPageChanged: (i) => setState(() => _currentPage = i),
            ),
          ),

          // Page counter badge (top right), e.g. "3/12"
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 70,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentPage + 1}/$total',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SINGLE PAGE STORY VIEW
// One full news page: hero image, title, text, action buttons
// ============================================================

class _SinglePageStory extends StatefulWidget {
  final NewsArticle article;
  final bool liked;
  final bool bookmarked;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final String selectedLanguage;
  final String selectedDistrict;

  const _SinglePageStory({
    super.key,
    required this.article,
    required this.liked,
    required this.bookmarked,
    required this.onLike,
    required this.onBookmark,
    required this.selectedLanguage,
    required this.selectedDistrict,
  });

  @override
  State<_SinglePageStory> createState() => _SinglePageStoryState();
}

class _SinglePageStoryState extends State<_SinglePageStory> {
  bool _isTranslating = false; // true while a translation is running
  late String _lang; // currently selected reading language
  late String _title, _desc, _body; // text shown on the page (may be translated)

  @override
  void initState() {
    super.initState();
    _lang = widget.selectedLanguage;
    _initContent();
    // Translate right away if the language is not English
    if (_lang != 'English' &&
        ArticleTranslator.languageCodes.containsKey(_lang)) {
      _translate(_lang);
    }
  }

  // Sets the original (untranslated) text
  void _initContent() {
    _title = widget.article.title;
    _desc = widget.article.description;
    _body = widget.article.content.isNotEmpty
        ? widget.article.content
        : widget.article.description;
  }

  // Re-initialise when the article or language changes
  @override
  void didUpdateWidget(covariant _SinglePageStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article.id != widget.article.id ||
        oldWidget.selectedLanguage != widget.selectedLanguage) {
      _lang = widget.selectedLanguage;
      _initContent();
      if (_lang != 'English' &&
          ArticleTranslator.languageCodes.containsKey(_lang)) {
        _translate(_lang);
      }
    }
  }

  // Translates title, description and body into the target language
  Future<void> _translate(String target) async {
    setState(() => _isTranslating = true);
    try {
      final translatedMap = await ArticleTranslator.translateArticle(
        title: widget.article.title,
        description: widget.article.description,
        body: widget.article.content.isNotEmpty
            ? widget.article.content
            : widget.article.description,
        targetLanguage: target,
      );

      if (!mounted) return;
      setState(() {
        _title = translatedMap['title'] ?? _title;
        _desc = translatedMap['description'] ?? _desc;
        _body = translatedMap['body'] ?? _body;
        _isTranslating = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  // Bottom sheet to choose the reading language
  void _showLangPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'Read in',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                // One row per available language
                ...ArticleTranslator.languageCodes.keys.map(
                  (l) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      l,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    trailing: l == _lang ? const Icon(Icons.check, size: 18, color: Colors.black) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _lang = l);
                      _translate(l);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroH = NewsLayoutConfig.heroHeight(context);
    final maxW = NewsLayoutConfig.maxWidth(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HERO IMAGE + WATERMARKS
            SizedBox(
              height: heroH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The news image (grey box if there is no image)
                  widget.article.imageUrl.isEmpty
                      ? Container(color: Colors.grey.shade200)
                      : CachedNetworkImage(
                          imageUrl: widget.article.imageUrl,
                          fit: BoxFit.cover,
                        ),
                  // Dark gradient on top and bottom of the image
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black38,
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                  // TOP RIGHT WATERMARK
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Image.asset(
                      'assets/public/images/watermark/watermark_top_right.png',
                      width: 74,
                      height: 74,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  // BOTTOM LEFT WATERMARK
                  Positioned(
                    bottom: -32,
                    left: -4, // Pushes it further to the left (off-screen)
                    child: Image.asset(
                      'assets/public/images/watermark/watermark_bottom_left.png',
                      width: 250, // Larger width
                      height: 100, // Larger height
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomLeft,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  // CATEGORY LABEL (top left)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.article.category.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ARTICLE INFO & COMPACT CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    final isSmallScreen = availableHeight < 360;
                    final isMediumScreen = availableHeight >= 360 && availableHeight < 460;
                    final titleLines = isSmallScreen ? 2 : 3;
                    final descLines = isSmallScreen ? 2 : (isMediumScreen ? 4 : 5);
                    final bodyLines = isSmallScreen ? 4 : (isMediumScreen ? 6 : 9);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Scrollable/flexible text block (title, divider, description, body)
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title displays gracefully
                                Text(
                                  _title,
                                  maxLines: titleLines,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Thin line under the title
                                Divider(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  thickness: 1,
                                  height: 1,
                                ),
                                const SizedBox(height: 8),
                                // Short description
                                if (_desc.trim().isNotEmpty) ...[
                                  Text(
                                    _desc,
                                    maxLines: descLines,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: isSmallScreen ? 10.5 : 11,
                                      height: 1.45,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                // Main body text
                                if (_body.trim().isNotEmpty)
                                  Text(
                                    _body,
                                    maxLines: bodyLines,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      height: 1.45,
                                      color: Colors.black87,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ACTIONS + FOOTER INFO
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Author / source and date
                            Expanded(
                              child: Text(
                                '${widget.article.author.isEmpty ? widget.article.source : widget.article.author} • ${widget.article.publishedAt}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: isSmallScreen ? 9.5 : 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            // Action buttons: like, bookmark, share, translate
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Like button
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    widget.liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 19,
                                    color: widget.liked
                                        ? Colors.red
                                        : Colors.black54,
                                  ),
                                  onPressed: widget.onLike,
                                ),
                                const SizedBox(width: 8),
                                // Bookmark button
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    widget.bookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    size: 19,
                                    color: widget.bookmarked
                                        ? Colors.deepPurple
                                        : Colors.black54,
                                  ),
                                  onPressed: widget.onBookmark,
                                ),
                                const SizedBox(width: 8),
                                // Share button
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.share_outlined,
                                    size: 19,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () => SharePlus.instance.share(
                                    ShareParams(
                                      text: '$_title\n\n$_desc\n\n$_body',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Translate button
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  constraints: const BoxConstraints(),
                                  icon: _isTranslating
                                      ? const SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.translate,
                                          size: 19,
                                          color: Colors.black54,
                                        ),
                                  onPressed: _showLangPicker,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// AD SLOT MARKER
// ============================================================

class _AdSlot {
  const _AdSlot();
}

// ============================================================
// AD PAGE
// A rich, responsive sponsored feature page
// ============================================================

class _AdPage extends StatelessWidget {
  final AdvertisementItem? ad;

  const _AdPage({this.ad});

  @override
  Widget build(BuildContext context) {
    final currentAd = ad ?? demoAds[0];
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: const Color(0xFFF3F1EC),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ad Media Header
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: currentAd.imageUrl,
                          height: screenHeight < 680 ? 150 : 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            height: 180,
                            color: Colors.black12,
                            child: const Center(
                              child: Icon(Icons.campaign_outlined, size: 40, color: Colors.black38),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              currentAd.tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ad Body Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentAd.sponsor.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentAd.headline,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: screenHeight < 680 ? 18 : 22,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currentAd.description,
                          style: GoogleFonts.inter(
                            fontSize: screenHeight < 680 ? 11 : 13,
                            height: 1.45,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Opening ${currentAd.sponsor}...'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentAd.ctaText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MAGAZINE FEED CARD
// Spawns randomly between news articles with PDF read & actions
// ============================================================

class _MagazineFeedCard extends StatefulWidget {
  final Magazine magazine;
  final String selectedLanguage;

  const _MagazineFeedCard({
    required this.magazine,
    required this.selectedLanguage,
  });

  @override
  State<_MagazineFeedCard> createState() => _MagazineFeedCardState();
}

class _MagazineFeedCardState extends State<_MagazineFeedCard> {
  final MagazineStore _store = MagazineStore.instance;

  void _openReader() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => MagazineReaderPage(magazine: widget.magazine),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Read "${widget.magazine.title}" on Samayam News!\n${widget.magazine.pdfUrl}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _store.isLiked(widget.magazine.id);
    final isSaved = _store.isSaved(widget.magazine.id);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 680;

    return Container(
      color: const Color(0xFF0F1115),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isSmallScreen ? 10 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top magazine label pill
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5A93B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_stories, size: 13, color: Colors.black),
                        SizedBox(width: 5),
                        Text(
                          'SPECIAL MAGAZINE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.magazine.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 10 : 16),

              // Interactive Magazine cover hero
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _openReader,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 340),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: const Color(0xFFE5A93B).withValues(alpha: 0.12),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: widget.magazine.coverImageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFF22262F),
                                child: const Center(
                                  child: Icon(Icons.picture_as_pdf_rounded,
                                      size: 54, color: Colors.white38),
                                ),
                              ),
                            ),
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.2),
                                    Colors.black.withValues(alpha: 0.85),
                                  ],
                                  stops: const [0.4, 0.7, 1.0],
                                ),
                              ),
                            ),
                            // Bottom tap badge
                            Positioned(
                              bottom: 12,
                              left: 14,
                              right: 14,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.menu_book_rounded,
                                            size: 13, color: Colors.black),
                                        SizedBox(width: 5),
                                        Text(
                                          'TAP TO READ PDF',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${widget.magazine.pageCount} Pages',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 10 : 16),

              // Title & Issue
              Text(
                widget.magazine.issue.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFE5A93B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.magazine.title,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                widget.magazine.subtitle,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isSmallScreen ? 11.5 : 13,
                  height: 1.35,
                ),
                maxLines: isSmallScreen ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: isSmallScreen ? 10 : 16),

              // Bottom action bar: Read PDF button, Like, Bookmark, Share
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _openReader,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text(
                        'Read Magazine',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Like
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      tooltip: 'Like',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isLiked ? Colors.redAccent : Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _store.toggleLike(widget.magazine.id);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Bookmark
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      tooltip: 'Bookmark',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isSaved ? Colors.amber : Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _store.toggleSave(widget.magazine.id);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Share
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      tooltip: 'Share',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                      onPressed: _share,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
