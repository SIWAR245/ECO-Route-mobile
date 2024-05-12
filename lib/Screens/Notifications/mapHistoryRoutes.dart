import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class MapHistory extends StatefulWidget {
  final String routeId;

  MapHistory({Key? key, required this.routeId}) : super(key: key);

  @override
  _MapHistoryState createState() => _MapHistoryState();
}

class _MapHistoryState extends State<MapHistory> with SingleTickerProviderStateMixin {
  late osm.MapController _mapController;
  late AnimationController _routeController;
  late Timer _timer;



  bool _showUserLocation = false;
  bool _isExpanded = false;
  double _currentRotationAngle = 0.0;
  osm.GeoPoint? userLocation;



  Future<void> _drawRoute(String routeId) async {
    try {
      // Fetch route points from the database based on the routeId
      List<osm.GeoPoint> routePoints = await fetchRoutePoints(routeId);

      if (routePoints.length < 2) {
        print("Error: Route must have at least two points.");
        return;
      }

      print("Start drawing route...");

      // Extract start and destination points
      osm.GeoPoint start = routePoints.first;
      osm.GeoPoint destination = routePoints.last;

      // Extract intermediate points (bins)
      List<osm.GeoPoint> intermediatePoints =
      routePoints.sublist(1, routePoints.length - 1);
      print("Intermediate points: $intermediatePoints");

      // Draw the route using the provided route points
      List<osm.RoadInfo> roads = [];

      // Draw the route from start to first bin if there are intermediate points
      if (intermediatePoints.isNotEmpty) {
        print("Drawing route from start to first bin...");
        roads.add(await _mapController.drawRoad(
          start,
          intermediatePoints.first,
          roadType: osm.RoadType.car,
          roadOption: osm.RoadOption(
            roadWidth: 20, // Set the width of the polyline
            roadColor: Colors.blue[400]!,
            zoomInto: false, // No need to zoom into the route for intermediate segments
          ),
        ));
      }

      // Draw the route between bins
      List<osm.GeoPoint> filteredIntermediatePoints = intermediatePoints.toSet().toList(); // Remove duplicates
      for (int i = 0; i < filteredIntermediatePoints.length - 1; i++) {
        print("Drawing route between bins ${i + 1} and ${i + 2}...");

        roads.add(await _mapController.drawRoad(
          filteredIntermediatePoints[i],
          filteredIntermediatePoints[i + 1],
          roadType: osm.RoadType.car,
          roadOption: osm.RoadOption(
            roadWidth: 20, // Set the width of the polyline
            roadColor: Colors.blue[400]!,
            zoomInto: false, // No need to zoom into the route for intermediate segments
          ),
        ));
      }


      // Draw the route from last bin to destination if there are intermediate points
      if (intermediatePoints.isNotEmpty) {
        print("Drawing route from last bin to destination...");
        roads.add(await _mapController.drawRoad(
          intermediatePoints.last,
          destination,
          roadType: osm.RoadType.car,
          roadOption: osm.RoadOption(
            roadWidth: 20, // Set the width of the polyline
            roadColor: Colors.blue[400]!,
            zoomInto: true, // Zoom into the route for the last segment
          ),
        ));
      } else {
        // Draw the route directly from start to destination if there are no intermediate points
        print("Drawing direct route from start to destination...");
        roads.add(await _mapController.drawRoad(
          start,
          destination,
          roadType: osm.RoadType.car,
          roadOption: osm.RoadOption(
            roadWidth: 20, // Set the width of the polyline
            roadColor: Colors.blue[400]!,
            zoomInto: true, // Zoom into the route for the direct segment
          ),
        ));
      }


      // Optionally, you can print some information about the route
      print("Route drawing completed.");
    } catch (error) {
      print("Error while drawing route: $error");
    }
  }
  Future<List<osm.GeoPoint>> fetchRoutePoints(String routeId) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Query the document with the given routeId from the 'routes' collection
    DocumentSnapshot snapshot =
    await firestore.collection('routes').doc(routeId).get();

    // Check if the document exists
    if (!snapshot.exists) {
      print("Error: Document not found for routeId: $routeId");
      return [];
    }

    // Extract the 'allPoints' field from the document
    List<Map<String, dynamic>> allPointsData =
    List<Map<String, dynamic>>.from(snapshot.get('routePoints'));

    // Convert the 'allPoints' data to a list of GeoPoint
    List<osm.GeoPoint> routePoints = allPointsData.map((pointData) {
      double latitude = pointData['latitude'];
      double longitude = pointData['longitude'];
      return osm.GeoPoint(latitude: latitude, longitude: longitude);
    }).toList();

    return routePoints;
  } catch (error) {
    print("Error fetching route points: $error");
    return [];
  }
}


  void _toggleUserLocation() async {
  setState(() {
    _showUserLocation = !_showUserLocation;
  });

  if (_showUserLocation) {
    PermissionStatus permissionStatus = await Permission.location.request();
    if (permissionStatus == PermissionStatus.granted) {
      await _mapController.enableTracking();
      await _mapController.setZoom(zoomLevel: 19);
      osm.GeoPoint? userLocation = await _mapController.myLocation();
      if (userLocation != null) {
        await _mapController.addMarker(
          userLocation,
          markerIcon: osm.MarkerIcon(
            icon: Icon(
              Icons.location_on_sharp,
              color: Colors.red[400],
              size: 25,
            ),
          ),
        );
      } else {
        print("User location is not available.");
      }
    } else {
      print("Location permission not granted.");
    }
  } else {
    await _mapController.disabledTracking();
  }
}
  void _zoomIn() async {
    await _mapController.zoomIn();
  }
  void _zoomOut() async {
    await _mapController.zoomOut();
  }
  void rotateMap(osm.MapController controller) {
    // Increment the current rotation angle by 90 degrees
    _currentRotationAngle += 30.0;
    // Call the rotateMapCamera method with the updated rotation angle
    controller.rotateMapCamera(_currentRotationAngle);
  }


  @override
  void initState() {
  super.initState();
  _mapController = osm.MapController(
    initPosition: osm.GeoPoint(latitude: 47.4358055, longitude: 8.4737324),
    areaLimit: osm.BoundingBox(
      east: 10.4922941,
      north: 47.8084648,
      south: 45.817995,
      west: 5.9559113,
    ),
  );
  _routeController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    // Perform periodic tasks here
  });

  _drawRoute(widget.routeId);

}

  @override
  void dispose() {
  _routeController.dispose();
  _timer.cancel();
  super.dispose();
}


  @override
  Widget build(BuildContext context) {
  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: _isExpanded ? null : _buildAppBar(),
    body: Stack(
      children: [
        osm.OSMFlutter(
          controller: _mapController,
          osmOption: const osm.OSMOption(
            zoomOption: osm.ZoomOption(
              initZoom: 3,
              minZoomLevel: 3,
              maxZoomLevel: 19,
              stepZoom: 1.0,
            ),
          ),
        ),
          // Only render these widgets if the map is fully loaded
          _buildFloatingButtons(),
      ],
    ),
  );
}


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
  Widget _buildFloatingButtons() {
    return Positioned(
      top: 90,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'fab1',
            onPressed: _toggleUserLocation,
            mini: true,
            backgroundColor: Colors.white70,
            child: Icon(Icons.my_location, color: Colors.teal),
          ),
          SizedBox(height: 5),
          FloatingActionButton(
            heroTag: 'fab2',
            onPressed: _zoomIn,
            mini: true,
            backgroundColor: Colors.white70,
            child: Icon(Icons.add, color: Colors.teal),
          ),
          SizedBox(height: 5),
          FloatingActionButton(
            heroTag: 'fab3',
            onPressed: _zoomOut,
            mini: true,
            backgroundColor: Colors.white70,
            child: Icon(Icons.remove, color: Colors.teal),
          ),
          SizedBox(height: 5),
          FloatingActionButton(
            heroTag: 'fab6',
            onPressed: () {
              rotateMap(_mapController);
            },
            mini: true,
            backgroundColor: Colors.white70,
            child: Icon(Icons.rotate_right, color: Colors.teal),
          ),
        ],
      ),
    );
  }




}
