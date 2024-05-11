
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
class RouteData {
  final List<osm.GeoPoint> allPoints;
  final List<osm.GeoPoint> routePoints;
  final double totalDistance;
  final double totalDuration;
  final String? routeId;


  RouteData({
    required this.allPoints,
    required this.routePoints,
    required this.totalDistance,
    required this.totalDuration,
    required this.routeId,

  });
}