import 'package:geolocator/geolocator.dart';

import '../models/route_point.dart';

class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException(this.message);
  @override
  String toString() => message;
}

class LocationService {
  /// Check and request location permission. Throws if the user denies.
  Future<void> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationPermissionDeniedException(
          'Location services are disabled. Please enable them in settings.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationPermissionDeniedException(
          'Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException(
          'Location permission is permanently denied. Enable it in app settings.');
    }
  }

  /// One-shot current position — used to center the map before tracking starts.
  Future<RoutePoint> getCurrentPosition() async {
    await ensurePermission();
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return _toRoutePoint(pos);
  }

  /// Stream of GPS updates with sane filtering.
  /// Emits a new point only when the user has moved at least [distanceFilter] metres.
  Stream<RoutePoint> trackPosition({int distanceFilter = 5}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilter,
      ),
    ).map(_toRoutePoint);
  }

  /// Total distance (metres) of a polyline of route points.
  static double calculateDistanceMeters(List<RoutePoint> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += Geolocator.distanceBetween(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    return total;
  }

  RoutePoint _toRoutePoint(Position pos) => RoutePoint(
    latitude: pos.latitude,
    longitude: pos.longitude,
    altitude: pos.altitude,
    timestamp: pos.timestamp ?? DateTime.now(),
    speedMps: pos.speed,
  );
}