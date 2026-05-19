import 'package:cloud_firestore/cloud_firestore.dart';

class RoutePoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime timestamp;
  final double? speedMps;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.timestamp,
    this.speedMps,
  });

  Map<String, dynamic> toMap() => {
    'lat': latitude,
    'lng': longitude,
    'alt': altitude,
    'ts': Timestamp.fromDate(timestamp),
    'speed': speedMps,
  };

  factory RoutePoint.fromMap(Map<String, dynamic> map) => RoutePoint(
    latitude: (map['lat'] as num).toDouble(),
    longitude: (map['lng'] as num).toDouble(),
    altitude: (map['alt'] as num?)?.toDouble(),
    timestamp: (map['ts'] as Timestamp).toDate(),
    speedMps: (map['speed'] as num?)?.toDouble(),
  );
}