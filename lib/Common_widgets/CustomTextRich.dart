import 'package:flutter/material.dart';
class CustomTextRich extends StatelessWidget {
  final double duration;
  final double distance;

  const CustomTextRich({
    Key? key,
    required this.duration,
    required this.distance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$duration min',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.normal, color: Colors.black),
          ),
          TextSpan(
            text: ' (${distance.toStringAsFixed(1)} km)', // Adding distance with unit
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.normal, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
