import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_route_se/Screens/Notifications/mapHistoryRoutes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eco_route_se/Common_widgets/bottom_nav_bar.dart';
import '../../Common_widgets/calendar.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> routes = [];
  DateTime? selectedDate;
  String firstName = '';
  String lastName = '';
  String imageUrl = '';
  User? user = FirebaseAuth.instance.currentUser;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> getRoutes() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore
          .collection('routes')
          .where('userUid', isEqualTo: uid)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        routes = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        routes.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp)); // Sort by date
        setState(() {});
      }
    }
  }

  Future<void> getUserInfo() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore
          .collection('employees')
          .where('uid', isEqualTo: uid)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic> data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          firstName = data['first_name'];
          lastName = data['last_name'];
          imageUrl = data['imageUrl'];
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getRoutes();
    getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration:  BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello $firstName,',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Safe Travels !',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(
              height: 20
          ),
          CalendarWidget(),
          const SizedBox(
              height: 20
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                child: const Text(
                  'Routes History',
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
          Expanded(
            child: ListView.builder(
              itemCount: selectedDate == null
                  ? routes.length
                  : routes.where((route) {
                final DateTime routeDate = (route['date'] as Timestamp).toDate();
                return routeDate.year == selectedDate!.year &&
                    routeDate.month == selectedDate!.month &&
                    routeDate.day == selectedDate!.day;
              }).length,
              itemBuilder: (context, index) {
                Map<String, dynamic> route;
                if (selectedDate == null) {
                  route = routes[index];
                } else {
                  route = routes.where((route) {
                    final DateTime routeDate = (route['date'] as Timestamp).toDate();
                    return routeDate.year == selectedDate!.year &&
                        routeDate.month == selectedDate!.month &&
                        routeDate.day == selectedDate!.day;
                  }).toList()[index];
                }

                List<Color> colors = [
                  const Color.fromRGBO(98, 227, 208, 220),
                  const Color.fromRGBO(244, 100, 140, 220),
                  const Color.fromRGBO(151, 106, 235, 220),
                  const Color.fromRGBO(123, 152, 245, 220),
                ];
                List<Color> colors2 = [
                  const Color.fromRGBO(0, 128, 128, 5),
                  const Color.fromRGBO(244, 100, 140, 5),
                  const Color.fromRGBO(151, 106, 235, 5),
                  const Color.fromRGBO(123, 152, 245, 5),
                ];

                Color containerColor = colors[index % colors.length];
                Color container2Color = colors2[index % colors.length];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapHistory(routeId: route['routeId']),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: containerColor,
                    ),
                    margin: const EdgeInsets.all(6),
                    child: ListTile(
                      tileColor: Colors.white,
                      leading: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Text(
                          DateFormat.MMMd().format((route['date'] as Timestamp).toDate()),
                          style: TextStyle(
                            color: container2Color,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        'Distance: ${route['distance']}km',
                        style: TextStyle(
                          color: container2Color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text('${route['duration']}s'),
                      trailing: Icon(
                        Icons.keyboard_arrow_right_rounded,
                        color: container2Color,
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