import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_route_se/Screens/Login/login_screen.dart';
import 'package:eco_route_se/Screens/Profile/change_password.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../Common_widgets/alert_dialog.dart';
import '../../Common_widgets/bottom_nav_bar.dart';
import 'Team/team.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  int _currentIndex = 4;
  String firstName = '';
  String lastName = '';
  String imageUrl = '';
  User? user = FirebaseAuth.instance.currentUser;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  //getting the current document id
  Future<String?> getDocumentId() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('uid', isEqualTo: uid)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
    }
    return null;
  }

  //logout method
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  //getting the current user info's
  Future<void> getUserInfo() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore
          .collection('employees')
          .where('uid', isEqualTo: uid)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic> data =
        querySnapshot.docs.first.data() as Map<String, dynamic>;
        firstName = data['first_name'];
        lastName = data['last_name'];
        imageUrl = data['imageUrl'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
            ),
            body: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        height: 158,
                        width: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${user?.email}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Row(
                        children: <Widget>[
                          const SizedBox(
                            width: 20,
                          ),
                          Flexible(
                            flex: 1,
                            fit: FlexFit.tight,
                            child: Container(
                              height: 80,
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 5.0,
                                    spreadRadius: 2.0,
                                  )
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Points',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '8515699',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Flexible(
                            flex: 1,
                            fit: FlexFit.tight,
                            child: Container(
                              height: 80,
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 5.0,
                                    spreadRadius: 2.0,
                                  )
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Points',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '8515699',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Flexible(
                            flex: 1,
                            fit: FlexFit.tight,
                            child: Container(
                              height: 80,
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 5.0,
                                    spreadRadius: 2.0,
                                  )
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Points',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '8515699',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 5.0,
                                        spreadRadius: 2.0,
                                      )
                                    ],
                                  ),
                                  margin: const EdgeInsets.fromLTRB(18, 5, 18, 5),
                                  child: ListTile(
                                    onTap: () async {
                                      String? documentId = await getDocumentId();
                                      if (documentId != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChangePWD(id: documentId),
                                          ),
                                        );
                                      }
                                    },
                                    leading: Container(
                                      margin: const EdgeInsetsDirectional.fromSTEB(20.0, 20.0, 0, 20.0),
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/images/password.svg',
                                      ),
                                    ),
                                    title: const Text('Change password'),
                                    trailing: const Icon(
                                      Icons.keyboard_arrow_right_rounded,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 5.0,
                                        spreadRadius: 2.0,
                                      )
                                    ],
                                  ),
                                  margin: const EdgeInsets.fromLTRB(18, 5, 18, 5),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Team(),
                                        ),
                                      );
                                    },
                                    leading: Container(
                                      margin: const EdgeInsetsDirectional.fromSTEB(20.0, 20.0, 0, 20.0),
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/images/team.svg',
                                        height: 30,
                                        width: 30,
                                      ),
                                    ),
                                    title: const Text('Team'),
                                    trailing: const Icon(
                                      Icons.keyboard_arrow_right_rounded,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 5.0,
                                        spreadRadius: 2.0,
                                      )
                                    ],
                                  ),
                                  margin: const EdgeInsets.fromLTRB(18, 5, 18, 5),
                                  child: ListTile(
                                    onTap: () {
                                      // Handle settings tap
                                    },
                                    leading: Container(
                                      margin: const EdgeInsetsDirectional.fromSTEB(20.0, 20.0, 0, 20.0),
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/images/settings.svg',
                                      ),
                                    ),
                                    title: const Text('Settings'),
                                    trailing: const Icon(
                                      Icons.keyboard_arrow_right_rounded,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 5.0,
                                        spreadRadius: 2.0,
                                      )
                                    ],
                                  ),
                                  margin: const EdgeInsets.fromLTRB(18, 5, 18, 5),
                                  child: ListTile(
                                    onTap: () {
                                      CustomAlertDialog.showAlertDialog(context, () {
                                        _logout(context);
                                      });
                                    },
                                    leading: Container(
                                      margin: const EdgeInsetsDirectional.fromSTEB(20.0, 20.0, 0, 20.0),
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/images/logout.svg',
                                        color: const Color.fromRGBO(244, 100, 140, 5),
                                      ),
                                    ),
                                    title: const Text('Logout', style: TextStyle(color: const Color.fromRGBO(244, 100, 140, 5))),

                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: _currentIndex,
              onItemTapped: _onItemTapped,
            ),
          );
        }
      },
    );
  }
}
