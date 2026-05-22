import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_point.dart';

class RouteMap extends StatefulWidget {
  const RouteMap({
    super.key,
    required this.routePoints,
    this.followUser = true,
    this.polylineColor = Colors.deepOrange,
    this.showStartEndMarkers = false,
  });

  final List<RoutePoint> routePoints;
  final bool followUser;
  final Color polylineColor;
  final bool showStartEndMarkers;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  final MapController _mapController = MapController();
  bool _hasCenteredOnce = false;

  // Throttle: only redraw the polyline every N updates.
  // GPS arrives every ~5m of movement, so updating every 3rd point ≈ every 15m.
  static const int _polylineUpdateEvery = 3;

  // Cached list — only rebuilt when we cross the throttle threshold.
  List<LatLng> _cachedLatLngs = const [];
  int _lastBuildLength = 0;

  @override
  void initState() {
    super.initState();
    _rebuildCache();
  }

  @override
  void didUpdateWidget(covariant RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newLen = widget.routePoints.length;
    final oldLen = oldWidget.routePoints.length;

    // Move map to latest point on every update (camera follow is cheap).
    if (widget.followUser && newLen > 0 && newLen != oldLen) {
      final latest = widget.routePoints.last;
      _safeMove(LatLng(latest.latitude, latest.longitude));
    }

    // Only rebuild the polyline cache every N points, or when finishing
    // (followUser flips off → make sure final shape is correct).
    final crossedThreshold =
        (newLen - _lastBuildLength) >= _polylineUpdateEvery;
    final followToggledOff = oldWidget.followUser && !widget.followUser;

    if (crossedThreshold || followToggledOff || newLen < oldLen) {
      _rebuildCache();
    }
  }

  void _rebuildCache() {
    _cachedLatLngs = widget.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);
    _lastBuildLength = widget.routePoints.length;
  }

  void _safeMove(LatLng target, {double? zoom}) {
    try {
      _mapController.move(target, zoom ?? _mapController.camera.zoom);
    } catch (_) {
      // Map not ready yet — ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always include the latest point at the end of the rendered polyline
    // so the live cursor and the line stay visually connected, even
    // between cache rebuilds.
    final List<LatLng> renderLatLngs = _cachedLatLngs.isNotEmpty &&
        widget.routePoints.isNotEmpty &&
        _lastBuildLength != widget.routePoints.length
        ? [..._cachedLatLngs, _latestLatLng()!]
        : _cachedLatLngs;

    final initialCenter = renderLatLngs.isNotEmpty
        ? renderLatLngs.first
        : const LatLng(41.9981, 21.4254);

    if (!_hasCenteredOnce && renderLatLngs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _safeMove(renderLatLngs.first, zoom: 16);
        _hasCenteredOnce = true;
      });
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.fitness_app',
          maxZoom: 19,
          // Cache tiles in memory to avoid re-downloading on every redraw.
          tileProvider: NetworkTileProvider(),
        ),
        if (renderLatLngs.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: renderLatLngs,
                strokeWidth: 5,
                color: widget.polylineColor,
              ),
            ],
          ),
        if (widget.showStartEndMarkers && renderLatLngs.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: renderLatLngs.first,
                width: 32,
                height: 32,
                child: const _MarkerDot(color: Colors.green),
              ),
              if (renderLatLngs.length > 1)
                Marker(
                  point: renderLatLngs.last,
                  width: 32,
                  height: 32,
                  child: const _MarkerDot(color: Colors.red),
                ),
            ],
          ),
        if (!widget.showStartEndMarkers && renderLatLngs.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: renderLatLngs.last,
                width: 24,
                height: 24,
                child: const _PulsingDot(),
              ),
            ],
          ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  LatLng? _latestLatLng() {
    if (widget.routePoints.isEmpty) return null;
    final p = widget.routePoints.last;
    return LatLng(p.latitude, p.longitude);
  }
}


class _MarkerDot extends StatelessWidget {
  const _MarkerDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.withValues(alpha: 0.3 + 0.4 * _ctrl.value),
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}