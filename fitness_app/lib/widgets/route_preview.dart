import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_point.dart';

class RoutePreview extends StatelessWidget {
  const RoutePreview({
    super.key,
    required this.points,
    this.height = 120,
  });

  final List<RoutePoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return _Placeholder(height: height);
    }

    final latLngs = points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final firstLat = latLngs.first.latitude;
    final firstLng = latLngs.first.longitude;
    final allSame = latLngs.every(
          (p) => p.latitude == firstLat && p.longitude == firstLng,
    );
    if (allSame) {
      return _Placeholder(height: height);
    }

    double minLat = latLngs.first.latitude;
    double maxLat = latLngs.first.latitude;
    double minLng = latLngs.first.longitude;
    double maxLng = latLngs.first.longitude;
    for (final p in latLngs) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final hasNaN = [minLat, maxLat, minLng, maxLng].any(
          (v) => v.isNaN || v.isInfinite,
    );
    if (hasNaN) {
      return _Placeholder(height: height);
    }

    const pad = 0.0005;
    final bounds = LatLngBounds(
      LatLng(minLat - pad, minLng - pad),
      LatLng(maxLat + pad, maxLng + pad),
    );

    return SizedBox(
      height: height,
      child: AbsorbPointer(
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(20),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.fitness_app',
              maxZoom: 19,
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: latLngs,
                  strokeWidth: 4,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined,
                color: Colors.grey.shade400, size: 32),
            const SizedBox(height: 4),
            Text(
              'No route data',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}