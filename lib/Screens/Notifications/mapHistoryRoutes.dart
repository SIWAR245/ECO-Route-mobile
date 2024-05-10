import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../Common_widgets/CustomTextRich.dart';
import '../../Common_widgets/MapButtons.dart';

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



  double _distance = 0.0;
  double _duration = 0.0;
  bool _mapLoaded = false;
  bool _expandableContainerVisible = false;
  bool _showUserLocation = false;
  bool _isExpanded = false;
  bool _isPinned = false;
  bool firstBinFound = false;
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
    List<Map<String, dynamic>>.from(snapshot.get('initialPoints'));

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
  void _handleVerticalDragUpdate(details) {
    if (details.delta.dy > 10) _toggleExpansion();
  }
  void _handleVerticalDragEnd(details) {
    if (_isExpanded && details.velocity.pixelsPerSecond.dy > 100) {
      _toggleExpansion();
    } else if (!_isExpanded && details.velocity.pixelsPerSecond.dy < -100) {
      _toggleExpansion();
    }
  }
  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
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
          osmOption: osm.OSMOption(
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

  Widget _buildExpandableContainer() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      top: _isExpanded ? 0 : MediaQuery.of(context).size.height - 120,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          height: _isExpanded ? MediaQuery.of(context).size.height : 870,
          child: _isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 30, left: 16, bottom: 10),
          child: CustomTextRich(
            duration: _duration,
            distance: _distance,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(width: 1.0, color: Colors.grey.shade200)),
              ),
            ),
          ),
        ), // Check _isPinned flag here
        Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: _buildMapButtons(),
        ),
      ],
    );
  }

  Widget _buildMapButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _isPinned
          ? [
        MapButton(
          text: "My Location",
          icon: Icons.location_on_outlined,
          iconColor: Colors.white,
          backgroundColor: Colors.teal,
          textColor: Colors.white,
          onPressed: () {
            _toggleUserLocation();
            setState(() {
              _isExpanded = false;
            });
          },
        ),
        MapButton(
          text: " Steps   ",
          icon: Icons.list,
          iconColor: Colors.teal,
          backgroundColor: Colors.white,
          textColor: Colors.teal,
          onPressed: () {
            setState(() {
              _isExpanded = true;
              _isPinned = false; // Set the _isPinned flag to false when the button is pressed
            });

          },
        ),
        MapButton(
          text: "Show Map",
          icon: Icons.map_outlined,
          iconColor: Colors.teal,
          backgroundColor: Colors.white,
          textColor: Colors.teal,
          onPressed: () {
            setState(() {
              _isExpanded = false;
            });

          },
        ),

      ]
          : [
        MapButton(
          text: "My Location",
          icon: Icons.location_on_outlined,
          iconColor: Colors.white,
          backgroundColor: Colors.teal,
          textColor: Colors.white,
          onPressed: () {
            _toggleUserLocation();
            setState(() {
              _isExpanded = false;
            });
          },
        ),
        MapButton(
          text: "Show Map",
          icon: Icons.map_outlined,
          iconColor: Colors.teal,
          backgroundColor: Colors.white,
          textColor: Colors.teal,
          onPressed: () {
            setState(() {
              _isExpanded = false;
            });

          },
        ),
        MapButton(
          text: "All Bins ",
          icon: Icons.delete_outline,
          iconColor: Colors.teal,
          backgroundColor: Colors.white,
          textColor: Colors.teal,
          onPressed: () {
            setState(() {
              _isExpanded = true;
              _isPinned = true; // Set the _isPinned flag to true when the button is pressed
            });

          },
        ),
      ],
    );
  }

  Widget _buildCollapsedContent() {
    return Stack(
      children: [
        Positioned(
          top: 20,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextRich(
                duration: _duration,
                distance: _distance,
              ),
              _buildCollapsedButtons(),
            ],
          ),
        ),

        Positioned(
          top: 50,
          left: 16,
          child: _isExpanded ? Text('ss', style: TextStyle(fontSize: 17, fontWeight: FontWeight.normal, color: Colors.black)) : SizedBox.shrink(),
        ),
        Positioned(
          top: 0,
          left: MediaQuery.of(context).size.width / 2 - 10,
          child: Icon(Icons.remove, color: Colors.grey, size: 30),
        ),
      ],
    );
  }

  Widget _buildCollapsedButtons(){
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Row(
        children: [
          _buildStepsButton(),
          SizedBox(width: 10),
        ],
      ),
    );
  }


  Widget _buildStepsButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _isExpanded = true;
          _isPinned = false; // Set the _isPinned flag to false when the button is pressed
        });
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 22),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.teal, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.list, color: Colors.teal),
          SizedBox(width: 5),
          Text("Steps", style: TextStyle(color: Colors.teal)),
        ],
      ),
    );
  }



}
