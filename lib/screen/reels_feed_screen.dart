import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:opendoors/Api/reels_api_service.dart';
import 'package:opendoors/Api/nearby_properties_api.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/firebase/chat_screen.dart';
import 'package:opendoors/model/reel.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/model/routes_helper.dart';
import 'package:opendoors/screen/login_screen.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:opendoors/utils/property_share.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:opendoors/utils/fast_spinner.dart';

class ReelsFeedScreen extends StatefulWidget {
  const ReelsFeedScreen({super.key, this.active = true});

  final bool active;

  @override
  State<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends State<ReelsFeedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final ReelsApiService _api = ReelsApiService();
  final List<Reel> _reels = [];
  int _activeIndex = 0;
  int _cursor = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _loadMoreError;
  int _feed = 0;
  double _feedSwipeDistance = 0;
  bool _commentsOpen = false;
  Position? _position;
  Set<String>? _nearbyPropertyIds;
  int _requestVersion = 0;

  // Pre-warm cache: keeps at most 2 initialised controllers so adjacent
  // reels start playing instantly without a network round-trip.
  static final Map<String, VideoPlayerController> _cache = {};

  /// Eagerly initialise [url] in the background and store in [_cache].
  static Future<void> _prewarm(String url) async {
    if (_cache.containsKey(url)) return;
    final c = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );
    _cache[url] = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      // Mute and pause — it's pre-warmed, not playing yet.
      await c.setVolume(0);
    } catch (_) {
      _cache.remove(url);
      await c.dispose();
    }
  }

  /// Pop a pre-warmed controller from cache (transfers ownership to caller).
  static VideoPlayerController? _takeCached(String url) {
    return _cache.remove(url);
  }

  /// Evict stale entries (any URL not in [keep]) to free memory.
  static Future<void> _evictCache(Set<String> keep) async {
    final stale = _cache.keys.where((k) => !keep.contains(k)).toList();
    for (final k in stale) {
      final c = _cache.remove(k);
      await c?.dispose();
    }
  }

  Future<Position> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ReelsApiException(
          'Turn on location services to see nearby reels.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const ReelsApiException(
          'Allow location access to see nearby reels.');
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    ).timeout(const Duration(seconds: 15));
  }

  Future<ReelsPage> _nearby({int cursor = 0}) async {
    final nearbyIds = _nearbyPropertyIds ?? const <String>{};
    if (nearbyIds.isEmpty) {
      return const ReelsPage(reels: [], nextCursor: 0, hasMore: false);
    }
    final found = <Reel>[];
    var nextCursor = cursor;
    var hasMore = true;
    final seenCursors = <int>{};
    while (hasMore && found.length < 10 && seenCursors.add(nextCursor)) {
      final page = await _api.list(cursor: nextCursor);
      found.addAll(page.reels.where(
        (reel) => nearbyIds.contains(reel.propertyId),
      ));
      hasMore = page.hasMore && page.nextCursor != nextCursor;
      nextCursor = page.nextCursor;
    }
    return ReelsPage(reels: found, nextCursor: nextCursor, hasMore: hasMore);
  }

  Future<ReelsPage> _fetch({int cursor = 0}) => switch (_feed) {
        1 => _api.liked(cursor: cursor),
        2 => _api.saved(cursor: cursor),
        3 => _nearby(cursor: cursor),
        _ => _api.list(cursor: cursor),
      };

  void _switchFeed(int feed) {
    if (_feed == feed) return;
    setState(() {
      _feed = feed;
      _commentsOpen = false;
    });
    _loadInitial();
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void didUpdateWidget(covariant ReelsFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active && _feed == 3) {
      _refreshNearbyLocation();
    }
  }

  Future<void> _refreshNearbyLocation() async {
    try {
      final current = await _getLocation();
      if (!mounted || !widget.active || _feed != 3) return;
      final previous = _position;
      if (previous == null ||
          Geolocator.distanceBetween(previous.latitude, previous.longitude,
                  current.latitude, current.longitude) >
              1000) {
        _position = current;
        _loadInitial();
      }
    } catch (_) {
      // Keep the current feed if a location refresh temporarily fails.
    }
  }

  Future<void> _loadInitial() async {
    final version = ++_requestVersion;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _loadMoreError = null;
        _loadingMore = false;
      });
    }
    try {
      if (_feed == 3) {
        _position = await _getLocation();
        final nearbyProperties = await NearbyPropertiesApi().fetch(
          latitude: _position!.latitude,
          longitude: _position!.longitude,
          radiusKm: 15,
          countryId: getData.read('countryId')?.toString(),
        );
        if (!mounted || version != _requestVersion) return;
        _nearbyPropertyIds = nearbyProperties
            .map((property) => property.id)
            .whereType<String>()
            .toSet();
      }
      final page = await _fetch();
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _reels
          ..clear()
          ..addAll(page.reels);
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
        _activeIndex = 0;
        _commentsOpen = false;
      });
    } on ReelsApiException catch (error) {
      if (mounted && version == _requestVersion) {
        setState(() => _error = error.message);
      }
    } catch (error) {
      debugPrint('Nearby reels failed: $error');
      if (mounted && version == _requestVersion) {
        setState(() => _error = _feed == 3
            ? 'Unable to load nearby reels. Check your location and connection, then try again.'
            : 'Unable to load reels. Please try again.');
      }
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final version = _requestVersion;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(cursor: _cursor);
      if (!mounted || version != _requestVersion) return;
      final existingIds = _reels.map((reel) => reel.id).toSet();
      setState(() {
        _loadMoreError = null;
        _reels.addAll(
          page.reels.where((reel) => existingIds.add(reel.id)),
        );
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
      });
    } on ReelsApiException catch (error) {
      if (mounted && version == _requestVersion) {
        setState(() => _loadMoreError = error.message);
      }
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() => _loadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final notifire = Provider.of<ColorNotifire>(context);
    return Scaffold(
      backgroundColor: notifire.getbgcolor,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => _feedSwipeDistance = 0,
        onHorizontalDragUpdate: (details) =>
            _feedSwipeDistance += details.delta.dx,
        onHorizontalDragEnd: (_) {
          if (_commentsOpen) return;
          if (_feedSwipeDistance < -50 && _feed == 0) _switchFeed(3);
          if (_feedSwipeDistance > 50 && _feed == 3) _switchFeed(0);
          _feedSwipeDistance = 0;
        },
        child: Stack(
          children: [
            _buildBody(notifire),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final entry in [(3, 'Nearby'), (0, 'For You')])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: GestureDetector(
                            onTap: () => _switchFeed(entry.$1),
                            child: Text(
                              entry.$2,
                              style: TextStyle(
                                color: _feed == entry.$1
                                    ? Colors.white
                                    : Colors.white70,
                                fontFamily: FontFamily.gilroyBold,
                                fontSize: 16,
                                shadows: const [
                                  Shadow(color: Colors.black87, blurRadius: 6),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorNotifire notifire) {
    if (_loading) {
      return Center(child: FastSpinner(color: Darkblue));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: notifire.getwhiteblackcolor,
                  fontFamily: FontFamily.gilroyMedium,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Darkblue,
                  foregroundColor: WhiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontFamily: FontFamily.gilroyBold),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_reels.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadInitial,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 180),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _feed == 3
                          ? Icons.location_searching_rounded
                          : _feed == 1
                              ? Icons.favorite_border_rounded
                              : _feed == 2
                                  ? Icons.bookmark_border_rounded
                                  : Icons.videocam_off_rounded,
                      size: 52,
                      color: notifire.getgreycolor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _feed == 0
                          ? 'No Reels Yet'
                          : _feed == 1
                              ? 'No Liked Reels'
                              : _feed == 2
                                  ? 'No Saved Reels'
                                  : _hasMore
                                      ? 'Searching Nearby…'
                                      : 'No Nearby Reels Found',
                      style: TextStyle(
                        color: notifire.getwhiteblackcolor,
                        fontFamily: FontFamily.gilroyBold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _feed == 0
                          ? 'Property reels will appear here once listings are added.'
                          : _feed == 1
                              ? 'Reels you like will show up here. Start exploring!'
                              : _feed == 2
                                  ? 'Save reels to revisit them anytime.'
                                  : _hasMore
                                      ? 'We\'re scanning for properties within 15 km of your location.'
                                      : 'No property reels were found within 15 km. Try a different area or browse For You.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: notifire.getgreycolor,
                        fontFamily: FontFamily.gilroyMedium,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (_hasMore && _feed == 3) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadingMore ? null : _loadMore,
                        icon: _loadingMore
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: FastSpinner(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search_rounded, size: 18),
                        label: Text(
                          _loadingMore ? 'Searching…' : 'Search More',
                          style: const TextStyle(
                              fontFamily: FontFamily.gilroyBold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Darkblue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                    if (_loadMoreError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_loadMoreError!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        PageView.builder(
          key: ValueKey(_feed),
          scrollDirection: Axis.vertical,
          physics: _commentsOpen
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          itemCount: _reels.length,
          onPageChanged: (index) {
            setState(() => _activeIndex = index);
            if (index >= _reels.length - 3) _loadMore();
            // Pre-warm the next reel while user is on this one
            final nextUrl =
                index + 1 < _reels.length ? _reels[index + 1].videoUrl : null;
            if (nextUrl != null && nextUrl.isNotEmpty) {
              _prewarm(nextUrl);
            }
            // Evict anything more than 2 slots away
            final keepUrls = <String>{};
            for (int i = (index - 1).clamp(0, _reels.length - 1);
                i <= (index + 2).clamp(0, _reels.length - 1);
                i++) {
              final u = _reels[i].videoUrl;
              if (u != null) keepUrls.add(u);
            }
            _evictCache(keepUrls);
          },
          itemBuilder: (context, index) => ReelPlayerPage(
            key: ValueKey(_reels[index].id),
            reel: _reels[index],
            active: widget.active && index == _activeIndex,
            centerOverlayBottomInset: 80,
            cachedController: _takeCached(_reels[index].videoUrl ?? ''),
            onCommentsChanged: (open) {
              if (mounted && index == _activeIndex) {
                setState(() => _commentsOpen = open);
              }
            },
            onChanged: (reel) {
              if (mounted &&
                  index < _reels.length &&
                  _reels[index].id == reel.id) {
                _reels[index] = reel;
              }
            },
          ),
        ),
        if (_loadMoreError != null)
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Material(
              color: notifire.getblackwhitecolor,
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _loadMoreError!,
                        style: TextStyle(
                          color: notifire.getwhiteblackcolor,
                          fontFamily: FontFamily.gilroyMedium,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadMore,
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Darkblue,
                          fontFamily: FontFamily.gilroyBold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ReelPlayerPage extends StatefulWidget {
  const ReelPlayerPage({
    required this.reel,
    required this.active,
    this.onChanged,
    this.onCommentsChanged,
    this.bottomOverlayInset = 0,
    this.centerOverlayBottomInset = 0,
    this.cachedController,
    super.key,
  });

  final Reel reel;
  final bool active;
  final ValueChanged<Reel>? onChanged;
  final ValueChanged<bool>? onCommentsChanged;
  final double bottomOverlayInset;
  final double centerOverlayBottomInset;

  /// A pre-warmed controller handed over from the parent cache. The widget
  /// takes full ownership (disposes it when done).
  final VideoPlayerController? cachedController;

  @override
  State<ReelPlayerPage> createState() => _ReelPlayerPageState();
}

class _ReelPlayerPageState extends State<ReelPlayerPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const _speeds = <double>[0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];
  VideoPlayerController? _controller;
  late final AnimationController _commentsController;
  late final AnimationController _pulseController;
  final ValueNotifier<double?> _speedHud = ValueNotifier(null);
  late final ValueNotifier<Reel> _displayReel;
  Timer? _speedHudTimer;
  final int _speedIndex = 2;
  bool _commentsOpened = false;
  ReelProperty? _propertyDetails;
  String? _error;
  final ReelsApiService _api = ReelsApiService();
  bool _liking = false, _saving = false, _viewSent = false;
  bool _openingOwnerChat = false;
  bool _descriptionExpanded = false;
  // Long-press speed boost state
  int _savedSpeedIndex = 2;
  bool _isSpeedBoosting = false;
  double? _activeBoostSpeed; // null = no boost, 0.5 = slow, 2.0 = fast
  // Position resume: persisted in a static map so it survives state disposal
  // (e.g. user switches bottom-nav tabs and comes back).
  static final Map<String, Duration> _resumePositions = {};

  Duration? get _savedPosition => _resumePositions[widget.reel.id];
  set _savedPosition(Duration? d) {
    if (d == null || d <= Duration.zero) {
      _resumePositions.remove(widget.reel.id);
    } else {
      _resumePositions[widget.reel.id] = d;
    }
  }

  // Dedicated notifier for play/pause state — updated synchronously on tap
  // so the icon reflects the user's intent instantly, without waiting for
  // the async controller.play() / controller.pause() to settle.
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier(false);

  void _publish(Reel reel) {
    if (!mounted) return;
    _displayReel.value = reel;
    widget.onChanged?.call(reel);
  }

  void _showError(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _openProperty() {
    final propertyId = widget.reel.propertyId;
    if (propertyId.isEmpty) return;
    _controller?.pause();
    _isPlayingNotifier.value = false;
    Get.toNamed(Routes.viewDataScreen, arguments: {'id': propertyId});
  }

  Future<void> _openOwnerChat({
    bool includePropertyContext = false,
    String? propertyMessage,
  }) async {
    if (_openingOwnerChat) return;
    if (getData.read('UserLogin') == null) {
      Get.to(() => LoginScreen());
      return;
    }
    setState(() => _openingOwnerChat = true);
    try {
      var reel = _displayReel.value;
      var property = _property;
      var ownerId = (property?.ownerId ?? reel.ownerId)?.trim();
      if (ownerId == null ||
          ownerId.isEmpty ||
          ownerId == '0' ||
          ownerId == 'null') {
        final details = await _api.propertyDetails(reel.propertyId);
        if (!mounted) return;
        if (details != null) {
          setState(() => _propertyDetails = details);
          _publish(reel.copyWith(
            property: details,
            ownerId: details.ownerId,
            ownerName: details.ownerName,
            ownerImage: details.ownerImage,
          ));
          reel = _displayReel.value;
          property = details;
          ownerId = details.ownerId?.trim();
        }
      }
      if (!mounted) return;
      if (ownerId == null ||
          ownerId.isEmpty ||
          ownerId == '0' ||
          ownerId == 'null') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner chat is unavailable for this reel.'),
          ),
        );
        return;
      }
      _controller?.pause();
      _isPlayingNotifier.value = false;
      Get.to(() => ChatPage(
            resiverUserId: ownerId!,
            resiverUseremail: '',
            proPic: property?.ownerImage ?? reel.ownerImage ?? '',
            propertyTitle: includePropertyContext ? property?.title : null,
            propertyAddress: includePropertyContext ? property?.address : null,
            propertyMessage: includePropertyContext ? propertyMessage : null,
            propertyId: includePropertyContext ? reel.propertyId : null,
          ));
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _openingOwnerChat = false);
    }
  }

  Future<void> _like() async {
    if (_liking) return;
    _liking = true;
    // Optimistic update for instant feedback
    final current = _displayReel.value;
    final optimistic = current.copyWith(
      hasLiked: !current.hasLiked,
      likesCount: current.hasLiked
          ? (current.likesCount - 1).clamp(0, 1 << 31)
          : current.likesCount + 1,
    );
    _publish(optimistic);
    HapticFeedback.lightImpact();
    try {
      final result = await _api.toggleLike(widget.reel.id);
      _publish(_displayReel.value
          .copyWith(hasLiked: result.active, likesCount: result.count));
    } catch (error) {
      _publish(current); // roll back on error
      _showError(error);
    } finally {
      _liking = false;
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    // Optimistic update for instant feedback
    final current = _displayReel.value;
    final optimistic = current.copyWith(
      hasSaved: !current.hasSaved,
      savesCount: current.hasSaved
          ? (current.savesCount - 1).clamp(0, 1 << 31)
          : current.savesCount + 1,
    );
    _publish(optimistic);
    HapticFeedback.lightImpact();
    try {
      final result = await _api.toggleSave(widget.reel.id);
      _publish(_displayReel.value
          .copyWith(hasSaved: result.active, savesCount: result.count));
    } catch (error) {
      _publish(current); // roll back on error
      _showError(error);
    } finally {
      _saving = false;
    }
  }

  Future<void> _addView() async {
    if (_viewSent || !widget.active) return;
    _viewSent = true;
    try {
      final count = await _api.addView(widget.reel.id);
      _publish(_displayReel.value.copyWith(views: count));
    } catch (_) {
      _viewSent = false;
    }
  }

  Future<void> _loadPropertyDetails() async {
    final existing = widget.reel.property;
    if ((existing?.description?.trim().isNotEmpty == true) &&
        (existing?.ownerName?.trim().isNotEmpty == true) &&
        (existing?.ownerId?.trim().isNotEmpty == true ||
            widget.reel.ownerId?.trim().isNotEmpty == true)) {
      return;
    }
    try {
      final details = await _api.propertyDetails(widget.reel.propertyId);
      if (!mounted || details == null) return;
      setState(() => _propertyDetails = details);
      _publish(_displayReel.value.copyWith(
        property: details,
        ownerName: details.ownerName,
        ownerImage: details.ownerImage,
        ownerId: details.ownerId,
      ));
    } catch (_) {
      // The reel remains usable when supplementary property data is unavailable.
    }
  }

  @override
  void initState() {
    super.initState();
    _displayReel = ValueNotifier(widget.reel);
    WidgetsBinding.instance.addObserver(this);
    _commentsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _commentsController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onCommentsChanged?.call(false);
      }
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    // Fire property details immediately in parallel with video init,
    // so description / avatar appear without waiting for the video to load.
    _loadPropertyDetails();
    _initialize();
  }

  Future<void> _initialize() async {
    final url = widget.reel.videoUrl;
    if (url == null || url.isEmpty) {
      setState(() => _error = 'This reel has no video URL.');
      return;
    }

    // Prefer a pre-warmed controller handed from the parent.
    final cached = widget.cachedController;
    if (cached != null && cached.value.isInitialized) {
      _controller = cached;
      _controller!.addListener(_onControllerUpdate);
      // Restore volume (pre-warm muted it)
      await cached.setVolume(1);
      final saved = _savedPosition;
      if (saved != null && saved > Duration.zero) {
        await cached.seekTo(saved);
      }
      if (widget.active) {
        await cached.play();
        _isPlayingNotifier.value = true;
      }
      if (widget.active) _addView();
      if (mounted) setState(() {});
      return;
    }
    // Dispose stale cached controller if not initialised yet.
    cached?.dispose();

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );
    _controller = controller;
    try {
      await controller.initialize();
      controller.addListener(_onControllerUpdate);
      await controller.setLooping(true);
      // Restore saved position (e.g. user navigated away and came back)
      final saved = _savedPosition;
      if (saved != null && saved > Duration.zero) {
        await controller.seekTo(saved);
      }
      if (widget.active) {
        await controller.play();
        _isPlayingNotifier.value = true;
      }
      if (widget.active) _addView();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to play this reel.');
    }
  }

  /// Fired by the VideoPlayerController on every value change (position ticks,
  /// buffering state, errors). Only used to keep _isPlayingNotifier in sync.
  void _onControllerUpdate() {
    final playing = _controller?.value.isPlaying == true;
    if (_isPlayingNotifier.value != playing) {
      _isPlayingNotifier.value = playing;
    }
  }

  @override
  void didUpdateWidget(covariant ReelPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reel != oldWidget.reel) _displayReel.value = widget.reel;
    if (widget.active != oldWidget.active) {
      if (!widget.active) {
        // Save position to static map so it survives state disposal
        final pos = _controller?.value.position;
        if (pos != null && pos > Duration.zero) {
          _savedPosition = pos;
        }
        _controller?.pause();
      } else {
        // Becoming active: seek to saved position then play
        _resumePlayback();
      }
    }
  }

  Future<void> _resumePlayback() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final saved = _savedPosition;
    if (saved != null && saved > Duration.zero) {
      await c.seekTo(saved);
      _savedPosition = null;
    }
    await c.play();
    _isPlayingNotifier.value = true;
    _addView();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      // Save current position to static map so it survives dispose
      final pos = _controller?.value.position;
      if (pos != null && pos > Duration.zero) {
        _savedPosition = pos;
      }
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed && widget.active) {
      _resumePlayback();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speedHudTimer?.cancel();
    _speedHud.dispose();
    _displayReel.dispose();
    _isPlayingNotifier.dispose();
    _commentsController.dispose();
    _pulseController.dispose();
    // Save position before disposal so we can resume if the widget is recreated.
    final pos = _controller?.value.position;
    if (pos != null && pos > Duration.zero) {
      _savedPosition = pos;
    }
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _toggleComments() {
    if (_commentsController.value > 0) {
      _commentsController.reverse();
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      setState(() => _commentsOpened = true);
      widget.onCommentsChanged?.call(true);
      _commentsController.forward();
    }
  }

  // Long-press speed boost: hold top-left to slow, top-right to speed up
  Future<void> _startSpeedBoost(double targetSpeed) async {
    if (_isSpeedBoosting) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    _savedSpeedIndex = _speedIndex;
    _isSpeedBoosting = true;
    _activeBoostSpeed = targetSpeed;
    if (mounted) setState(() {});
    HapticFeedback.mediumImpact();
    try {
      await controller.setPlaybackSpeed(targetSpeed);
      _speedHud.value = targetSpeed;
    } catch (_) {}
  }

  Future<void> _endSpeedBoost() async {
    if (!_isSpeedBoosting) return;
    _isSpeedBoosting = false;
    _activeBoostSpeed = null;
    if (mounted) setState(() {});
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final restoredSpeed = _speeds[_savedSpeedIndex];
    try {
      await controller.setPlaybackSpeed(restoredSpeed);
      _speedHud.value = restoredSpeed;
      _speedHudTimer?.cancel();
      _speedHudTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) _speedHud.value = null;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_commentsController.value > 0) {
          _commentsController.reverse();
          return false;
        }
        return true;
      },
      child: AnimatedBuilder(
        animation: _commentsController,
        child: _buildVideoSurface(),
        builder: (context, videoSurface) => LayoutBuilder(
          builder: (context, constraints) {
            final progress = _commentsController.value;
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            final openSheetHeight = (keyboardInset + 180).clamp(
                constraints.maxHeight * .55, constraints.maxHeight * .85);
            final sheetHeight = openSheetHeight * progress;
            final videoHeight = constraints.maxHeight - sheetHeight;
            final isReady = _controller?.value.isInitialized == true;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: videoHeight,
                  child: ClipRect(
                      child: Stack(fit: StackFit.expand, children: [
                    videoSurface!,
                    _buildActionRail(context, progress),
                    _buildMetadata(context, progress),
                    // Play/pause icon — driven by _isPlayingNotifier so it
                    // updates instantly on tap without waiting for async play/pause.
                    Positioned.fill(
                      top: MediaQuery.paddingOf(context).top,
                      bottom: _navigationTopInset(context) +
                          widget.centerOverlayBottomInset,
                      child: IgnorePointer(
                        child: Center(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _isPlayingNotifier,
                            builder: (_, playing, __) => AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                opacity: anim,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.75, end: 1.0)
                                      .animate(CurvedAnimation(
                                          parent: anim, curve: Curves.easeOut)),
                                  child: child,
                                ),
                              ),
                              child: (!isReady || playing)
                                  ? const SizedBox.shrink(key: ValueKey('none'))
                                  : const Icon(
                                      Icons.play_arrow_rounded,
                                      key: ValueKey('paused'),
                                      color: Color(0xffFF4D00),
                                      size: 72,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isReady)
                      Positioned(
                          left: 0,
                          right: 0,
                          bottom: (_navigationTopInset(context) + 6) *
                              (1 - progress),
                          child: SizedBox(
                            height: 4,
                            child: VideoProgressIndicator(_controller!,
                                allowScrubbing: true,
                                padding: EdgeInsets.zero,
                                colors: VideoProgressColors(
                                  playedColor: Darkblue,
                                  bufferedColor: Colors.white38,
                                  backgroundColor: Colors.white24,
                                )),
                          )),
                    _buildSpeedHud(),
                  ])),
                ),
                if (_commentsOpened)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: videoHeight,
                    height: openSheetHeight,
                    child: Material(
                      elevation: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: IgnorePointer(
                        ignoring: progress == 0,
                        child: ReelCommentsSheet(
                          reelId: widget.reel.id,
                          api: _api,
                          initialCount: _displayReel.value.commentsCount,
                          onClose: _toggleComments,
                          onDragUpdate: (delta) {
                            _commentsController.value -=
                                delta / openSheetHeight;
                          },
                          onDragEnd: (velocity) {
                            if (velocity > 650 ||
                                _commentsController.value < .55) {
                              _commentsController.reverse();
                            } else {
                              _commentsController.forward();
                            }
                          },
                          onCountChanged: (count) => _publish(_displayReel.value
                              .copyWith(commentsCount: count)),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpeedHud() => Positioned.fill(
        child: IgnorePointer(
          child: Stack(
            children: [
              // Pulsating zone indicator when speed boost is active
              if (_activeBoostSpeed != null)
                Positioned(
                  top: 0,
                  left: _activeBoostSpeed! < 1 ? 0 : null,
                  right: _activeBoostSpeed! >= 1 ? 0 : null,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      // _pulseController oscillates 0→1→0 (reverse:true)
                      final t = _pulseController.value;
                      final opacity = 0.15 + t * 0.30;
                      final iconOpacity = 0.65 + t * 0.35;
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: MediaQuery.of(context).size.height * 0.22,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: _activeBoostSpeed! < 1
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            end: _activeBoostSpeed! < 1
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            colors: [
                              (_activeBoostSpeed! < 1
                                      ? Colors.blueAccent
                                      : const Color(0xffFF4D00))
                                  .withValues(alpha: opacity),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomRight: _activeBoostSpeed! < 1
                                ? const Radius.circular(24)
                                : Radius.zero,
                            bottomLeft: _activeBoostSpeed! >= 1
                                ? const Radius.circular(24)
                                : Radius.zero,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                scale: 0.85 + t * 0.2,
                                child: Icon(
                                  _activeBoostSpeed! < 1
                                      ? Icons.fast_rewind_rounded
                                      : Icons.fast_forward_rounded,
                                  color: Colors.white.withValues(alpha: iconOpacity),
                                  size: 32,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _activeBoostSpeed! < 1 ? '0.5×' : '2×',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: iconOpacity),
                                  fontSize: 13,
                                  fontFamily: FontFamily.gilroyBold,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 6,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Central speed HUD badge
              Center(
                child: ValueListenableBuilder<double?>(
                  valueListenable: _speedHud,
                  builder: (_, speed, __) => speed == null
                      ? const SizedBox.shrink()
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('${speed}x',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18)),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildVideoSurface() {
    return LayoutBuilder(builder: (context, constraints) {
      final topZoneHeight = constraints.maxHeight * 0.28;
      final sideZoneWidth = constraints.maxWidth * 0.35;
      return Stack(
        fit: StackFit.expand,
        children: [
          // ── Visual layers (bottom-up) ──────────────────────────────────
          // IMPORTANT: _video() uses FittedBox whose RenderFittedBox.hitTest()
          // returns true for any pointer within its bounds, absorbing ALL taps.
          // All GestureDetectors MUST come after _video() in this list so they
          // sit above it in Z-order and receive hits first.
          _video(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.55, 1],
              ),
            ),
          ),
          // ── Interaction layers (above video, top-down in Z) ────────────
          // Main tap/double-tap — full screen below the top-corner zones.
          Positioned(
            top: topZoneHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () {
                if (!_displayReel.value.hasLiked) _like();
              },
              onTap: () {
                final c = _controller;
                if (c == null) return;
                if (c.value.isPlaying) {
                  c.pause();
                  _isPlayingNotifier.value = false;
                } else {
                  c.play();
                  _isPlayingNotifier.value = true;
                }
              },
            ),
          ),
          // Center top strip — between the two speed-boost corner zones.
          Positioned(
            top: 0,
            left: sideZoneWidth,
            right: sideZoneWidth,
            height: topZoneHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final c = _controller;
                if (c == null) return;
                if (c.value.isPlaying) {
                  c.pause();
                  _isPlayingNotifier.value = false;
                } else {
                  c.play();
                  _isPlayingNotifier.value = true;
                }
              },
            ),
          ),
          // Top-left corner — long-press to slow down.
          Positioned(
            top: 0,
            left: 0,
            width: sideZoneWidth,
            height: topZoneHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPressStart: (_) => _startSpeedBoost(0.5),
              onLongPressEnd: (_) => _endSpeedBoost(),
              onLongPressCancel: () => _endSpeedBoost(),
              onTap: () {
                final c = _controller;
                if (c == null) return;
                if (c.value.isPlaying) {
                  c.pause();
                  _isPlayingNotifier.value = false;
                } else {
                  c.play();
                  _isPlayingNotifier.value = true;
                }
              },
            ),
          ),
          // Top-right corner — long-press to speed up.
          Positioned(
            top: 0,
            right: 0,
            width: sideZoneWidth,
            height: topZoneHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPressStart: (_) => _startSpeedBoost(2.0),
              onLongPressEnd: (_) => _endSpeedBoost(),
              onLongPressCancel: () => _endSpeedBoost(),
              onTap: () {
                final c = _controller;
                if (c == null) return;
                if (c.value.isPlaying) {
                  c.pause();
                  _isPlayingNotifier.value = false;
                } else {
                  c.play();
                  _isPlayingNotifier.value = true;
                }
              },
            ),
          ),
        ],
      );
    });
  }

  double _navigationTopInset(BuildContext context) =>
      widget.bottomOverlayInset + MediaQuery.paddingOf(context).bottom;

  Widget _buildActionRail(BuildContext context, double progress) => Positioned(
        right: 8,
        bottom: _navigationTopInset(context) + 20,
        child: IgnorePointer(
          ignoring: progress >= .5,
          child: Opacity(
            opacity: (1 - progress * 2).clamp(0, 1),
            child: ValueListenableBuilder<Reel>(
                valueListenable: _displayReel,
                builder: (context, reel, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Owner avatar
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Tooltip(
                            message: 'Message property owner',
                            child: InkWell(
                              onTap: _openingOwnerChat
                                  ? null
                                  : () => _openOwnerChat(),
                              customBorder: const CircleBorder(),
                              child: ClipOval(
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: _openingOwnerChat
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : () {
                                          final ownerImage =
                                              _property?.ownerImage ??
                                                  reel.ownerImage;
                                          if (ownerImage != null &&
                                              ownerImage.isNotEmpty) {
                                            final url = ownerImage
                                                    .startsWith('http')
                                                ? ownerImage
                                                : '${Config.imageUrl}$ownerImage';
                                            return Image.network(
                                              url,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Image.asset(
                                                'assets/images/profile-default.png',
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          }
                                          return Image.asset(
                                            'assets/images/profile-default.png',
                                            fit: BoxFit.cover,
                                          );
                                        }(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Like button — uses the same heart style as home screen
                        _ActionButton(
                          icon: reel.hasLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: reel.hasLiked
                              ? const Color(0xffFF4D00)
                              : Colors.white,
                          label: _formatCount(reel.likesCount),
                          onTap: _like,
                          tooltip: 'Like reel',
                        ),
                        const SizedBox(height: 4),
                        // Comment button — uses chat-dots asset like home screen
                        _AssetActionButton(
                          assetPath: 'assets/images/chat-dots.png',
                          label: _formatCount(reel.commentsCount),
                          onTap: _toggleComments,
                          tooltip: 'Comments',
                        ),
                        const SizedBox(height: 4),
                        // Save / bookmark button
                        _ActionButton(
                          icon: reel.hasSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: reel.hasSaved
                              ? const Color(0xffFF4D00)
                              : Colors.white,
                          label: _formatCount(reel.savesCount),
                          onTap: _save,
                          tooltip: 'Save reel',
                        ),
                        const SizedBox(height: 4),
                        // Share button — arrow-up-from-box style
                        _ActionButton(
                          icon: Icons.reply_rounded,
                          color: Colors.white,
                          label: 'Share',
                          onTap: _shareReel,
                          tooltip: 'Share reel',
                          flipHorizontal: true,
                        ),
                        const SizedBox(height: 4),
                        // Views
                        _ActionButton(
                          icon: Icons.play_arrow_rounded,
                          color: Colors.white,
                          label: _formatCount(reel.views),
                          onTap: null,
                          tooltip: 'Views',
                        ),
                      ],
                    )),
          ),
        ),
      );

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  Future<void> _shareReel() async {
    final reel = widget.reel;
    ReelProperty? property = _property;
    if (property?.imageUrl?.trim().isNotEmpty != true) {
      try {
        property = await _api.propertyDetails(reel.propertyId) ?? property;
      } catch (_) {
        // Sharing the reel still works when property details are unavailable.
      }
    }
    if (!mounted) return;
    await PropertyShare.share(
      context: context,
      message:
          'Check out this property on OpenDoors${property?.title?.isNotEmpty == true ? ': ${property!.title}' : ''}',
      subject: property?.title ?? 'OpenDoors reel',
      link: reel.videoUrl,
      propertyImage: property?.imageUrl,
    );
  }

  // Retained for the legacy in-app sharing actions; the reel button now opens
  // the native share sheet directly.
  // ignore: unused_element
  void _showShareSheet(
    BuildContext context,
    String? url,
    String? title,
    ReelProperty? property,
    Reel reel,
  ) {
    if (url == null || url.isEmpty) return;
    // Capture the overlay entry before the sheet opens, so "Share Via" can
    // call Share.share() using the root navigator context — not the sheet ctx
    // that gets torn down on pop.
    final rootCtx = context;
    final isDark = Provider.of<ColorNotifire>(context, listen: false).isDark;
    final bgColor = isDark ? const Color(0xff1A1D21) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xff1A1D21);
    final subTextColor =
        isDark ? const Color(0xffA0A5B4) : const Color(0xff6B7280);
    const accentColor = Color(0xffFF4D00);

    // Compute share position origin before the sheet opens (context is still
    // valid here). iOS requires a non-zero Rect for the UIActivityViewController
    // popover anchor — screen centre satisfies this on both iPhone and iPad.
    final screenSize = MediaQuery.sizeOf(context);
    final shareOrigin = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2),
      width: 1,
      height: 1,
    );

    final shareText = 'Check out this reel on OpenDoors:\n$url';
    final previewUrls = [
      property?.imageUrl,
      reel.thumbnailUrl,
      reel.thumbnailPath,
    ].map(_absoluteMediaUrl).whereType<String>().toSet().toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: subTextColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Share Property',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
                fontFamily: FontFamily.gilroyBold,
              ),
            ),
            if (title != null && title.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: subTextColor,
                  fontFamily: FontFamily.gilroyMedium,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOption(
                  icon: Icons.link_rounded,
                  label: 'Copy Link',
                  color: accentColor,
                  bgColor: accentColor.withValues(alpha: 0.12),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(rootCtx).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.ios_share_rounded,
                  label: 'Share Via…',
                  color: const Color(0xff007AFF),
                  bgColor: const Color(0xff007AFF).withValues(alpha: 0.12),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    // Await dismiss animation so UIKit is free to present
                    // UIActivityViewController without a presentation conflict.
                    await Future.delayed(const Duration(milliseconds: 350));
                    await _shareProperty(
                      text: shareText,
                      subject: 'Check out this reel on OpenDoors',
                      previewUrls: previewUrls,
                      sharePositionOrigin: shareOrigin,
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Message',
                  color: const Color(0xff34C759),
                  bgColor: const Color(0xff34C759).withValues(alpha: 0.12),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _openOwnerChat(
                      includePropertyContext: true,
                      propertyMessage: shareText,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static String? _absoluteMediaUrl(String? value) {
    final path = value?.trim();
    if (path == null || path.isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri?.hasScheme == true) return path;
    return Uri.parse(Config.imageUrl).resolve(path).toString();
  }

  static Future<void> _shareProperty({
    required String text,
    required String subject,
    required Rect sharePositionOrigin,
    required List<String> previewUrls,
  }) async {
    for (final previewUrl in previewUrls) {
      try {
        final response = await http
            .get(Uri.parse(previewUrl))
            .timeout(const Duration(seconds: 10));
        final contentType = response.headers['content-type'] ?? '';
        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            contentType.startsWith('image/') &&
            response.bodyBytes.isNotEmpty) {
          final extension = contentType.contains('png') ? 'png' : 'jpg';
          final preview = File(
            '${Directory.systemTemp.path}/opendoors_share_${DateTime.now().microsecondsSinceEpoch}.$extension',
          );
          await preview.writeAsBytes(response.bodyBytes, flush: true);
          await Share.shareXFiles(
            [XFile(preview.path, mimeType: contentType.split(';').first)],
            text: text,
            subject: subject,
            sharePositionOrigin: sharePositionOrigin,
          );
          return;
        }
      } catch (_) {
        // Try the next available property image or reel thumbnail.
      }
    }

    await Share.share(
      text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Widget _buildMetadata(BuildContext context, double progress) => Positioned(
        left: 16,
        right: 92,
        bottom: _navigationTopInset(context) + 20,
        child: IgnorePointer(
          ignoring: progress >= .5,
          child: Opacity(
            opacity: (1 - progress * 2).clamp(0, 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Property title
                GestureDetector(
                  onTap: _openProperty,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _property?.title ?? 'View property',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xffFF4D00),
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.gilroyBold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    ),
                  ),
                ),
                // Address pill
                if (_property?.address?.trim().isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Color(0xffFF4D00), size: 13),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.52,
                                ),
                                child: Text(
                                  _property!.address!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: FontFamily.gilroyMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Description
                if (_property?.description?.trim().isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final description = _property!.description!.trim();
                        const descriptionStyle = TextStyle(
                          color: Colors.white,
                          height: 1.3,
                          fontSize: 13,
                          fontFamily: FontFamily.gilroyMedium,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4)
                          ],
                        );
                        final measurement = TextPainter(
                          text: const TextSpan(style: descriptionStyle),
                          textDirection: Directionality.of(context),
                          maxLines: 2,
                        )..text = TextSpan(
                            text: description, style: descriptionStyle);
                        measurement.layout(maxWidth: constraints.maxWidth);
                        final canExpand = measurement.didExceedMaxLines;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSize(
                              duration: const Duration(milliseconds: 180),
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                description,
                                maxLines: _descriptionExpanded ? null : 2,
                                overflow: _descriptionExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: descriptionStyle,
                              ),
                            ),
                            if (canExpand)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(() =>
                                    _descriptionExpanded =
                                        !_descriptionExpanded),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Text(
                                    _descriptionExpanded
                                        ? 'See less'
                                        : 'See more',
                                    style: const TextStyle(
                                      color: Color(0xffFF4D00),
                                      fontSize: 12,
                                      fontFamily: FontFamily.gilroyBold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  ReelProperty? get _property => _propertyDetails ?? widget.reel.property;

  Widget _video() {
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white)),
      );
    }
    if (_controller?.value.isInitialized != true) {
      final thumbnail = widget.reel.thumbnailUrl;
      return Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnail != null && thumbnail.isNotEmpty)
            Image.network(thumbnail, fit: BoxFit.cover),
          Center(child: FastSpinner(color: Darkblue)),
        ],
      );
    }
    final size = _controller!.value.size;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}

class ReelCommentsSheet extends StatefulWidget {
  const ReelCommentsSheet(
      {required this.reelId,
      required this.api,
      required this.initialCount,
      required this.onCountChanged,
      this.onClose,
      this.onDragUpdate,
      this.onDragEnd,
      super.key});
  final String reelId;
  final ReelsApiService api;
  final int initialCount;
  final ValueChanged<int> onCountChanged;
  final VoidCallback? onClose;
  final ValueChanged<double>? onDragUpdate;
  final ValueChanged<double>? onDragEnd;

  @override
  State<ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<ReelCommentsSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ReelComment> _comments = [];
  final Set<String> _deletingIds = {};
  int _cursor = 0;
  late final int _baseCount;
  int _countDelta = 0;
  bool _hasMore = true, _loading = false, _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _baseCount = widget.initialCount;
    _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.api.comments(widget.reelId, cursor: _cursor);
      if (!mounted) return;
      setState(() {
        final ids = _comments.map((item) => item.id).toSet();
        _comments.addAll(page.comments.where((item) => ids.add(item.id)));
        _cursor = page.nextCursor;
        _hasMore = page.hasMore && page.nextCursor != 0;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment = await widget.api.addComment(widget.reelId, text);
      if (!mounted) return;
      setState(() {
        if (!_comments.any((item) => item.id == comment.id)) {
          _comments.insert(0, comment);
          _countDelta++;
        }
        _input.clear();
      });
      widget.onCountChanged(_baseCount + _countDelta);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(ReelComment comment) async {
    if (!_deletingIds.add(comment.id)) return;
    try {
      await widget.api.deleteComment(comment.id);
      if (!mounted) return;
      final before = _comments.length;
      setState(() => _comments.removeWhere((item) => item.id == comment.id));
      if (_comments.length == before) return;
      _countDelta--;
      widget.onCountChanged((_baseCount + _countDelta).clamp(0, 1 << 31));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _deletingIds.remove(comment.id);
    }
  }

  Future<void> _confirmDelete(ReelComment comment) async {
    if (_deletingIds.contains(comment.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text(
          'This comment will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _delete(comment);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifire = Provider.of<ColorNotifire>(context);
    final isDark = notifire.isDark;
    final bgColor = isDark ? const Color(0xff1A1D21) : Colors.white;
    final surfaceColor =
        isDark ? const Color(0xff252830) : const Color(0xffF5F5F7);
    final textColor = isDark ? Colors.white : const Color(0xff1A1D21);
    final subTextColor =
        isDark ? const Color(0xffA0A5B4) : const Color(0xff6B7280);
    final dividerColor = isDark ? Colors.white12 : Colors.black12;
    const accentColor = Color(0xffFF4D00);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SizedBox.expand(
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxHeight < 112) return const SizedBox.shrink();
        // ClipRRect ensures the rounded top corners are actually clipped,
        // including the border which was previously overflowing the corners.
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              // Mirror the ClipRRect radius so the background fills to the edge.
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07),
                width: 1,
              ),
            ),
            child: Column(children: [
              // Header with drag handle
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) =>
                    widget.onDragUpdate?.call(details.primaryDelta ?? 0),
                onVerticalDragEnd: (details) =>
                    widget.onDragEnd?.call(details.primaryVelocity ?? 0),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(bottom: BorderSide(color: dividerColor)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Drag handle pill
                      Positioned(
                        top: 10,
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: subTextColor.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          fontFamily: FontFamily.gilroyBold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: widget.onClose,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: subTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontFamily: FontFamily.gilroyMedium,
                    ),
                  ),
                ),
              // Comments list
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is OverscrollNotification &&
                        _scroll.hasClients &&
                        _scroll.offset <= 0 &&
                        notification.overscroll < 0) {
                      widget.onDragUpdate?.call(-notification.overscroll);
                      return true;
                    }
                    if (notification is ScrollEndNotification) {
                      widget.onDragEnd?.call(0);
                    }
                    return false;
                  },
                  child: _comments.isEmpty
                      ? Center(
                          child: _loading
                              ? const FastSpinner(color: accentColor)
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 48,
                                      color: subTextColor.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No comments yet',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 15,
                                        fontFamily: FontFamily.gilroyMedium,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Be the first to comment!',
                                      style: TextStyle(
                                        color: subTextColor.withValues(alpha: 0.6),
                                        fontSize: 13,
                                        fontFamily: FontFamily.gilroyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _comments.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _comments.length) {
                              return _hasMore
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Center(
                                        child: _loading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: FastSpinner(
                                                  strokeWidth: 2,
                                                  color: accentColor,
                                                ),
                                              )
                                            : TextButton(
                                                onPressed: _load,
                                                style: TextButton.styleFrom(
                                                  foregroundColor: accentColor,
                                                ),
                                                child: const Text('Load more'),
                                              ),
                                      ),
                                    )
                                  : const SizedBox(height: 8);
                            }
                            final comment = _comments[index];
                            // Resolve avatar: prefer network image, else initial.
                            final picUrl = comment.userPic?.trim();
                            final hasNetworkPic =
                                picUrl != null && picUrl.isNotEmpty;
                            final avatarUrl = hasNetworkPic
                                ? (picUrl.startsWith('http')
                                    ? picUrl
                                    : '${Config.imageUrl}$picUrl')
                                : null;
                            return Padding(
                              key: ValueKey(comment.id),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar on the LEFT of the comment
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        accentColor.withValues(alpha: 0.15),
                                    // Always use backgroundImage only — no child text
                                    // so the placeholder image is fully visible
                                    // (a child renders on top of backgroundImage).
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : const AssetImage(
                                                'assets/images/profile-default.png')
                                            as ImageProvider,
                                    onBackgroundImageError:
                                        avatarUrl != null ? (_, __) {} : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment.userName,
                                          style: TextStyle(
                                            color: textColor,
                                            fontFamily: FontFamily.gilroyBold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          comment.text,
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 14,
                                            fontFamily: FontFamily.gilroyMedium,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (getData
                                          .read('UserLogin')?['id']
                                          ?.toString() ==
                                      comment.userId)
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 20),
                                      color: subTextColor,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _confirmDelete(comment),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              // Comment Input — always pinned above keyboard
              AnimatedPadding(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(top: BorderSide(color: dividerColor)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Current user's avatar — load from stored profile data.
                        Builder(builder: (context) {
                          final userPic = getData
                                  .read('UserLogin')?['pro_pic']
                                  ?.toString()
                                  .trim() ??
                              '';
                          final hasNetworkPic = userPic.isNotEmpty &&
                              userPic != 'null' &&
                              userPic != 'undefined';
                          final avatarUrl = hasNetworkPic
                              ? (userPic.startsWith('http')
                                  ? userPic
                                  : '${Config.imageUrl}$userPic')
                              : null;
                          return CircleAvatar(
                            radius: 18,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : const AssetImage(
                                        'assets/images/profile-default.png')
                                    as ImageProvider,
                          );
                        }),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 120),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(22),
                              border:
                                  Border.all(color: dividerColor, width: 1.2),
                            ),
                            child: TextField(
                              controller: _input,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontFamily: FontFamily.gilroyMedium,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add a comment…',
                                hintStyle: TextStyle(
                                  color: subTextColor,
                                  fontSize: 14,
                                  fontFamily: FontFamily.gilroyMedium,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 11,
                                ),
                              ),
                              textInputAction: TextInputAction.newline,
                              keyboardAppearance:
                                  isDark ? Brightness.dark : Brightness.light,
                              maxLines: null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sending ? null : _submit,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _sending
                                  ? accentColor.withValues(alpha: 0.5)
                                  : accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _sending
                                ? const Padding(
                                    padding: EdgeInsets.all(11),
                                    child: FastSpinner(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }
}

/// Image-asset based action button for the reel side rail (e.g. chat-dots).
class _AssetActionButton extends StatefulWidget {
  const _AssetActionButton({
    required this.assetPath,
    required this.label,
    required this.onTap,
    required this.tooltip,
  });

  final String assetPath;
  final String label;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  State<_AssetActionButton> createState() => _AssetActionButtonState();
}

class _AssetActionButtonState extends State<_AssetActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.82,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (widget.onTap != null) _scale.reverse();
        },
        onTapUp: (_) {
          _scale.forward();
          widget.onTap?.call();
        },
        onTapCancel: () => _scale.forward(),
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                widget.assetPath,
                width: 30,
                height: 30,
                color: Colors.white,
              ),
              const SizedBox(height: 5),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: FontFamily.gilroyBold,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern icon + label action button for the reel side rail.
/// Uses a tap-scale animation and a soft glow shadow — no opaque container.
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    required this.tooltip,
    this.flipHorizontal = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  final String tooltip;
  final bool flipHorizontal;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.82,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scale;
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onTap != null) _scale.reverse();
  }

  void _onTapUp(_) {
    _scale.forward();
    widget.onTap?.call();
  }

  void _onTapCancel() => _scale.forward();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform(
                alignment: Alignment.center,
                transform: widget.flipHorizontal
                    ? (Matrix4.identity()..scale(-1.0, 1.0, 1.0))
                    : Matrix4.identity(),
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color,
                      widget.color.withValues(alpha: 0.75),
                    ],
                  ).createShader(bounds),
                  child: Icon(
                    widget.icon,
                    size: 30,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: widget.color == Colors.white
                            ? Colors.black45
                            : widget.color.withValues(alpha: 0.6),
                        blurRadius: 12,
                      ),
                      const Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: FontFamily.gilroyBold,
                  shadows: [
                    Shadow(color: Colors.black87, blurRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Share option tile used in the share bottom sheet.
class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontFamily: FontFamily.gilroyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
