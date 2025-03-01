import 'package:flutter/material.dart';
import 'package:pitch_perfect/constants.dart';

// ignore: must_be_immutable
class Requirement extends StatelessWidget {
  Requirement(
      {super.key, required this.requirementTitle});

  final requirementTextStyle = const TextStyle(
    fontSize: 30,
    color: largeTextColor,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        color: Colors.grey, // Choose the color of the shadow
        blurRadius: 1.0, // Adjust the blur radius for the shadow effect
        offset: Offset(
            2.0, 2.0), // Set the horizontal and vertical offset for the shadow
      )
    ],
  );

  String requirementTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        requirementTitle,
        style: requirementTextStyle,
      ),
    );
  }
}
