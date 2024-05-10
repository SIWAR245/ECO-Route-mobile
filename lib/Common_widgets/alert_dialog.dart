import 'package:flutter/material.dart';

class CustomAlertDialog {
  static Future<void> showAlertDialog(BuildContext context,VoidCallback xmethod) async {
    return showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return IntrinsicHeight(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const SizedBox(
                   height: 30,
                 ),
                 const Text('Are you sure you want to log out?',
                   style: TextStyle(
                     fontSize: 15,
                   ),
                 ),
                 const SizedBox(
                   height: 20,
                 ),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     ElevatedButton(
                       onPressed: () {
                         Navigator.pop(context);
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.tealAccent, // Set the background color here
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(10),
                         ),
                       ),
                       child: const Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(
                             '   Cancel  ',
                             style: TextStyle(
                               color: Colors.teal,
                               fontSize: 16, // Adjust the font size as needed
                             ),
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(
                       width: 10,
                     ),
                     ElevatedButton(
                       onPressed: () {
                         xmethod();
                         Navigator.pop(context);
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.teal,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(10),
                         ),
                       ),
                       child: const Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(
                             ' Yes,logout',
                             style: TextStyle(
                               color: Colors.white,
                               fontSize: 16, // Adjust the font size as needed
                             ),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(
                   height: 10,
                 ),
               ],
             ),
        );
      },
    );
  }

}
