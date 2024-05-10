import 'package:flutter/material.dart';
import '../../Common_widgets/MapButtons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Common_widgets/CustomTextRich.dart';
import 'package:flutter/animation.dart';
import 'package:intl/intl.dart';

import './RouteDataClass.dart';
import './BinInfoClass.dart';

import 'dart:math';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;


class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class Notification {
  final String type;
  final String routeId;
  final String userUID;


  Notification({
    required this.type,
    required this.routeId,
    required this.userUID,
  });
}


class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  late osm.MapController _mapController;
  late AnimationController _routeController;
  late Timer _timer;

  bool _expandableContainerVisible = false;
  bool _isLoading = false;
  bool _mapLoaded = false;
  bool _showUserLocation = false;
  bool _isExpanded = false;
  bool _isPinned = false;
  bool _isSimulationPaused = false;
  Completer<void> _resumeCompleter = Completer<void>();
  bool _dialogDismissed = false;
  bool _dialogShown = false;
  bool firstBinFound = false;
  bool _routeCreated = false;
  bool _routeGenerated = false;


  osm.GeoPoint? userLocation;

  List<osm.GeoPoint> routePoints = [];
  List<firestore.GeoPoint> Locations = [];
  List<BinInfo> allBins = [];
  List<int> bestRoute = [];
  List<osm.GeoPoint> _generatedRoutePoints = [];
  List<osm.GeoPoint> _allpoints=[];


  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _userMunicipality = '';
  String _userGovernorate = '';
  double _distance = 0.0;
  double _duration = 0.0;
  double _fuelConsumption=0.0;
  String _instructions = '';
  String _routeId='';

// ACO Parameters
  static const int nAnts = 50;  // Number of ants simulating path exploration
  static const int nIterations = 50;  // Number of iterations for the ACO algorithm
  static const double alpha = 0.01;  // Pheromone influence factor (higher alpha -> more emphasis on past pheromone trails)
  static const double beta = 0.2;  // Distance influence factor (higher beta -> more emphasis on shorter distances)
  static const double weight1 = 0.8; // Adjusts the importance of filling level (higher weight1 -> more emphasis on high-fill bins)
  static const double weight2 = 0.2; // Adjusts the importance of distance (higher weight2 -> more emphasis on shorter distances between bins)

  static const double evaporationRate = 0.6;  // Rate at which pheromone trails evaporate over time
  static const double Q = 70.0;  // Pheromone update constant (controls how much pheromone is added after each ant's path)
  static const double bias = 0.6; // Probability bias for selecting the most filled bin (60% chance)

  double _currentRotationAngle = 0.0;
  static const double _segmentDistance = 0.5; // Adjust this value as needed


  @override
  void initState() {
    super.initState();
    _mapController = osm.MapController(
      initPosition: osm.GeoPoint(latitude: 47.4358055, longitude: 8.4737324),
      areaLimit: osm.BoundingBox(
        east: 10.4922941,
        north: 47.8084648,
        south: 45.817995,
        west:  5.9559113,
      ),
    );

    // Initialize AnimationController
    _routeController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20), // Adjust animation duration as needed
    );

    // Use Future.delayed to introduce a small delay before setting _mapLoaded to true
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _mapLoaded = true;
      });
    });

    // Fetch bins after a delay
    Future.delayed(Duration(seconds: 1), () {
      if (_mapLoaded) {
        fetchAllBinInfos();
      }
    });
  }
  @override
  void dispose() {
    _timer.cancel();
    _routeController.dispose();
    super.dispose();
  }




  Future<void> fetchAllBinInfos() async {
    try {
      print('Fetching all bin information...');

      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      print('Current user: $user');
      if (user == null) {
        print('No user signed in.');
        return;
      }

      // Retrieve user document
      var userSnapshot = await firestore.FirebaseFirestore.instance
          .collection('employees')
          .where('uid', isEqualTo: user.uid)
          .get();
      if (userSnapshot.docs.isEmpty) {
        print('User document not found for uid: ${user.uid}');
        return;
      }

      print('User document retrieved successfully.');

      // Extract user's governorate and municipality
      var userData = userSnapshot.docs.first.data();
      if (userData == null) {
        print('User data is null.');
        return;
      }

      String userGovernorate = userData['governorate'];
      String userMunicipality = userData['municipality'];
      _userGovernorate = userData['governorate'] ?? ''; // Assigning governorate to class variable
      _userMunicipality = userData['municipality'] ?? ''; // Assigning municipality to class variable



      print('User governorate: $userGovernorate, User municipality: $userMunicipality');

      // Query bins matching the user's governorate and municipality
      var binSnapshot = await firestore.FirebaseFirestore.instance
          .collection('bins')
          .where('governorate', isEqualTo: userGovernorate)
          .where('municipality', isEqualTo: userMunicipality)
          .get();

      if (binSnapshot.docs.isEmpty) {
        print('No bins found in the same governorate and municipality as the user.');
        return;
      }

      print('Bins found in the same governorate and municipality as the user.');

      // Mapping bin documents to BinInfo objects and assigning them to the class-level variable allBins
      allBins = binSnapshot.docs.map((doc) {
        firestore.GeoPoint location = doc['location'] as firestore.GeoPoint;
        double fillLevel = double.parse(doc['filling_level'].toString());
        String locationName = doc['location_name'].toString();
        return BinInfo(
          fillingLevel: fillLevel,
          latitude: location.latitude,
          longitude: location.longitude,
          locationName: locationName,
        );
      }).toList();

      print('Bins mapped to BinInfo objects successfully: $allBins');
      allBins.sort((a, b) => b.fillingLevel.compareTo(a.fillingLevel));

      print('Bins sorted by filling level (descending): $allBins');
      // Add markers for all bins
      _addMarkers(allBins);
    } catch (error) {
      print('Error fetching bin information: $error');
    }
  }
  Future<String?> getCurrentUserUID() async {
    try {
      // Get the current user from FirebaseAuth
      final User? user = FirebaseAuth.instance.currentUser;

      // Check if user is not null and return the UID
      if (user != null) {
        return user.uid;
      } else {
        // User is not signed in
        print('No user signed in.');
        return null;
      }
    } catch (error) {
      print('Error while getting current user UID: $error');
      return null;
    }
  }
  Future<void> _filterAndSortBins() async {
    // Get user's current location
    osm.GeoPoint userLocation = await _mapController.myLocation();
    print('User location: $userLocation');

    // Print all bins before filtering
    print('Total number of bins: ${allBins.length}');
    print('All bins: $allBins');

    // Filter out bins with a filling level <= 70
    List<BinInfo> filteredBins = allBins.where((bin) => bin.fillingLevel > 70).toList();
    print('Filtered bins (filling level > 70): $filteredBins');

    // Calculate the percentage of bins with filling levels > 70 compared to the total number of bins
    double percentage = (filteredBins.length / allBins.length) * 100;
    print('Percentage of bins with filling levels > 70: $percentage%');

    // Check for 0% or less than 50% for skipped route dialog
    if (percentage <= 50) {
      String message;
      if (percentage == 0) {
        message = "Bins chilling. Route stalling!";
      } else {
        message = "Bins chilling. Route stalling!";
      }
      _showRouteGenerationSkippedDialog(message);
    } else {
      print('Percentage is greater than 50%. Proceeding with route generation.');

      // Call antColonyOptimization to find the best route
      List<int> bestRoute = await antColonyOptimization(filteredBins, nAnts, nIterations, alpha, beta, evaporationRate, Q, weight1, weight2);
      List<BinInfo> bestRouteBins = bestRoute.map((index) => filteredBins[index]).toList();

      // Generate the route passing through the best route bins
      if (bestRouteBins.isNotEmpty) {
        await _generateRoute(userLocation, bestRouteBins);
      } else {
        print('No valid route found.'); // Or handle the empty route case accordingly
        _showRouteGenerationSkippedDialog("No valid route found. There are no bins with filling levels greater than 70%.");
      }
    }
  }
  void _addMarkers(List<BinInfo> binInfos) {
    for (var binInfo in binInfos) {
      _mapController.addMarker(
        osm.GeoPoint(latitude: binInfo.latitude, longitude: binInfo.longitude),
        markerIcon: osm.MarkerIcon(
          icon: Icon(
            Icons.delete_rounded,
            color: Colors.teal[300],
            size: 25,
          ),
        ),
      );
      // Print the filling level of each bin to the console
      print('Bin at (${binInfo.latitude}, ${binInfo.longitude}) has filling level: ${binInfo.fillingLevel}');
    }
  }
  void _showRouteGenerationSkippedDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 4,
          child: Container(
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Route Status Update!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.0),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
                SizedBox(height: 20),
                Image.asset(
                  'assets/images/gif.gif', // Replace with your image path
                  height: 70,
                  width: 70,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.white,
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 20.0,
                    ),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  Future<List<int>> antColonyOptimization(List<BinInfo> bins, int nAnts, int nIterations, double alpha, double beta, double evaporationRate, double Q, double weight1, double weight2) async {
    // Show loading UI (assuming these functions exist)
    setState(() {
      _isLoading = true;
    });
    _showLoadingDialog(context);
    await Future.delayed(Duration(seconds: 3)); // Simulate 3 seconds of loading (remove for actual use)

    // Initialize variables
    int nPoints = bins.length;
    List<List<double>> pheromone = List.generate(nPoints, (i) => List.generate(nPoints, (j) => 1.0)); // Pheromone trails (initialized to 1.0)
    List<int> bestPath = [];  // Stores the best path found so far
    double bestPathLength = double.infinity;  // Tracks the shortest path length

    // Main ACO loop (iterates for nIterations)
    for (int iteration = 0; iteration < nIterations; iteration++) {
      List<List<int>> paths = [];  // Stores paths taken by each ant in this iteration
      List<double> pathLengths = [];  // Stores lengths of each path

      // Loop for each ant (nAnts)
      for (int ant = 0; ant < nAnts; ant++) {
        List<bool> visited = List.filled(nPoints, false);  // Keeps track of visited bins
        int currentPoint = Random().nextInt(nPoints); // Random starting point
        visited[currentPoint] = true;
        List<int> path = [currentPoint];  // Stores the path for this ant
        double pathLength = 0.0;  // Tracks the length of the path

        // Loop until all bins are visited
        while (visited.contains(false)) {
          List<int> unvisited = [];  // List of unvisited bins
          for (int i = 0; i < nPoints; i++) {
            if (!visited[i]) {
              unvisited.add(i);
            }
          }
          List<double> probabilities = List.filled(unvisited.length, 0.0);  // Stores probabilities for each unvisited bin

          // Calculate probabilities for each unvisited bin
          for (int i = 0; i < unvisited.length; i++) {
            int unvisitedPoint = unvisited[i];
            double pheromoneFactor = pow(pheromone[currentPoint][unvisitedPoint], alpha) as double; // Pheromone influence
            double distanceFactor = pow(1 / distance(bins[currentPoint], bins[unvisitedPoint]), beta) as double; // Distance influence
            double fillLevelFactor = bins[unvisitedPoint].fillingLevel / 100; // Filling level factor (normalized)
            probabilities[i] = pheromoneFactor * pow(distanceFactor, weight2) * pow(fillLevelFactor, weight1);
          }

          // Normalize probabilities to sum to 1
          double totalProbability = probabilities.fold(0.0, (sum, element) => sum + element);
          probabilities = probabilities.map((e) => e / totalProbability).toList();

          // Choose the next point based on probabilities
          int nextPoint = _chooseRandomly(unvisited, probabilities);

          // Update path and visited list
          path.add(nextPoint);
          pathLength += distance(bins[currentPoint], bins[nextPoint]);
          visited[nextPoint] = true;
          currentPoint = nextPoint;
        }

        // Add the ant's path and its length to the lists
        paths.add(path);
        pathLengths.add(pathLength);

        // Update the best path if a shorter path is found
        if (pathLength < bestPathLength) {
          bestPath = path;
          bestPathLength = pathLength;
        }
      }

      // Print pheromone matrix for debugging
      print("Pheromone Matrix (iteration $iteration):");
      for (int i = 0; i < nPoints; i++) {
        print(pheromone[i]);
      }

      // Update pheromone trails based on the paths taken by all ants
      for (int i = 0; i < nPoints; i++) {
        for (int j = 0; j < nPoints; j++) {
          pheromone[i][j] *= evaporationRate; // Pheromone evaporation
        }
      }
      for (int i = 0; i < paths.length; i++) {
        for (int j = 0; j < paths[i].length - 1; j++) {
          pheromone[paths[i][j]][paths[i][j + 1]] += Q / pathLengths[i]; // Update pheromone on edges in the path
        }
        // Update pheromone for the last edge to the starting point (cyclic path)
        pheromone[paths[i].last][paths[i].first] += Q / pathLengths[i];
      }
    }

    // Clear loading UI (assuming these functions exist)
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop(); // Dismiss loading dialog (assuming this exists)

    // Print the best path found
    print("Order of bins:");
    for (int binIndex in bestPath) {
      BinInfo bin = bins[binIndex];
      print("Bin ${bin.locationName}: ${bin.fillingLevel}% filled in (${bin.latitude}° N, ${bin.longitude}° E), Cost: ${bin.cost}");
    }
    print("Order of bins: $bestPath");

    return bestPath;
  }
  int _chooseRandomly(List<int> choices, List<double> probabilities) {
    double randomValue = Random().nextDouble();
    double cumulativeProbability = 0.0;

    // Find the index of the most filled bin
    int mostFilledBinIndex = choices[probabilities.indexOf(probabilities.reduce(max))];

    for (int i = 0; i < choices.length; i++) {
      cumulativeProbability += probabilities[i];
      if (choices[i] == mostFilledBinIndex && randomValue < bias) {
        return choices[i]; // Select most filled bin with probability bias
      } else if (randomValue < cumulativeProbability) {
        return choices[i]; // Fallback to random selection with probabilities
      }
    }
    return choices.last; // In case of rounding errors
  }
  double _calculateDistance(double startLat, double startLon, double endLat, double endLon) {
    // Constants
    const double pi = 3.1415926535897932; // Pi constant
    const double radius = 6371.0; // Earth radius in kilometers

    // Convert latitude and longitude from degrees to radians
    double lat1 = startLat * pi / 180.0; // Latitude of the starting point in radians
    double lon1 = startLon * pi / 180.0; // Longitude of the starting point in radians
    double lat2 = endLat * pi / 180.0; // Latitude of the ending point in radians
    double lon2 = endLon * pi / 180.0; // Longitude of the ending point in radians

    // Calculate differences in longitude and latitude
    double dlon = lon2 - lon1; // Difference in longitude
    double dlat = lat2 - lat1; // Difference in latitude

    // Intermediate calculations using the Haversine formula
    double a = pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2); // Intermediate calculation 'a' =the square of half the chord length between the points
    double c = 2 * atan2(sqrt(a), sqrt(1 - a)); // Intermediate calculation 'c'=the angular distance in radians.

    // Calculate distance using the Haversine formula and Earth's radius
    double distance = radius * c; // Distance in kilometers r is the radius of the Earth in kilometers (approximately 6371.0 km).
    print('Distance calculated: $distance km');
    return distance;
  }
  double distance(BinInfo bin1, BinInfo bin2) {
    // Use your existing _calculateDistance function here
    return _calculateDistance(bin1.latitude, bin1.longitude, bin2.latitude, bin2.longitude);
  }
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 4,
          child: Container(
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Searching for the most efficient route...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ), // Custom message
                SizedBox(height: 20.0),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ), // Loading indicator
                SizedBox(height: 12),
                Text(
                  'Thank you for your patience!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                  ),
                ), // Subtitle
              ],
            ),
          ),
        );
      },
    );
  }




  Future<void> _generateRoute(osm.GeoPoint? start, List<BinInfo> bestRouteBins) async {
    if (_routeGenerated) {
      print("Route already generated. Skipping route generation.");
      return;
    }

    if (start == null) {
      // Handle the case where the start location is null
      return;
    }

    print('Best route bins (generate route()):');
    for (var bin in bestRouteBins) {
      print('${bin.locationName}: (${bin.latitude}, ${bin.longitude})');
    }

    List<osm.GeoPoint> routePoints = [start];
    for (var bin in bestRouteBins) {
      routePoints.add(osm.GeoPoint(latitude: bin.latitude, longitude: bin.longitude));
    }
    routePoints.add(start);

    await _drawRoute(routePoints);

    _routeGenerated = true;
  }
  Future<RouteData> _drawRoute(List<osm.GeoPoint> routePoints) async {
    try {
      if (_routeCreated) {
        print("Route already created. Skipping route creation.");
        // You may return existing route data here if needed
        return RouteData(
          allPoints: _allpoints,
          routePoints: _generatedRoutePoints,
          totalDistance: _distance,
          totalDuration: _duration,
          routeId: _routeId,
        );
      }

      final User? user = _auth.currentUser;
      if (user == null) {
        print("Error: User not logged in.");
        return RouteData(
          allPoints: [],
          routePoints: [],
          totalDistance: 0.0,
          totalDuration: 0.0,
          routeId: '',
        );
      }

      if (routePoints.isEmpty) {
        print("Error: Route points list is empty.");
        return RouteData(
          allPoints: [],
          routePoints: [],
          totalDistance: 0.0,
          totalDuration: 0.0,
          routeId: '',
        );
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

      // Draw the route from start to first bin
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

      // Draw the route between bins
      for (int i = 0; i < intermediatePoints.length - 1; i++) {
        print("Drawing route between bins ${i + 1} and ${i + 2}...");

        roads.add(await _mapController.drawRoad(
          intermediatePoints[i],
          intermediatePoints[i + 1],
          roadType: osm.RoadType.car,
          roadOption: osm.RoadOption(
            roadWidth: 20, // Set the width of the polyline
            roadColor: Colors.blue[400]!,
            zoomInto: false, // No need to zoom into the route for intermediate segments
          ),
        ));
      }

      // Draw the route from last bin to destination
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

      // Format distance to display one digit after the decimal point and round
      double roundedDistance = double.parse(totalDistance.toStringAsFixed(1));
      double fuelConsumption = _calculateFuelConsumption(totalDistance);

      // Update route information variables
      setState(() {
        _distance = roundedDistance;
        _duration = durationInMinutes.toDouble();
        _fuelConsumption = fuelConsumption;
        // Access instructions from each RoadInfo object in the roads list
        _instructions = roads.map((road) => road.instructions).join('\n');
      });

      // Optionally, you can print some information about the route
      print("Route information:");
      print("Distance: $_distance");
      print("Duration: $_duration");
      print("Instructions: $_instructions");

      // Extract initial points used to draw the route
      List<osm.GeoPoint> initialPoints = [start];
      initialPoints.addAll(intermediatePoints);
      initialPoints.add(destination);

      // Extract all points along the route
      List<osm.GeoPoint> allPoints = [];
      for (var road in roads) {
        allPoints.addAll(road.route);
      }
      _allpoints = allPoints;
      _generatedRoutePoints = routePoints;

      // Call createRoute method after drawing the route successfully
      String? createdRouteId =
      await createRoute(fuelConsumption, routePoints.length, initialPoints);


      // Set routeCreated to true to prevent further route creation
      _routeCreated = true;

      // Return both lists in a RouteData object
      return RouteData(
        allPoints: allPoints,
        routePoints: routePoints,
        totalDistance: roundedDistance,
        routeId: createdRouteId,
        totalDuration: durationInMinutes.toDouble(),
      );
    } catch (error) {
      print("Error while drawing route: $error");
      return RouteData(
        allPoints: [],
        routePoints: [],
        totalDistance: 0.0,
        totalDuration: 0.0,
        routeId: '',
      );
    }
  }
  Future<String?> createRoute(double fuelConsumption, int collectedBins, List<osm.GeoPoint> initialPoints) async {
    try {
      if (_routeCreated) {
        print("Route already created. Skipping route creation.");
        return null;
      }
      // Get the current user UID
      String? uid = await getCurrentUserUID();

      // Ensure uid is not null before proceeding
      if (uid == null) {
        print("Error: Current user UID is null.");
        return null;
      }

      // Create a route document in Firestore
      final firestore.CollectionReference routesCollection =
      firestore.FirebaseFirestore.instance.collection('routes');
      final firestore.DocumentReference newRouteRef =
      routesCollection.doc();

      // Generate a timestamp representing the current moment
      final currentTime = DateTime.now();

      // Generate a unique ID for the day
      final dayId = DateFormat('yyyyMMdd').format(currentTime);

      await newRouteRef.set({
        'routeId': newRouteRef.id,
        'userUid': uid,
        'duration': _duration,
        'distance': _distance,
        'fuelConsumption': fuelConsumption,
        'governorate': _userGovernorate,
        'municipality': _userMunicipality,
        'date': currentTime, // Add the current timestamp
        'dayId': dayId, // Add the day ID
        'collected_bins': collectedBins, // Add collected bins count
        'initialPoints': initialPoints.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude,
        }).toList(),
      });

      return newRouteRef.id;
    } catch (error) {
      print("Error while creating route: $error");
      return null;
    }
  }
  double _calculateFuelConsumption(double distance) {
    double fuelEfficiency = 3; // km/l
    double consumption = distance / fuelEfficiency;
    return double.parse(consumption.toStringAsFixed(1)); // Round to one decimal place
  }

  Future<List<osm.GeoPoint>> drawTestRoute(osm.MapController _mapController,List<osm.GeoPoint> allPoints) async {
    // Define the route points
    final List<osm.GeoPoint> routePoints = [
      osm.GeoPoint(latitude: 36.1796, longitude: 8.7074), // New starting point
      osm.GeoPoint(latitude: 36.1803, longitude: 8.7072), //
      osm.GeoPoint(latitude: 36.1801, longitude: 8.7082), //
      osm.GeoPoint(latitude: 36.1800, longitude: 8.7084), // Shell
      osm.GeoPoint(latitude: 36.1799, longitude: 8.7088), //
      osm.GeoPoint(latitude: 36.1799, longitude: 8.7115), // MhSadia
    ];

    // Draw the route segments from starting point to intermediate points
    List<osm.RoadInfo> roads = [];
    for (int i = 0; i < routePoints.length - 1; i++) {
      osm.GeoPoint start = routePoints[i];
      osm.GeoPoint end = routePoints[i + 1];
      osm.RoadInfo roadInfo = await _mapController.drawRoad(
        start,
        end,
        roadType: osm.RoadType.car,
        roadOption: osm.RoadOption(
          roadColor: Colors.red,
          roadWidth: 20.0,
          zoomInto: false, // Don't zoom into each segment
        ),
      );
      roads.add(roadInfo);
    }

    // Draw route segment from the last intermediate point to the starting point (closing the loop)
    osm.RoadInfo finalRoadInfo = await _mapController.drawRoad(
      routePoints.last,
      routePoints.first,
      roadType: osm.RoadType.car,
      roadOption: osm.RoadOption(
        roadColor: Colors.red,
        roadWidth: 20.0,
        zoomInto: true, // Zoom into the complete route
      ),
    );
    roads.add(finalRoadInfo);

    // Extract all points from the drawn roads
    List<osm.GeoPoint> allTestPoints = [];
    for (var road in roads) {
      allTestPoints.addAll(road.route);
    }
    await createTestRoute(allTestPoints);
    String? createdTestRouteId = await createTestRoute(allTestPoints);
    // Return the list of all the points of the drawn route
    print('alltestpoints:$allTestPoints');

    // Start simulation with the drawn route points
    startTestRouteSimulation(allTestPoints, allPoints,createdTestRouteId ); // Pass allPoints
    return allTestPoints;
  }
  Future<String?> createTestRoute(List<osm.GeoPoint> allTestPoints) async {
    try {
      // Create a route document in Firestore
      final firestore.CollectionReference routesCollection =
      firestore.FirebaseFirestore.instance.collection('TestRoute');
      final firestore.DocumentReference newRouteRef =
      routesCollection.doc();

      // Generate a timestamp representing the current moment
      final currentTime = DateTime.now();

      // Generate a unique ID for the day
      final dayId = DateFormat('yyyyMMdd').format(currentTime);

      await newRouteRef.set({
        'routeId': newRouteRef.id,
        'date': currentTime,
        'allTestPoints': allTestPoints.map((point) =>
        {
          'latitude': point.latitude,
          'longitude': point.longitude
        }).toList(),
        'dayId': dayId, // Add the day ID
      });


      print("Route information:");
      print("Route ID: ${newRouteRef.id}");
      print("Date: $currentTime");
      print("Day ID: $dayId");
      print("All Test Points: $allTestPoints");

      return newRouteRef.id;
    }catch (error) {
      print("Error while creating route: $error");
      return null;
    }



  }

  void startTestRouteSimulation(List<osm.GeoPoint> allTestpoints,List<osm.GeoPoint> allPoints,String? routeId) async {
    print('Starting route simulation...');
    for (int i = 0; i < allTestpoints.length; i++) {
      osm.GeoPoint currentTestPoint = allTestpoints[i];

      await _mapController.addMarker(
        currentTestPoint,
        markerIcon: osm.MarkerIcon(
          icon: Icon(
            Icons.gps_fixed,
            color: Colors.blueAccent,
            size: 20,
          ),
        ),
      );

      await _mapController.moveTo(currentTestPoint, animate: true);
      await Future.delayed(Duration(milliseconds: 100));
      await _mapController.removeMarker(currentTestPoint);

      // Check if the test point matches the correct point
      if (!allPoints.contains(currentTestPoint)) {
        _showWrongPathDialog(); // Show wrong path dialog

        continue; // Stop the simulation once a wrong point is found
      }
    }
    createNotification('wrong_route', '$routeId');
  }
  void _showWrongPathDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(30.0),
            decoration: BoxDecoration(
              color: Color.fromRGBO(254, 233, 240, 1), // Pink background
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/danger.gif', // Animation
                  width: 70,
                  height: 70,
                ),
                SizedBox(height: 10.0),
                Text(
                  "Wrong Path",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent, // Pink for title
                  ),
                ),
                SizedBox(height: 10.0),
                Text(
                  "You are deviating from the correct route. Please follow the right path.",
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.pinkAccent, // Pink for content
                  ),
                ),
                SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.pinkAccent, // Pink for button text
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showRouteCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(30.0),
            decoration: BoxDecoration(
              color: Color.fromRGBO(98, 227, 208, 200), // Custom background color
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/success.gif', // Animation
                  width: 50,
                  height: 50,
                ),
                SizedBox(height: 25.0),
                Text(
                  "Route Completed Successfully",
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal, // Custom color
                  ),
                ),
                SizedBox(height: 12.0),
                Text(
                  "Congratulations! You have successfully completed the route.",
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.teal, // Custom color
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.0),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.teal, // Custom color
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void startRouteSimulation(List<osm.GeoPoint> allpoints, List<osm.GeoPoint> routePoints, double totalDistance, double totalDuration,String routeId) async {
    // Make sure routePoints is not empty
    if (allpoints.isEmpty) {
      print('Route points are empty. Cannot start simulation.');
      return;
    }

    print('binPoints number: ${routePoints.length}');
    print('binPoints: $routePoints'); // Log all route points
    print('Starting route simulation...');
    print('Total route distance: $totalDistance');
    print('Number of all points: ${allpoints.length}');

    // List to store found bin information
    List<BinInfo> foundBins = [];

    List<osm.GeoPoint> allBinsPoints = convertBinsToGeoPoints(allBins);

    // Convert allpoints and routePoints to formatted format
    List<String> formattedAllPoints = _formatCoordinates(allpoints);
    List<String> formattedRoutePoints = _formatCoordinates(routePoints);

    print('Formatted all points: $formattedAllPoints');
    print('Formatted route points: $formattedRoutePoints');
    Map<String, int> lastVisitedBinIndex = {}; // Track last visited bin for each formatted point

    for (int i = 0; i < formattedAllPoints.length; i++) {
      bool isRoutePoint = formattedRoutePoints.contains(formattedAllPoints[i]);

      // **Log:** Print formatted point for debugging
      print('Current formatted point: $formattedAllPoints[i]');

      // Check if current point is a route point
      if (isRoutePoint) {
        String formattedPoint = formattedAllPoints[i];

        // Check if this formatted point has already been visited (duplicate)
        if (lastVisitedBinIndex.containsKey(formattedPoint) &&
            i > lastVisitedBinIndex[formattedPoint]!) {
          // Skip showing dialog for duplicates
          continue;
        }
        // Only proceed if it's a route point and dialog hasn't been shown
        if (!_dialogShown) {
          _pauseSimulation(); // Pause simulation (log this call if needed)
          print('Simulation paused at route point: $i');

          osm.GeoPoint currentPoint = parseFormattedPoint(formattedPoint);

          // Check if current point matches any bin location
          for (osm.GeoPoint binPoint in allBinsPoints) {
            // **Log:** Print both points for comparison
            print('Checking current point (${currentPoint.latitude}, ${currentPoint.longitude}) against bin point (${binPoint.latitude}, ${binPoint.longitude})');

            if (currentPoint.latitude == binPoint.latitude && currentPoint.longitude == binPoint.longitude) {
              BinInfo? matchingBin = allBins.firstWhere((bin) => bin.latitude == binPoint.latitude && bin.longitude == binPoint.longitude);
              if (matchingBin != null) {
                foundBins.add(matchingBin);

                await _showPauseDialog(matchingBin, routePoints.length - foundBins.length);
                lastVisitedBinIndex[formattedPoint] = i; // Update last visited index
              }

              _resumeSimulation(); // Resume simulation
            } else {
              _dialogShown = false; // Reset dialog shown flag for the next route point
            }

          }
          _resumeSimulation(); // Resume simulation
        } else {
          _dialogShown = false; // Reset dialog shown flag for the next route point
        }
      }

      if (_isSimulationPaused) {
        await _resumeCompleter.future; // Wait until resumed
      }

      osm.GeoPoint currentPoint = allpoints[i];

      // Remove previous marker if it exists
      if (i > 0) {
        osm.GeoPoint prevPoint = allpoints[i - 1];
        double distance = _calculateDistance(prevPoint.latitude, prevPoint.longitude, currentPoint.latitude, currentPoint.longitude);
        print('Distance from previous point: $distance km');
        totalDistance -= distance;
        updateTotalDistance(totalDistance);
        print('New total distance: $totalDistance km');


        if (prevPoint != null) {
          await _mapController.removeMarker(prevPoint);
        }
        await Future.delayed(Duration(milliseconds: 10)); // Short delay to allow removal

      }

      // Update user location and move camera along with it
      await _mapController.moveTo(currentPoint, animate: true);
      await _mapController.addMarker(
        currentPoint,
        markerIcon: osm.MarkerIcon(
          icon: Icon(
            Icons.gps_fixed,
            color: Colors.deepOrange,
            size: 20,
          ),
        ),
      );

      // Delay between updating user location (adjust as needed)
      await Future.delayed(Duration(milliseconds: 10));
    }

    print('Simulation completed.');
    _showRouteCompletionDialog();
    await _mapController.removeLastRoad();
    await createNotification('correct_route', '$routeId');
  }
  List<String> _formatCoordinates(List<osm.GeoPoint> points) {
    return points.map((point) {
      String lat = point.latitude.toStringAsFixed(4);
      String lon = point.longitude.toStringAsFixed(4);
      return '($lat,$lon)';
    }).toList();
  }
  void updateTotalDistance(double newDistance) {
    setState(() {
      _distance = newDistance;
    });
  }
  List<osm.GeoPoint> convertBinsToGeoPoints(List<BinInfo> allBins) {
    List<osm.GeoPoint> allBinspoints = [];

    for (BinInfo binInfo in allBins) {
      double latitude = binInfo.latitude;
      double longitude = binInfo.longitude;
      osm.GeoPoint geoPoint = osm.GeoPoint(latitude: latitude, longitude: longitude);
      allBinspoints.add(geoPoint);
    }

    return allBinspoints;
  }
  osm.GeoPoint parseFormattedPoint(String formattedPoint) {
    // Remove any unnecessary characters (parentheses in this case)
    formattedPoint = formattedPoint.substring(1, formattedPoint.length - 1);

    List<String> parts = formattedPoint.split(',');
    double latitude = double.parse(parts[0]);
    double longitude = double.parse(parts[1]);
    return osm.GeoPoint(latitude: latitude, longitude: longitude);
  }
  void _pauseSimulation() {
    _isSimulationPaused = true;
  }
  void _resumeSimulation() {
    if (_isSimulationPaused) {
      _isSimulationPaused = false;
      if (!_resumeCompleter.isCompleted) {
        _resumeCompleter.complete(); // Signal that simulation should resume
      }
    }
  }
  Future<void> _showPauseDialog(BinInfo matchingBin, int binsLeft) async {
    // List of motivational phrases
    List<String> motivationalPhrases = [
      "You're doing great! Keep up the good work!",
      "Every step counts towards a cleaner environment!",
      "Your dedication makes a difference!",
      "You're making your community proud!",
    ];

    // Randomly select a motivational phrase
    String randomPhrase =
    motivationalPhrases[Random().nextInt(motivationalPhrases.length)];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 4,
          child: Container(
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.teal, // Teal background
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Pause",
                  style: TextStyle(
                    fontSize: 28.0,
                    color: Colors.white, // White for title
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.0),
                Text(
                  randomPhrase,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.white, // White for motivational phrase
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.0),
                Image.asset(
                  'assets/images/watch.gif', // Animated timer GIF
                  width: 70,
                  height: 70,
                ),
                SizedBox(height: 20.0),
                Text(
                  "Bin At : ${matchingBin.locationName}",
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.white, // White for bin info
                  ),
                ),
                SizedBox(height: 5.0),
                Text(
                  "Filling Level: ${matchingBin.fillingLevel}%",
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white, // White for bin info
                  ),
                ),
                SizedBox(height: 5.0),
                Text(
                  "Bins left in the route: $binsLeft",
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white, // White for bin info
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resumeSimulation();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.white), // White for button background
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  icon: Icon(
                    Icons.play_arrow,
                    color: Colors.teal,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Text(
                      "Resume",
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.teal, // Teal for button text
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    // Set _dialogDismissed to true after the dialog is dismissed
    _dialogDismissed = true;
  }
  Future<void> createNotification(String type, String routeId) async {
    try {
      // Get the UID of the current user
      String? userUID = await getCurrentUserUID();

      // Check if userUID is not null
      if (userUID != null) {
        // Create a notification instance
        Notification notification = Notification(
          type: type,
          routeId: routeId,
          userUID: userUID,
        );

        // Create a notification document in Firestore
        final firestore.CollectionReference notificationsCollection =
        firestore.FirebaseFirestore.instance.collection('notifications');

        // Generate a unique ID for the document
        final String notif_id = notificationsCollection.doc().id;

        // Create the document with the new field
        await notificationsCollection.doc(notif_id).set({
          'notif_id': notif_id, // Add notif_id to the data
          'type': notification.type,
          'sent':false,
          'routeId': notification.routeId,
          'userUID': notification.userUID,
          'timestamp': DateTime.now(),
          'adminRead': false, // Default value for admin read status
          'appRead': false, // Default value for app read status
        });

        print("Notification created successfully with ID: $notif_id");
      } else {
        print("Failed to create notification: User UID is null.");
      }
    } catch (error) {
      print("Error while creating notification: $error");
    }
  }




  void _toggleUserLocation() async  {
    setState(() {
      _showUserLocation = !_showUserLocation;
    });

    if (_showUserLocation) {
      await _mapController.enableTracking();
      await _mapController.setZoom(zoomLevel: 19);
      osm.GeoPoint userLocation = await _mapController.myLocation();
      await _mapController.addMarker(
        userLocation,
        markerIcon: osm.MarkerIcon(
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
  void _onButtonPressed() {
    _filterAndSortBins(); // Call method to draw the route
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
          if (_mapLoaded) ...[
            // Only render these widgets if the map is fully loaded
            _buildFloatingButtons(),
            if (_expandableContainerVisible) _buildExpandableContainer(), // Conditionally render the expandable container
          ],
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
            onPressed: () {
              _zoomIn();           },
            mini: true,
            backgroundColor: Colors.white70,
            child: Icon(Icons.add, color: Colors.teal),
          ),
          SizedBox(height: 5),
          FloatingActionButton(
            heroTag: 'fab3',
            onPressed: () {
              _zoomOut();
            },
            mini: true,
            backgroundColor: Colors.white70,
            child: Icon(Icons.remove, color: Colors.teal), // Zoom out button
          ),
          SizedBox(height: 5),
          FloatingActionButton(
            heroTag: 'fab4',
            onPressed: () {
              _filterAndSortBins();
              setState(() {
                _expandableContainerVisible = !_expandableContainerVisible;
              });
            },
            mini: true,
            backgroundColor: Colors.white70,
            child: Icon(Icons.route, color: Colors.teal), // Preview button
          ),
          SizedBox(height: 5),
          FloatingActionButton(
            heroTag: 'fab7',
            onPressed: () async {
              RouteData routeData = await _drawRoute( _generatedRoutePoints);
              if (routeData.allPoints.isNotEmpty) {
                await drawTestRoute(_mapController, routeData.allPoints);
              }
            },
            mini: true,
            backgroundColor: Colors.white70,
            child: Icon(Icons.directions, color: Colors.teal),
          ),
          SizedBox(height: 5),
          FloatingActionButton(
            heroTag: 'fab6',
            onPressed: () {
              // Call the rotateMap function
              rotateMap(_mapController);
            },
            mini: true,
            backgroundColor: Colors.white70,
            child: Icon(
                Icons.rotate_right, color: Colors.teal), // Rotate map button
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
        ),
        _isPinned ? PinnedContentView() : _buildInstructions(), // Check _isPinned flag here
        Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: _buildMapButtons(),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    // Split the instructions string into a list based on comma delimiter
    List<String> instructionList = _instructions.split(',');

    // Initialize a list to hold the widgets for instructions and bins
    List<Widget> allWidgets = [];

    // Iterate through each instruction and process accordingly
    for (int i = 0; i < instructionList.length; i++) {
      String instruction = instructionList[i];

      // Remove square brackets and trim the instruction string
      String cleanInstruction = instruction.replaceAll('[', '').replaceAll(']', '').trim();

      // Determine if this instruction should be replaced with a bin
      if (cleanInstruction.toLowerCase().contains('vous etes arrivé a une etape de votre voyage')) {
        // If a bin is available, replace the instruction with the bin
        if (allBins.isNotEmpty) {
          BinInfo bin = allBins.removeAt(0); // Remove the first bin from the list
          allWidgets.add(
            Padding(
              padding: EdgeInsets.only(left: 30, top: 10, bottom: 5, right: 30),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.teal), // Bin icon
                      SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          'Bin at ${bin.locationName}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Add separator conditionally
                  if (i != instructionList.length - 1)
                    Padding(
                      padding: EdgeInsets.only(left: 35, top: 20, bottom: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(width: 1, color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
      } else {
        // Process regular instructions
        IconData icon;
        if (cleanInstruction.toLowerCase().contains('droite')) {
          icon = Icons.turn_right;
        } else if (cleanInstruction.toLowerCase().contains('gauche')) {
          icon = Icons.turn_left;
        } else if (cleanInstruction.toLowerCase().contains('rond-point')) {
          icon = Icons.roundabout_left_sharp;
        } else if ((cleanInstruction.toLowerCase().contains('sortie')) ||
            (cleanInstruction.toLowerCase().contains('prenez'))) {
          icon = Icons.arrow_upward;
        } else {
          icon = Icons.location_on_outlined; // Default icon
        }

        allWidgets.add(
          Padding(
            padding: EdgeInsets.only(left: 30, top: 10, bottom: 5, right: 30),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.teal), // Use the determined icon
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        cleanInstruction,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                // Add separator conditionally
                if (i != instructionList.length - 1)
                  Padding(
                    padding: EdgeInsets.only(left: 35, top: 20, bottom: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                width: 1, color: Colors.grey.shade200)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }

    // Return the combined list of widgets
    return Container(
      height: 620, // Adjust the height as needed
      child: SingleChildScrollView(
        // Wrap with SingleChildScrollView
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Text(
                "Steps",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
            ),
            ...allWidgets,
          ],
        ),
      ),
    );
  }

  Widget PinnedContentView() {
    // Sort the bins by fill level in descending order
    allBins.sort((a, b) => b.fillingLevel.compareTo(a.fillingLevel));

    // Render the bins' fill levels when pinned button is pressed
    return SizedBox(
      height: 600, // Set the desired height here
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, top: 10, right: 16, bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bin Overview",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "Location: $_userMunicipality, $_userGovernorate",
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allBins.length,
              itemBuilder: (context, index) {
                var bin = allBins[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Display the location name of the bin
                      SizedBox(
                        width: 87,
                        child: Text(
                          bin.locationName,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 10),
                      _buildColoredPercentage(barWidth: 220, fillLevel: bin.fillingLevel),
                      SizedBox(width: 15),
                      Text(
                        "${bin.fillingLevel.toStringAsFixed(0)}%",
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColoredPercentage({required double barWidth, required double fillLevel}) {

    // Determine the image index based on fill level
    int imageIndex;

    if (fillLevel == 0) {
      imageIndex = 1; // 0%
    } else if (fillLevel <= 5) {
      imageIndex = 2; // 2% to 5%
    } else if (fillLevel <= 10) {
      imageIndex = 3; // 6% to 10%
    } else if (fillLevel <= 15) {
      imageIndex = 4; // 11% to 15%
    } else if (fillLevel <= 20) {
      imageIndex = 5; // 15% to 20%
    } else if (fillLevel <= 25) {
      imageIndex = 7; // 21% to 25%
    } else if (fillLevel <= 30) {
      imageIndex = 9; // 26% to 30%
    } else if (fillLevel <= 35) {
      imageIndex = 10; // 31% to 35%
    } else if (fillLevel <= 40) {
      imageIndex = 10; // 36% to 40%
    } else if (fillLevel <= 43) {
      imageIndex = 10; // 41% to 43%
    } else if (fillLevel <= 46) {
      imageIndex = 11; // 44% to 46%
    } else if (fillLevel <= 48) {
      imageIndex = 12; // 47% to 48%
    } else if (fillLevel <= 49) {
      imageIndex = 13; // 49%
    } else if (fillLevel <= 50) {
      imageIndex = 14; // 50%
    } else if (fillLevel <= 55) {
      imageIndex = 15; // 51% to 55%
    } else if (fillLevel <= 60) {
      imageIndex = 16; // 56% to 60%
    } else if (fillLevel <= 66) {
      imageIndex = 17; // 61% to 66%
    } else if (fillLevel <= 70) {
      imageIndex = 18; // 67% to 70%
    } else if (fillLevel <= 80) {
      imageIndex = 19; // 71% to 80%
    } else if (fillLevel <= 82) {
      imageIndex = 20; // 81% to 82%
    } else if (fillLevel <= 85) {
      imageIndex = 21; // 83% to 85%
    } else if (fillLevel <= 90) {
      imageIndex = 22; // 86% to 90%
    } else if (fillLevel <= 99) {
      imageIndex = 23; // 91% to 99%
    } else {
      imageIndex = 24; // 100%
    }

    // Construct the image path
    String imagePath = 'assets/images/bars/$imageIndex.png';

    // Return the container with the colored image
    return Container(
      width: barWidth, // Fixed width for the container
      height: 15, // Adjust the height of the bar as needed
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
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
          child: _isExpanded ? Text(_instructions, style: TextStyle(fontSize: 17, fontWeight: FontWeight.normal, color: Colors.black)) : SizedBox.shrink(),
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
          _buildStartButton(),
          SizedBox(width: 10),
          _buildStepsButton(),
          SizedBox(width: 10),
          _buildPreviewButton(),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: () async {
        // Show confirmation dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.teal, // Set background color
              title: Text(
                "Start Route ",
                style: TextStyle(color: Colors.white), // Set text color
              ),
              content: Text(
                "Bins calling! Ready to roll?",
                style: TextStyle(color: Colors.white), // Set text color
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close the dialog
                    // Draw the route and get the route data
                    RouteData routeData = await _drawRoute(_generatedRoutePoints);
                    // Extract all points ,route points ,  distance and duration from the route data
                    List<osm.GeoPoint> allPoints = routeData.allPoints;
                    List<osm.GeoPoint> routePoints = routeData.routePoints;
                    double totalDistance = routeData.totalDistance;
                    double totalDuration = routeData.totalDuration;
                    String? routeId = routeData.routeId;
                    startRouteSimulation(allPoints, routePoints,totalDistance,totalDuration,routeId!); // Call startRouteSimulation
                  },
                  child: Text(
                    "Yes",
                    style: TextStyle(color: Colors.white), // Set text color
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(
                    "No",
                    style: TextStyle(color: Colors.white), // Set text color
                  ),
                ),
              ],
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 30),
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.not_started_sharp, color: Colors.white),
          SizedBox(width: 5),
          Text("Start", style: TextStyle(color: Colors.white)),
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

  Widget _buildPreviewButton() {
    return ElevatedButton(
      onPressed: _onButtonPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.teal, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.keyboard_double_arrow_right, color: Colors.teal),
          SizedBox(width: 5),
          Text("Preview", style: TextStyle(color: Colors.teal)),
        ],
      ),
    );
  }


}
