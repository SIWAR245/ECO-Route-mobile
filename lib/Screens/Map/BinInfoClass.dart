class BinInfo {
  final String binId;
  final double fillingLevel;
  final double latitude;
  final double longitude;
  final String locationName;
  final String tiltStatus;
  double cost;
  bool visited;

  BinInfo({
    required this.binId,
    required this.fillingLevel,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.tiltStatus,
    this.cost = 0,
    this.visited = false,
  });
}