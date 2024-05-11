import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

import 'dart:math';

class MapUtils {
  late MapController _mapController;

  // Constructor
  MapUtils(this._mapController);

  void zoomIn() async {
    await _mapController.zoomIn();
  }

  void zoomOut() async {
    await _mapController.zoomOut();
  }

  void toggleUserLocation(bool _showUserLocation) async {
    if (_showUserLocation) {
      await _mapController.enableTracking();
      await _mapController.setZoom(zoomLevel: 19);
      GeoPoint userLocation = await _mapController.myLocation();
      await _mapController.addMarker(
        userLocation,
        markerIcon: MarkerIcon(
          icon: Icon(
            Icons.location_on_sharp, // You can use a different icon here if needed
            color: Colors.red[400], // Adjust color as needed
            size: 25,
          ),
        ),
      );
    } else {
      await _mapController.disabledTracking();
    }
  }



  static double calculateDistance(double startLat, double startLon, double endLat, double endLon) {
    const double pi = 3.1415926535897932;
    const double radius = 6371.0; // Earth radius in kilometers

    double lat1 = startLat * pi / 180.0;
    double lon1 = startLon * pi / 180.0;
    double lat2 = endLat * pi / 180.0;
    double lon2 = endLon * pi / 180.0;

    double dlon = lon2 - lon1;
    double dlat = lat2 - lat1;

    double a = pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radius * c; // Distance in kilometers
  }

  static Future<void> drawRoute(
      MapController mapController,
      List<GeoPoint> routePoints,
      Function(double distance, int duration) onRouteDrawn,
      ) async {
    if (routePoints.isEmpty) {
      print("Error: Route points list is empty.");
      return;
    }

    // Extract start and destination points
    GeoPoint start = routePoints.first;
    GeoPoint destination = routePoints.last;

    // Extract intermediate points (bins)
    List<GeoPoint> intermediatePoints = routePoints.sublist(1, routePoints.length - 1);

    // Draw the route using the provided route points
    List<RoadInfo> roads = [];

    // Draw the route from start to first bin
    roads.add(await mapController.drawRoad(start, intermediatePoints.first,
        roadType: RoadType.car,
        roadOption: RoadOption(
          roadWidth: 20, // Set the width of the polyline
          roadColor: Colors.blue[400]!,
          zoomInto: false, // No need to zoom into the route for intermediate segments
        )));

    // Draw the route between bins
    for (int i = 0; i < intermediatePoints.length - 1; i++) {
      roads.add(await mapController.drawRoad(intermediatePoints[i], intermediatePoints[i + 1],
          roadType: RoadType.car,
          roadOption: RoadOption(
            roadWidth: 20, // Set the width of the polyline
            roadColor: Colors.blue[400]!,
            zoomInto: false, // No need to zoom into the route for intermediate segments
          )));
    }

    // Draw the route from last bin to destination
    roads.add(await mapController.drawRoad(intermediatePoints.last, destination,
        roadType: RoadType.car,
        roadOption: RoadOption(
          roadWidth: 20, // Set the width of the polyline
          roadColor: Colors.blue[400]!,
          zoomInto: true, // Zoom into the route for the last segment
        )));

    // Calculate total duration and distance
    double totalDuration = 0;
    double totalDistance = 0;

    for (var road in roads) {
      if (road.duration != null) {
        totalDuration += road.duration!;
      }
      if (road.distance != null) {
        totalDistance += road.distance!;
      }
    }

    // Convert duration from seconds to minutes
    int durationInMinutes = (totalDuration / 60).round();

    // Call the callback function with the calculated distance and duration
    onRouteDrawn(totalDistance, durationInMinutes);
  }



}