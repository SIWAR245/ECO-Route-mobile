import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../Common_widgets/tealButton.dart';
import '../../Common_widgets/toast.dart';


class ChangePWD extends StatefulWidget {
  const ChangePWD({super.key, required this.id});

  @override
  _ChangePWDState createState() => _ChangePWDState();
  final String id;
}

class _ChangePWDState extends State<ChangePWD> {

  final _formSignInKey = GlobalKey<FormState>();
  late final TextEditingController? controller;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  String firstName = '';
  String lastName = '';
  String email = '';
  String imageUrl = '';


  // data loading from firestore
  Future<void> getUserInfo() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore
          .collection('employees')
          .where('uid', isEqualTo: uid)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic> data = querySnapshot.docs.first.data() as Map<
            String,
            dynamic>;
        firstName = data['first_name'];
        lastName = data['last_name'];
        email= data['email'];
        imageUrl = data['imageUrl'];

      }
    }
  }

//Updating password
  void changePassword(String newPassword, String confirmPassword) async {
    if (newPassword != confirmPassword) {
      ToastUtils.showErrorToast(
        message: 'Confirm password',
      );
      return;
    }

    if (newPassword.length < 6) {
      ToastUtils.showADVToast(
        message: 'Password must contain more than 6 characters',
      );
      return;
    }
    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.updatePassword(newPassword);
      ToastUtils.showToast(
        message: 'Password changed successfully',
      );
    } catch (e) {
      ToastUtils.showErrorToast(
        message: '$e',
      );
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
                centerTitle: true,
                leading: InkWell(onTap: (
                    ) {
                  Navigator.pop(context);
                  },
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.teal,
                  ),
                ),
            ),
            body: SingleChildScrollView(
              child: Center(
                child: Form(
                  key: _formSignInKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 20.0),
                      SizedBox(
                        height: 158,
                        width: 128,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('$firstName $lastName',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                        ),
                      ),
                        Text('$email',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 20,
                          ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Container(
                        width: 360,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(98, 227, 208,220),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: true,
                          onChanged: (value) {
                            FirebaseFirestore.instance
                                .collection('employees')
                                .doc(widget.id)
                                .update({'password': value});
                          },
                          decoration: InputDecoration(
                            labelText: 'New password',
                            labelStyle: const TextStyle(
                                color: Colors.teal
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color.fromRGBO(98, 227, 208,220),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color.fromRGBO(178, 223, 219, 0.1),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color.fromRGBO(178, 223, 219, 0.1),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40.0),
                      Container(
                        width: 360,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(98, 227, 208,220),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          controller: _passwordConfirmController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            labelStyle: const TextStyle(
                                color: Colors.teal
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color.fromRGBO(178, 223, 219, 0.1),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color.fromRGBO(178, 223, 219, 0.1),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color.fromRGBO(178, 223, 219, 0.1),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      CustomButton(
                        text: 'Change Password',
                        onPressed: () {
                            changePassword(_passwordController.text,_passwordConfirmController.text);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}