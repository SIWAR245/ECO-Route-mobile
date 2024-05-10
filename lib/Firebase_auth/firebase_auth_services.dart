import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../Common_widgets/toast.dart';
import '../Screens/Login/login_screen.dart';

class FirebaseAuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // Future<User?> signUp(
  //     String firstName,
  //     String lastName,
  //     String phoneNumber,
  //     int expYears,
  //     String email,
  //     String password,
  //     ) async {
  //   try {
  //     UserCredential credential = await _auth.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //
  //     String uid = credential.user?.uid ?? '';
  //
  //     await FirebaseFirestore.instance.collection('users').doc(uid).set({
  //       'firstName': firstName,
  //       'lastName': lastName,
  //       'expYears': expYears,
  //       'phoneNumber': phoneNumber,
  //       'email': email,
  //     });
  //
  //     return credential.user;
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'email-already-in-use') {
  //       ToastUtils.showErrorToast(
  //         message: 'The email address is already in use',
  //       );
  //       } else {
  //       ToastUtils.showErrorToast(
  //         message: 'An error occurred : ${e.code}'
  //       );
  //       }
  //   }
  //   return null;
  // }
  // Future<void> sendEmailVerification() async {
  //   try {
  //     User? user = _auth.currentUser;
  //     if (user != null && !user.emailVerified) {
  //       await user.sendEmailVerification();
  //       ToastUtils.showToast(message: 'Verification email sent');
  //     } else {
  //       ToastUtils.showErrorToast(message: 'Email already verified or no user signed in');
  //     }
  //   } catch (e) {
  //     ToastUtils.showErrorToast(message: 'Error sending verification email: $e');
  //   }
  // }


  Future<Map<String, dynamic>?> getUserInfo(String email) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
        .collection('employees')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }

    return null;
  }



//signIg employee method
  Future<User?> signIn(String email, String password) async {
    Map<String, dynamic>? userInfo = await getUserInfo(email);

    if (userInfo != null) {
      try {
        UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return credential.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          ToastUtils.showErrorToast(
            message: 'Incorrect email',
          );
        } else if (e.code == 'wrong-password') {
          ToastUtils.showErrorToast(
            message: 'Incorrect password',
          );
        } else {
          ToastUtils.showErrorToast(
            message: 'Incorrect email and password',
          );
        }
      }
    } else {
      ToastUtils.showErrorToast(
        message: 'User not found',
      );
    }

    return null;
  }


  //reset password method
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ToastUtils.showToast(message: 'Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ToastUtils.showErrorToast(message: 'No user found with this email');
      } else {
        ToastUtils.showErrorToast(message: e.code);
      }
    } catch (e) {
      ToastUtils.showErrorToast(message: 'An unexpected error occurred.');
    }
  }



}
