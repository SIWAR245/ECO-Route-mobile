class Notification {
  final String notif_id;  // New field to store document ID
  final String type;
  final String routeId;
  final String userUID;
  final bool adminRead;
  final bool appRead;
  final bool sent;

  Notification({
    required this.type,
    required this.notif_id,
    required this.sent,
    required this.routeId,
    required this.userUID,
    this.adminRead = false,
    this.appRead = false,
  });
}