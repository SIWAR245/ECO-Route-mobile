import 'package:badges/badges.dart';
import 'package:eco_route_se/Screens/Home/home_screen.dart';
import 'package:eco_route_se/Screens/Profile/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Screens/Map/MapPage.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    initializeFirebase();
    updateNotificationCount();
  }

  // Initialize Firebase app
  void initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Get unread notification count from Firebase
  Future<void> updateNotificationCount() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userUID', isEqualTo: uid)
          .where('appRead', isEqualTo: false)
          .get();
      setState(() {
        _notificationCount = snapshot.docs.length;
      });
    }
  }

// Update notification status to read
  Future<void> markNotificationsAsRead() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .where('userUID', isEqualTo: uid)
          .where('appRead', isEqualTo: false)
          .get()
          .then((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(doc.id)
              .update({'appRead': true});
        });
      });
      setState(() {
        _notificationCount = 0;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      child: _buildNavBar(context),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25.0, 2.0, 25.0, 2.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(40.0),
          topLeft: Radius.circular(40.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(context, 'assets/images/home.png', 'Home', 0),
          _buildNavBarItem(context, 'assets/images/map.png', 'Map', 1),
          _buildCenterButton(),
          _buildNavBarItem(context, 'assets/images/notifs.png', 'Notif', 3),
          _buildNavBarItem(context, 'assets/images/profile2.png', 'Profile', 4),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(BuildContext context, String imagePath, String label, int index) {
    final isSelected = widget.currentIndex == index;
    Widget item = ColorFiltered(
      colorFilter: isSelected ? const ColorFilter.mode(Colors.teal, BlendMode.srcIn) : ColorFilter.mode(Colors.grey, BlendMode.srcIn),
      child: Image.asset(
        imagePath,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
      ),
    );
    if (index == 3) { // Check if this is the 'Notif' icon
      item = badges.Badge(
        position: BadgePosition.topEnd(top: -6, end: -6),
        badgeContent: Text(
          '$_notificationCount',
          style: TextStyle(color: Colors.white),
        ),
        badgeStyle: BadgeStyle(
          badgeColor: Color.fromRGBO(244, 100, 140,5),
        ),
        child: item,
      );
    }
    return GestureDetector(
      onTap: () {
        widget.onItemTapped(index);
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(),
              ),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MapPage(),
              ),
            );
            break;
          case 3:
          // Navigate to NotifsScreen and mark notifications as read
            Navigator.pushNamed(context, '/notif').then((_) => markNotificationsAsRead());
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Profile(),
              ),
            );
            break;
          default:
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          item,
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.teal : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: () {
        // Handle center button tap
      },
      child: Container(
        width: 70,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.teal,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.search,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}
