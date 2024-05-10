class BinInfo {
  final double fillingLevel;
  final double latitude;
  final double longitude;
  final String locationName;
  double cost; // Add this property to store the calculated cost
  bool visited; // Flag for ACO process

  BinInfo({
    required this.fillingLevel,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.cost = 0, // Initialize cost to 0
    this.visited = false, // Initialize visited flag to false
  });
}