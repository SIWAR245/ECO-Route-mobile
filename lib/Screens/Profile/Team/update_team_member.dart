import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../../../Common_widgets/tealButton.dart';
import '../../../Common_widgets/toast.dart';


class UpdateMemberForm extends StatefulWidget {

  const UpdateMemberForm({Key? key, required this.memberId}) : super(key: key);
  final String memberId;

  @override
  _UpdateMemberFormState createState() => _UpdateMemberFormState();

}

class _UpdateMemberFormState extends State<UpdateMemberForm> {

  late final TextEditingController? controller;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  late String _profileImageUrl = '';
  final _formSignInKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

//date select method
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      _startDateController.text = pickedDate.toString().split(' ')[0];
    }
  }


  //image uploading method
  Future<void> _selectImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery);

    if (pickedImage != null) {
      // Upload the image to Firebase Storage
      final firebase_storage.Reference ref = firebase_storage.FirebaseStorage
          .instance
          .ref()
          .child('team_members_pp')
          .child('profilePicture_${DateTime
          .now()
          .millisecondsSinceEpoch}.png');

      final firebase_storage.UploadTask uploadTask = ref.putFile(
          File(pickedImage.path));
      final firebase_storage.TaskSnapshot taskSnapshot = await uploadTask
          .whenComplete(() => null);

      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      setState(() {
        _profileImageUrl = downloadUrl;
      });
    }
  }


  //data loading from firestore
  void _loadMemberData() async {
    try {
      DocumentSnapshot memberSnapshot =
      await FirebaseFirestore.instance.collection('team_members').doc(
          widget.memberId).get();
      if (memberSnapshot.exists) {
        setState(() {
          _firstNameController.text = memberSnapshot['firstName'];
          _lastNameController.text = memberSnapshot['lastName'];
          _startDateController.text = memberSnapshot['startDate'];
          _emailController.text = memberSnapshot['Email'];
          _profileImageUrl = memberSnapshot['profileImageUrl'];
        });
      }
    } catch (e) {
      ToastUtils.showErrorToast(
        message: '$e',
      );
    }
  }


//Updating team member method
  void _updateMember() {
    try {
      FirebaseFirestore.instance.collection('team_members')
          .doc(widget.memberId)
          .update({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'startDate': _startDateController.text,
        'Email': _emailController.text,
        'profileImageUrl': _profileImageUrl,
      });
      ToastUtils.showToast(
        message: 'Team member updated successfully',
      );
      Navigator.of(context).pop();
    } catch (e) {
      ToastUtils.showToast(
        message: 'Error updating team member: $e',
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: InkWell(onTap: () {
            Navigator.pop(context);
          },
            child: const Icon(Icons.arrow_back_ios_rounded,
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
                const SizedBox(height: 40.0),
                SizedBox(
                  height: 158,
                  width: 128,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: _profileImageUrl.isNotEmpty
                                ? DecorationImage(
                              image: NetworkImage(_profileImageUrl),
                              fit: BoxFit.cover,
                            )
                                : const DecorationImage(
                              image: AssetImage('assets/images/avatar.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            _selectImage(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.camera_alt_sharp,
                              color: Colors.teal,
                              size: 28.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60.0),
                Container(
                  width: 360,
                  height: 60,
                  decoration: BoxDecoration(
                    color:  const Color.fromRGBO(98, 227, 208,220),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    controller: _firstNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter First Name';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'First Name',
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

                const SizedBox(height: 20.0),
                Container(
                  width: 360,
                  height: 60,
                  decoration: BoxDecoration(
                    color:  const Color.fromRGBO(98, 227, 208,220),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    controller: _lastNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Last Name';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Last Name',
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

                const SizedBox(height: 20.0),

                Container(
                  width: 360,
                  height: 60,
                  decoration: BoxDecoration(
                    color:  const Color.fromRGBO(98, 227, 208,220),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    onTap: () async {
                      await _selectDate(context);
                    },
                    readOnly: true,
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: 'Start date of activity',
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

                const SizedBox(height: 20.0),

                Container(
                  width: 360,
                  height: 60,
                  decoration: BoxDecoration(
                    color:  const Color.fromRGBO(98, 227, 208,220),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
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
                  text: 'Update',
                  onPressed: () {
                      _updateMember();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}