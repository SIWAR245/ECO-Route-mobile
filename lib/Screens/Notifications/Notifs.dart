import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Common_widgets/bottom_nav_bar.dart';


class NotifsScreen extends StatefulWidget {
  const NotifsScreen({Key? key}) : super(key: key);

  @override
  _NotifsScreenState createState() => _NotifsScreenState();

}

class _NotifsScreenState extends State<NotifsScreen> {
  int _currentIndex = 3;
  DateTime? selectedDate;
  List<Map<String, dynamic>> notifications = [];



  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }


  Future<void> getNotifications() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore
          .collection('notifications')
          .where('userUID', isEqualTo: uid)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        notifications = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        notifications.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp)); // Sort by date
        setState(() {});
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (timestamp.year == today.year &&
        timestamp.month == today.month &&
        timestamp.day == today.day) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (timestamp.year == yesterday.year &&
        timestamp.month == yesterday.month &&
        timestamp.day == yesterday.day) {
      return 'Yesterday';
    } else if (timestamp.year == now.year && timestamp.month == now.month) {
      return DateFormat('MM-dd.dart').format(timestamp);
    } else {
      return DateFormat('MM-dd.dart').format(timestamp);
    }
  }

  @override
  void initState() {
    super.initState();
    getNotifications();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Column(
              children: [
                const SizedBox(
                    height: 10
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(10),
                      child: const Text(
                        'Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Filter',
                          style: TextStyle(
                            color: Colors.teal,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          icon: const Icon(Icons.filter_list),
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                  Expanded(
                    child: ListView.builder(
                        itemCount: selectedDate == null ? notifications.length : notifications.where((notif) {
                          final DateTime notificationDate = (notif['timestamp'] as Timestamp).toDate();
                          return notificationDate.year == selectedDate!.year &&
                              notificationDate.month == selectedDate!.month &&
                              notificationDate.day == selectedDate!.day;
                        }).length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> notif;
                          if (selectedDate == null) {
                            notif = notifications[index];
                          } else {
                            notif = notifications.where((notif) {
                              final DateTime notificationDate = (notif['timestamp'] as Timestamp).toDate();
                              return notificationDate.year == selectedDate!.year &&
                                  notificationDate.month == selectedDate!.month &&
                                  notificationDate.day == selectedDate!.day;
                            }).toList()[index];
                          }

                          List<Color> colors = [
                            Color.fromRGBO(98, 227, 208,220),
                            Color.fromRGBO(244, 100, 140,220),
                            Color.fromRGBO(123, 152, 245,220),
                          ];
                          List<Color> colors2 = [
                            Color.fromRGBO(0, 128, 128,5),
                            Color.fromRGBO(244, 100, 140,5),
                            Color.fromRGBO(123, 152, 245,5),
                          ];

                          IconData iconData;
                          Color containerColor;
                          Color iconsColor;
                          if (notif['type'] == 'correct_route') {
                            iconData = Icons.check_circle;
                            containerColor = colors[0];
                            iconsColor = colors2[0];
                          } else if (notif['type'] == 'wrong_route') {
                            iconData = Icons.error;
                            containerColor = colors[1];
                            iconsColor = colors2[1];
                          } else {
                            iconData = Icons.error;
                            containerColor = colors[2 % colors.length];
                            iconsColor = colors2[2 % colors.length];
                          }


                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: containerColor,
                            ),
                            margin: const EdgeInsets.all(6),
                            child: ListTile(
                              tileColor: Colors.white,
                              leading: Container(
                                  padding: EdgeInsets.all(5),
                                  child:  Icon(iconData,color: iconsColor,)
                              ),
                              title: Text(notif['type'] == 'correct_route'
                                    ? 'Route Completed Successfully'
                                    : 'Route Divergence Detected',
                                style: TextStyle(
                                  color: iconsColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle:Text(notif['type'] == 'correct_route'
                                  ? 'You ve successfully completed the assigned route for waste collection'
                                  : 'You have diverged from the planned route',
                                style: const TextStyle(
                                  color: Color.fromRGBO(112, 128, 145,5),
                                  fontSize: 13
                                ),
                              ),
                              trailing: Text(
                                notif['timestamp'] != null
                                    ? _formatTimestamp(notif['timestamp'].toDate())
                                    : '',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color.fromRGBO(112, 128, 145,5),
                                ),
                              ),

                            ),
                          );
                        },
                    ),
                  ),
              ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onItemTapped: _onItemTapped,
      ),
      backgroundColor: Colors.white,
    );

  }
}
